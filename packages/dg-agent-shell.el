;;; dg-agent-shell.el --- Agent shell configuration -*- lexical-binding: t; -*-

(use-package shell-maker
  :ensure t
  :demand t)

(defun dg/auth-source-get-password (host)
  "Get password for HOST from auth-source (e.g., ~/.authinfo.gpg).
Returns empty string if not found."
  (require 'auth-source)
  (if-let* ((auth-info (auth-source-search :host host :max 1))
            (secret (plist-get (car auth-info) :secret)))
      (if (functionp secret)
          (funcall secret)
        secret)
    ""))

(defvar-local dg/agent-shell--prompt-count 0
  "Number of prompts sent in this agent-shell session.")

(defvar-local dg/agent-shell--session-summary nil
  "Summary of what this session is working on.")

(defvar-local dg/agent-shell--summary-pending nil
  "Non-nil if we're waiting to parse a summary response.")

(defvar-local dg/agent-shell--last-prompt-text nil
  "Text of the most recently submitted user prompt in this session.")

(defvar-local dg/agent-shell--last-prompt-time nil
  "Time of the most recently submitted user prompt in this session.")

(defvar dg/agent-shell-summary-interval 10
  "Number of prompts between automatic summary generation.")

(defconst dg/agent-shell--summary-prompt
  "Reply with ONLY: the Linear ticket id if any has been referenced (e.g. INFRA-1234), then a 3-6 word summary of what we're working on. If no ticket, just the summary. No other text."
  "Prompt used to request session summaries.")

(defvar dg/agent-shell--pending-permissions nil
  "Alist of (buffer . tool-call-title) for sessions awaiting permission.")

(defvar dg/agent-shell--selected-buffer nil
  "Cached agent-shell buffer selection for the current command.")

(use-package agent-shell
  :demand t
  :ensure t
  :bind (("C-M-s-/" . dg/agent-shell-transient-menu)
         ("<end>" . dg/agent-shell-transient-menu))
  :custom
  (agent-shell-highlight-blocks t)
  (agent-shell-anthropic-default-model-id "claude-opus-4-7")
  (agent-shell-anthropic-default-session-mode-id "bypassPermissions")

  :config
  (setq agent-shell-prefer-viewport-interaction nil)

  (setq agent-shell-session-strategy 'new)

  (setq agent-shell-mcp-servers
        `(
          ((name . "linear")
           (type . "http")
           (url . "https://mcp.linear.app/mcp")
           (headers . (((name . "Authorization")
                        (value . ,(concat "Bearer " (dg/auth-source-get-password "linear.app")))))))
          ;; ((name . "notion")
          ;;  (type . "http")
          ;;  (headers . [])
          ;;  (url . "https://mcp.notion.com/mcp"))

          ))

  (setq agent-shell-header-style nil)
  (setq agent-shell-show-welcome-message nil))

(defun dg/agent-shell--track-prompt-submission (orig-fun &rest args)
  "Advice around `shell-maker-submit' to track prompts and capture last prompt."
  (when (derived-mode-p 'agent-shell-mode)
    (let ((input (string-trim (buffer-substring-no-properties
                               (shell-maker--prompt-end-position) (point-max)))))
      (unless (string-empty-p input)
        (if (string= input dg/agent-shell--summary-prompt)
            (setq dg/agent-shell--summary-pending t)
          (setq dg/agent-shell--last-prompt-text input)
          (setq dg/agent-shell--last-prompt-time (current-time))
          (cl-incf dg/agent-shell--prompt-count)
          (dg/agent-shell--maybe-queue-summary)))))
  (apply orig-fun args))

(defun dg/agent-shell--poll-for-summary (buf attempts)
  "Poll BUF for summary response, up to ATTEMPTS times."
  (when (and (buffer-live-p buf) (> attempts 0))
    (with-current-buffer buf
      (if (and dg/agent-shell--summary-pending (not (shell-maker-busy)))
          (progn
            (dg/agent-shell--check-for-summary-capture)
            (when dg/agent-shell--summary-pending
              (run-with-timer 2 nil #'dg/agent-shell--poll-for-summary buf (1- attempts))))
        (when dg/agent-shell--summary-pending
          (run-with-timer 2 nil #'dg/agent-shell--poll-for-summary buf (1- attempts)))))))

(defun dg/agent-shell--maybe-queue-summary ()
  "Queue a summary request if conditions are met."
  (when (and (derived-mode-p 'agent-shell-mode)
             (not dg/agent-shell--summary-pending)
             (or (= dg/agent-shell--prompt-count 1)
                 (= 0 (mod dg/agent-shell--prompt-count dg/agent-shell-summary-interval))))
    (let ((buf (current-buffer)))
      (run-with-timer 1 nil
                      (lambda ()
                        (when (buffer-live-p buf)
                          (with-current-buffer buf
                            (agent-shell-queue-request dg/agent-shell--summary-prompt)
                            (run-with-timer 5 nil #'dg/agent-shell--poll-for-summary buf 10))))))))

(defun dg/agent-shell--status-line-p (line)
  "Return non-nil if LINE is an agent-shell status message to skip."
  (or (string-empty-p line)
      (string-prefix-p "▶" line)
      (string-equal line "Done")
      (string-prefix-p "Requesting " line)
      (string-prefix-p "Creating " line)
      (string-prefix-p "Subscribing" line)
      (string-prefix-p "Initializing" line)
      (string-equal line "Ready")
      (string-prefix-p "<shell-maker" line)))

(defun dg/agent-shell--check-for-summary-capture ()
  "Check if we should capture a summary from the buffer."
  (when dg/agent-shell--summary-pending
    (save-excursion
      (goto-char (point-max))
      (let* ((shell-prompt (or (map-nested-elt agent-shell--state '(:agent-config :shell-prompt))
                               "Claude> "))
             (prompt-line-re (concat "^" (regexp-quote shell-prompt)))
             (search-pattern (concat prompt-line-re (regexp-quote dg/agent-shell--summary-prompt))))
        (when (re-search-backward search-pattern nil t)
          (when (re-search-forward "<shell-maker-end-of-prompt>\n" nil t)
            (let* ((start (point))
                   (end (if (re-search-forward prompt-line-re nil t)
                            (match-beginning 0)
                          (point-max)))
                   (found-summary nil))
              (goto-char end)
              (forward-line -1)
              (while (and (>= (point) start) (not found-summary))
                (let ((line (string-trim (buffer-substring-no-properties
                                          (line-beginning-position)
                                          (line-end-position)))))
                  (unless (dg/agent-shell--status-line-p line)
                    (setq found-summary line)))
                (forward-line -1))
              (when found-summary
                (setq dg/agent-shell--summary-pending nil)
                (setq dg/agent-shell--session-summary
                      (truncate-string-to-width found-summary 60 nil nil "..."))
                (when-let ((sid (map-nested-elt agent-shell--state '(:session :id))))
                  (dg/agent-shell--archive-summary
                   sid dg/agent-shell--session-summary default-directory))
                (message "Summary for %s: %s" (buffer-name) dg/agent-shell--session-summary)))))))))

(defun dg/agent-shell--after-response-hook (orig-fun &rest args)
  "Advice to capture summary after any response completes."
  (prog1 (apply orig-fun args)
    (when (derived-mode-p 'agent-shell-mode)
      (dg/agent-shell--check-for-summary-capture))))

(advice-add 'agent-shell--process-pending-request :around #'dg/agent-shell--after-response-hook)
(advice-add 'shell-maker-submit :around #'dg/agent-shell--track-prompt-submission)

(defun dg/agent-shell--track-queue-request (orig-fun request &rest args)
  "Advice around `agent-shell-queue-request' to record submitted prompts."
  (when (and (derived-mode-p 'agent-shell-mode)
             (stringp request)
             (let ((trimmed (string-trim request)))
               (and (not (string-empty-p trimmed))
                    (not (string= trimmed dg/agent-shell--summary-prompt)))))
    (setq-local dg/agent-shell--last-prompt-text (string-trim request))
    (setq-local dg/agent-shell--last-prompt-time (current-time)))
  (apply orig-fun request args))

(advice-add 'agent-shell-queue-request :around #'dg/agent-shell--track-queue-request)

(defun dg/agent-shell--safe-clean-up (orig-fun &rest args)
  "Advice around `agent-shell--clean-up' to prevent errors from blocking buffer kill.
The upstream clean-up can fail with \"Cannot modify map in-place\" or
\"Text is read-only\", which prevents killing agent-shell buffers."
  (let ((inhibit-read-only t))
    (condition-case err
        (apply orig-fun args)
      (error (message "agent-shell clean-up error (ignored): %s" err)))))

(advice-add 'agent-shell--clean-up :around #'dg/agent-shell--safe-clean-up)

(defun dg/agent-shell--on-permission-request (event)
  "Track permission request from EVENT in `dg/agent-shell--pending-permissions'."
  (let* ((data (map-elt event :data))
         (tool-call (map-elt data :tool-call))
         (title (or (map-elt tool-call :title) "Unknown action"))
         (buf (map-elt event :shell-buffer)))
    (when (buffer-live-p buf)
      (push (cons buf title) dg/agent-shell--pending-permissions))))

(defun dg/agent-shell--on-permission-response (event)
  "Remove resolved permission from `dg/agent-shell--pending-permissions'."
  (let ((buf (map-elt event :shell-buffer)))
    (setq dg/agent-shell--pending-permissions
          (assq-delete-all buf dg/agent-shell--pending-permissions))))

(defun dg/agent-shell--setup-permission-tracking ()
  "Subscribe to permission events for the current agent-shell buffer."
  (let ((buf (current-buffer)))
    (agent-shell-subscribe-to
     :shell-buffer buf
     :event 'permission-request
     :on-event #'dg/agent-shell--on-permission-request)
    (agent-shell-subscribe-to
     :shell-buffer buf
     :event 'permission-response
     :on-event #'dg/agent-shell--on-permission-response)
    (agent-shell-subscribe-to
     :shell-buffer buf
     :event 'clean-up
     :on-event (lambda (_event)
                 (setq dg/agent-shell--pending-permissions
                       (assq-delete-all buf dg/agent-shell--pending-permissions))))))

(add-hook 'agent-shell-mode-hook #'dg/agent-shell--setup-permission-tracking)

;; corfu's auto-popup is noisy while composing prompts to the agent — too
;; many false-positive completions on prose. Disable auto-popup here; corfu
;; still works manually via M-TAB. We also yank the post-command-hook in
;; case global-corfu-mode's corfu-mode activated before this hook ran (its
;; auto-trigger is installed at corfu-mode startup, not read live).
(add-hook 'agent-shell-mode-hook
          (lambda ()
            (setq-local corfu-auto nil)
            (remove-hook 'post-command-hook #'corfu--auto-post-command t)))

(defun dg/agent-shell--clear-selected-buffer ()
  "Clear the cached agent-shell buffer selection."
  (setq dg/agent-shell--selected-buffer nil))

(defun dg/agent-shell--get-all-buffers ()
  "Get all agent-shell buffers."
  (seq-filter (lambda (buf)
                (with-current-buffer buf
                  (derived-mode-p 'agent-shell-mode)))
              (agent-shell-buffers)))

(defun dg/agent-shell--get-buffer ()
  "Get the agent-shell buffer for the current project.
When multiple buffers match, prompt with summaries to disambiguate.
The selection is cached for the duration of the current command."
  (add-hook 'post-command-hook #'dg/agent-shell--clear-selected-buffer nil t)
  (if dg/agent-shell--selected-buffer
      dg/agent-shell--selected-buffer
    (let ((project-buffers (agent-shell-project-buffers))
          (current-is-agent (derived-mode-p 'agent-shell-mode)))
      (setq dg/agent-shell--selected-buffer
            (cond
             (current-is-agent
              (current-buffer))
             (project-buffers
              (car project-buffers))
             (t
              (car (dg/agent-shell--get-all-buffers))))))))

(defun dg/agent-shell-generate-all-summaries ()
  "Generate summaries for all agent-shell buffers.
First tries to extract from existing buffer content, then queues new requests if needed."
  (interactive)
  (let ((all-buffers (dg/agent-shell--get-all-buffers))
        (extracted 0)
        (queued 0)
        (skipped 0))
    (if (null all-buffers)
        (user-error "No agent-shell buffers available")
      (dolist (buf all-buffers)
        (with-current-buffer buf
          ;; Clear any bad/stale summaries from buggy extraction
          (when (and dg/agent-shell--session-summary
                     (or (string-prefix-p "<shell-maker" dg/agent-shell--session-summary)
                         (string-prefix-p "▶" dg/agent-shell--session-summary)))
            (setq dg/agent-shell--session-summary nil))

          (cond
           ;; Already has valid summary
           (dg/agent-shell--session-summary
            (cl-incf skipped))

           ;; Try to extract from existing buffer content first
           (t
            (setq dg/agent-shell--summary-pending t)
            (dg/agent-shell--check-for-summary-capture)
            (cond
             ;; Extraction succeeded
             (dg/agent-shell--session-summary
              (cl-incf extracted))

             ;; Buffer is busy, can't queue new request
             ((shell-maker-busy)
              (setq dg/agent-shell--summary-pending nil)
              (cl-incf skipped))

             ;; Queue a new summary request
             (t
              (setq dg/agent-shell--summary-pending nil)
              (condition-case nil
                  (progn
                    (agent-shell-queue-request dg/agent-shell--summary-prompt)
                    (setq dg/agent-shell--summary-pending t)
                    (run-with-timer 5 nil #'dg/agent-shell--poll-for-summary buf 10)
                    (cl-incf queued))
                (error (cl-incf skipped)))))))))
      (message "Summaries: %d extracted, %d queued, %d skipped"
               extracted queued skipped))))

(defun dg/agent-shell--validate-process ()
  "Validate that an agent-shell process exists, or offer to start one."
  (unless (dg/agent-shell--get-buffer)
    (when (y-or-n-p "No agent-shell session active. Start a new Claude Code session?")
      (agent-shell-anthropic-start-claude-code))
    (unless (dg/agent-shell--get-buffer)
      (user-error "No agent-shell session available"))))

(defun dg/agent-shell--send-message (message)
  "Send MESSAGE to the agent-shell buffer via the request queue.
This allows messages to be sent at any time and queued for processing."
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (agent-shell-queue-request message))))

(defvar dg/agent-shell--prompt-callback nil
  "Callback to invoke with the prompt text when submitted.")

(defvar dg/agent-shell--prompt-window-config nil
  "Saved window configuration to restore after prompt submission.")

(defvar dg/agent-shell--origin-frame nil
  "Frame that was selected when the transient menu was invoked.")

(defvar dg/agent-shell--prompt-buffer nil
  "Name of the currently-active compose buffer, or nil when none.
Computed per target so the buffer name reveals which session is
about to receive the prompt.")

(defun dg/agent-shell--prompt-buffer-name (shell-buffer)
  "Build a compose-buffer name announcing SHELL-BUFFER as the target."
  (let ((target (buffer-name shell-buffer))
        (summary (buffer-local-value 'dg/agent-shell--session-summary shell-buffer)))
    (if summary
        (format " *compose: %s [%s]*" target summary)
      (format " *compose: %s*" target))))

(defvar dg/agent-shell-prompt-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'dg/agent-shell-prompt-submit)
    (define-key map (kbd "C-c C-k") #'dg/agent-shell-prompt-cancel)
    map))

(define-derived-mode dg/agent-shell-prompt-mode text-mode "AgentPrompt"
  "Mode for composing agent-shell prompts in a popup window.")

(defun dg/agent-shell--prompt-cleanup ()
  "Restore window configuration and kill the prompt buffer."
  (when dg/agent-shell--prompt-window-config
    (set-window-configuration dg/agent-shell--prompt-window-config)
    (setq dg/agent-shell--prompt-window-config nil))
  (when-let* ((name dg/agent-shell--prompt-buffer)
              (buf (get-buffer name)))
    (kill-buffer buf))
  (setq dg/agent-shell--prompt-buffer nil))

(defun dg/agent-shell-prompt-submit ()
  "Submit the prompt buffer content and restore window layout."
  (interactive)
  (let ((text (string-trim (buffer-substring-no-properties (point-min) (point-max))))
        (cb dg/agent-shell--prompt-callback))
    (dg/agent-shell--prompt-cleanup)
    (when (and cb (not (string-empty-p text)))
      (funcall cb text))))

(defun dg/agent-shell-prompt-cancel ()
  "Cancel the prompt and restore window layout."
  (interactive)
  (dg/agent-shell--prompt-cleanup))

(defun dg/agent-shell--insert-context (context)
  "Insert CONTEXT into the prompt buffer before the prompt separator.
Finds the first blank-line separator and inserts before it,
keeping the user's typed prompt text after the separator."
  (goto-char (point-min))
  (if (re-search-forward "\n\n" nil t)
      (progn
        (goto-char (match-beginning 0))
        (insert "\n" context))
    (goto-char (point-max))
    (insert context "\n\n"))
  (goto-char (point-max)))

(defun dg/agent-shell--show-prompt (shell-buffer callback &optional initial-content)
  "Pop a window for composing a prompt to send to SHELL-BUFFER.
CALLBACK receives the prompt text on C-c C-c.
INITIAL-CONTENT is optional text to pre-fill.
When the prompt buffer is already visible, appends INITIAL-CONTENT
instead of replacing, preserving the original target session.
Window layout is restored on submit or cancel."
  (let* ((frame (or dg/agent-shell--origin-frame (selected-frame)))
         (existing-buf (and dg/agent-shell--prompt-buffer
                            (get-buffer dg/agent-shell--prompt-buffer)))
         (already-open (and existing-buf (get-buffer-window existing-buf t))))
    (cond
     ((and already-open initial-content)
      (with-selected-frame frame
        (pop-to-buffer existing-buf)
        (dg/agent-shell--insert-context initial-content)))
     (already-open
      (with-selected-frame frame
        (pop-to-buffer existing-buf)
        (goto-char (point-max))))
     (t
      (setq dg/agent-shell--prompt-callback callback)
      (let* ((buf-name (dg/agent-shell--prompt-buffer-name shell-buffer))
             (_ (setq dg/agent-shell--prompt-buffer buf-name))
             (buf (get-buffer-create buf-name))
             (name (buffer-name shell-buffer))
             (summary (buffer-local-value 'dg/agent-shell--session-summary shell-buffer))
             (header (if summary
                         (format " %s  [%s]  |  C-c C-c: send  C-c C-k: cancel" name summary)
                       (format " %s  |  C-c C-c: send  C-c C-k: cancel" name))))
        (with-current-buffer buf
          (dg/agent-shell-prompt-mode)
          (erase-buffer)
          (when initial-content
            (insert initial-content)
            (insert "\n\n"))
          (setq-local header-line-format
                      (propertize header 'face 'font-lock-comment-face)))
        (with-selected-frame frame
          (setq dg/agent-shell--prompt-window-config (current-window-configuration))
          (pop-to-buffer buf)
          (goto-char (point-max))))))))

(defun dg/agent-shell-ask ()
  "Send a bare prompt to agent-shell via a popup window."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (dg/agent-shell--show-prompt
     shell-buffer
     (lambda (text)
       (with-current-buffer shell-buffer
         (agent-shell-queue-request text))))))

(defun dg/agent-shell--make-buffer-wrapper (func)
  "Create a wrapper around FUNC that executes in agent-shell buffer without switching focus."
  (lambda ()
    (interactive)
    (dg/agent-shell--validate-process)
    (let ((shell-buffer (dg/agent-shell--get-buffer)))
      (with-current-buffer shell-buffer
        (call-interactively func)))))

(defalias 'dg/agent-shell-next-item
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-next-item)
  "Go to next item in agent-shell buffer without switching focus.")

(defalias 'dg/agent-shell-previous-item
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-previous-item)
  "Go to previous item in agent-shell buffer without switching focus.")

(defalias 'dg/agent-shell-next-permission-button
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-next-permission-button)
  "Go to next permission button without switching focus.")

(defalias 'dg/agent-shell-previous-permission-button
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-previous-permission-button)
  "Go to previous permission button without switching focus.")

(defalias 'dg/agent-shell-jump-to-latest-permission
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-jump-to-latest-permission-button-row)
  "Jump to latest permission button without switching focus.")

(defalias 'dg/agent-shell-interrupt
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-interrupt)
  "Interrupt agent-shell without switching focus.")

(defalias 'dg/agent-shell-reload
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-reload)
  "Reload the current session, resuming with its session ID.")

(defun dg/agent-shell--resume-session (entry)
  "Open a new agent-shell buffer resuming the session described by ENTRY.
ENTRY is a plist as returned by `dg/agent-shell--buffer-session-data'.
Returns the new buffer, or nil if it could not be located."
  (let* ((session-id (plist-get entry :session-id))
         (cwd (plist-get entry :cwd))
         (identifier (plist-get entry :identifier))
         (summary (plist-get entry :summary))
         (config-fn (alist-get identifier dg/agent-shell--identifier-to-config-fn)))
    (unless session-id
      (user-error "No session id"))
    (unless (and config-fn (fboundp config-fn))
      (user-error "No config builder registered for %S" identifier))
    (unless (and cwd (file-directory-p cwd))
      (user-error "cwd no longer exists: %s" cwd))
    (let ((before (dg/agent-shell--get-all-buffers)))
      (let* ((default-directory cwd)
             (agent-shell-cwd-function (lambda () cwd)))
        (agent-shell-start :config (funcall config-fn) :session-id session-id))
      (let ((new-buffer (car (seq-difference (dg/agent-shell--get-all-buffers) before))))
        (when (and new-buffer summary)
          (with-current-buffer new-buffer
            (setq-local dg/agent-shell--session-summary summary)))
        new-buffer))))

(defun dg/agent-shell-fork ()
  "Open a new agent-shell buffer that resumes the source session.
Source defaults to the current agent-shell buffer when visiting one;
otherwise prompts.  This is our replacement for `agent-shell-fork',
which requires ACP fork support that Claude Code does not advertise."
  (interactive)
  (let* ((source (or (and (derived-mode-p 'agent-shell-mode) (current-buffer))
                     (dg/agent-shell--prompt-for-buffer "Fork from agent-shell buffer: ")))
         (data (or (dg/agent-shell--buffer-session-data source)
                   (user-error "Source buffer has no active session")))
         (new-buffer (dg/agent-shell--resume-session data)))
    (if new-buffer
        (progn
          (pop-to-buffer new-buffer)
          (message "Forked %s -> %s" (buffer-name source) (buffer-name new-buffer)))
      (message "Could not locate forked agent-shell buffer"))))

(defun dg/agent-shell-set-mode-bypass ()
  "Set the current session's mode to bypassPermissions."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer))
        (mode-id "bypassPermissions"))
    (with-current-buffer shell-buffer
      (unless (map-nested-elt (agent-shell--state) '(:session :id))
        (user-error "No active session"))
      (agent-shell--send-request
       :state (agent-shell--state)
       :client (map-elt (agent-shell--state) :client)
       :request (acp-make-session-set-mode-request
                 :session-id (map-nested-elt (agent-shell--state) '(:session :id))
                 :mode-id mode-id)
       :buffer (current-buffer)
       :on-success (lambda (_acp-response)
                     (let ((updated-session (map-elt (agent-shell--state) :session)))
                       (map-put! updated-session :mode-id mode-id)
                       (map-put! (agent-shell--state) :session updated-session))
                     (agent-shell--update-header-and-mode-line)
                     (message "Session mode: bypassPermissions"))
       :on-failure (lambda (acp-error _raw-message)
                     (message "Failed to change session mode: %s" acp-error))))))

(defun dg/agent-shell-start-new-session-pick-repo ()
  "Pick a project root, then start a new Claude Code session there."
  (interactive)
  (let* ((dir (cond
               ((and (boundp 'projectile-known-projects)
                     projectile-known-projects)
                (completing-read "Project: " projectile-known-projects nil t))
               (t (read-directory-name "Project: "))))
         (default-directory (file-name-as-directory (expand-file-name dir)))
         (agent-shell-cwd-function (lambda () default-directory)))
    (dg/agent-shell-start-new-session)))

(defun dg/agent-shell-start-new-session ()
  "Start a new Claude Code session."
  (interactive)
  (agent-shell-start :config (agent-shell-anthropic-make-claude-code-config)))

(defun dg/agent-shell--buffer-display-name (buffer)
  "Get display name for BUFFER including summary if available."
  (let* ((name (buffer-name buffer))
         (summary (buffer-local-value 'dg/agent-shell--session-summary buffer)))
    (if summary
        (format "%s [%s]" name summary)
      name)))

(defun dg/agent-shell--prompt-for-buffer (&optional prompt)
  "Prompt user to select an agent-shell buffer.
PROMPT is the prompt string (defaults to \"Select agent-shell buffer: \").
Returns the selected buffer, or signals error if none available."
  (let ((all-buffers (dg/agent-shell--get-all-buffers)))
    (cond
     ((null all-buffers)
      (user-error "No agent-shell buffers available"))
     ((= 1 (length all-buffers))
      (car all-buffers))
     (t
      (let* ((display-names (mapcar (lambda (buf)
                                      (cons (dg/agent-shell--buffer-display-name buf) buf))
                                    all-buffers))
             (choice (completing-read (or prompt "Select agent-shell buffer: ")
                                      (mapcar #'car display-names) nil t)))
        (cdr (assoc choice display-names)))))))

(defun dg/agent-shell-switch-to-buffer ()
  "Prompt to select and switch to an agent-shell buffer."
  (interactive)
  (switch-to-buffer (dg/agent-shell--prompt-for-buffer "Switch to agent-shell buffer: ")))

(defun dg/agent-shell-accept-permission ()
  "Jump to latest permission and accept it (y)."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (agent-shell-jump-to-latest-permission-button-row)
      (call-interactively (key-binding "y")))))

(defun dg/agent-shell-reject-permission ()
  "Jump to latest permission and reject it (n)."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (agent-shell-jump-to-latest-permission-button-row)
      (call-interactively (key-binding "n")))))

(defun dg/agent-shell-always-accept-permission ()
  "Jump to latest permission and always accept it (!)."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (agent-shell-jump-to-latest-permission-button-row)
      (call-interactively (key-binding "!")))))

(defun dg/agent-shell-view-diff ()
  "Jump to latest permission and view diff (v)."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (agent-shell-jump-to-latest-permission-button-row)
      (call-interactively (key-binding "v")))))

(defun dg/agent-shell--build-context ()
  "Build context string from the current buffer state.
For file buffers: absolute path with line number(s).
For non-file buffers: region text or current line."
  (let* ((file-path (buffer-file-name))
         (has-region (use-region-p))
         (start-line (if has-region
                         (line-number-at-pos (region-beginning))
                       (line-number-at-pos)))
         (end-line (when has-region
                     (line-number-at-pos (region-end)))))
    (cond
     (file-path
      (if (and has-region (not (= start-line end-line)))
          (format "%s:%d-%d" file-path start-line end-line)
        (format "%s:%d" file-path start-line)))
     (has-region
      (buffer-substring-no-properties (region-beginning) (region-end)))
     (t
      (buffer-substring-no-properties
       (line-beginning-position) (line-end-position))))))

(defun dg/agent-shell-execute-request ()
  "Send context to agent-shell with an optional prompt via popup window.
For file buffers, sends the absolute path with line number(s).
For non-file buffers, sends region or current line text."
  (interactive)
  (dg/agent-shell--validate-process)
  (let* ((shell-buffer (dg/agent-shell--get-buffer))
         (context (dg/agent-shell--build-context)))
    (dg/agent-shell--show-prompt
     shell-buffer
     (lambda (text)
       (with-current-buffer shell-buffer
         (agent-shell-queue-request text)))
     context)))

(defun dg/agent-shell-execute-request-pick-buffer ()
  "Send context to a specific agent-shell buffer chosen via completing-read."
  (interactive)
  (let ((target (dg/agent-shell--prompt-for-buffer "Send to agent-shell buffer: ")))
    (setq dg/agent-shell--selected-buffer target)
    (unwind-protect
        (dg/agent-shell-execute-request)
      (setq dg/agent-shell--selected-buffer nil))))

(defun dg/agent-shell-send-flycheck-error ()
  "Copy current flycheck error(s) and send to agent-shell with file context.
If region is active, copy all errors in the region and send all line numbers.
Otherwise, copy the error at point and send its line number."
  (interactive)
  (require 'flycheck)
  (dg/agent-shell--validate-process)
  (let* ((file-path (buffer-file-name))
         (has-region (use-region-p))
         (errors (if has-region
                     (flycheck-overlay-errors-in (region-beginning) (region-end))
                   (flycheck-overlay-errors-at (point))))
         (error-messages (delq nil (mapcar #'flycheck-error-message errors))))

    (unless error-messages
      (user-error "No flycheck errors found"))

    (let* ((error-text (string-join error-messages "\n"))
           (context-text
            (if file-path
                (if has-region
                    (let* ((line-numbers (delete-dups
                                          (mapcar (lambda (err)
                                                    (line-number-at-pos (flycheck-error-pos err)))
                                                  errors))))
                      (if (= (length line-numbers) 1)
                          (format "%s:%d" file-path (car line-numbers))
                        (format "%s:%s" file-path
                                (mapconcat #'number-to-string
                                           (sort line-numbers #'<)
                                           ","))))
                  (format "%s:%d" file-path (line-number-at-pos)))
              (buffer-substring-no-properties
               (if has-region (region-beginning) (line-beginning-position))
               (if has-region (region-end) (line-end-position)))))
           (message-text (format "%s\n\n%s" error-text context-text)))

      (dg/agent-shell--send-message message-text))))

(require 'transient)

(defun dg/agent-shell--pending-permissions-description ()
  "Return a string describing pending permission requests, or nil if none."
  (when dg/agent-shell--pending-permissions
    (let* ((grouped (seq-group-by #'car dg/agent-shell--pending-permissions))
           (parts (mapcar
                   (lambda (group)
                     (let* ((buf (car group))
                            (titles (mapcar #'cdr (cdr group)))
                            (summary (and (buffer-live-p buf)
                                          (buffer-local-value 'dg/agent-shell--session-summary buf)))
                            (label (or summary (buffer-name buf))))
                       (format "%s: %s" label (string-join titles ", "))))
                   grouped)))
      (format "Waiting: %s" (string-join parts " | ")))))

(transient-define-prefix dg/agent-shell-transient-menu--internal ()
  "Agent Shell AI Pair Programming Interface."
  [:description
   (lambda ()
     (let ((pending (dg/agent-shell--pending-permissions-description)))
       (if pending
           (format "Agent Shell\n%s" (propertize pending 'face 'warning))
         "Agent Shell")))
   ["Core"
    ("N" "Start NEW Session" dg/agent-shell-start-new-session)
    ("M" "Start NEW Session (pick repo)" dg/agent-shell-start-new-session-pick-repo)
    ("b" "Switch to Buffer" dg/agent-shell-switch-to-buffer)
    ("r" "Reload current session" dg/agent-shell-reload)
    ("F" "Fork (resume in new buffer)" dg/agent-shell-fork)
    ("m" "Set mode: bypass" dg/agent-shell-set-mode-bypass)]
   ["Send to Agent"
    ("s" "Ask (bare prompt)" dg/agent-shell-ask)
    ("x" "Execute with context" dg/agent-shell-execute-request)
    ("X" "Execute (pick buffer)" dg/agent-shell-execute-request-pick-buffer)
    ("f" "Send flycheck error" dg/agent-shell-send-flycheck-error)]
   ["Permissions"
    ("y" "Accept (Yes)" dg/agent-shell-accept-permission)
    ("n" "Reject (No)" dg/agent-shell-reject-permission)
    ("!" "Always Accept" dg/agent-shell-always-accept-permission)
    ("v" "View Diff" dg/agent-shell-view-diff)]
   ["Summary"
    ("T" "Generate All Summaries" dg/agent-shell-generate-all-summaries)]
   ["Persistence"
    ("d" "Dashboard" dg/agent-shell-dashboard)
    ("P" "Save active sessions" dg/agent-shell-save-active-sessions)
    ("R" "Restore active sessions" dg/agent-shell-restore-active-sessions)]
   ])

(defun dg/agent-shell-transient-menu ()
  "Save current buffer and invoke agent-shell transient menu."
  (interactive)
  (setq dg/agent-shell--origin-frame (selected-frame))
  (when (buffer-file-name)
    (save-buffer))
  (dg/agent-shell-transient-menu--internal))

(with-eval-after-load 'key-chord
  (key-chord-define-global "z/" 'dg/agent-shell-transient-menu))

(defcustom dg/agent-shell-active-file
  (expand-file-name "agent-shell-active.el" user-emacs-directory)
  "File where active agent-shell session metadata is persisted."
  :type 'file
  :group 'dg-agent-shell)

(defcustom dg/agent-shell-summary-archive-file
  (expand-file-name "agent-shell-summaries.el" user-emacs-directory)
  "Append-only archive of every captured session summary.
Survives session close so summaries remain searchable indefinitely."
  :type 'file
  :group 'dg-agent-shell)

(defvar dg/agent-shell--identifier-to-config-fn
  '((claude-code . agent-shell-anthropic-make-claude-code-config))
  "Map from saved agent `:identifier' to the function that builds its config.")

(defun dg/agent-shell--buffer-session-data (buf)
  "Return persistable data for BUF, or nil if it has no session ID."
  (with-current-buffer buf
    (when-let* ((session-id (map-nested-elt agent-shell--state '(:session :id)))
                (config (map-elt agent-shell--state :agent-config))
                (identifier (map-elt config :identifier)))
      (list :buffer-name (buffer-name)
            :session-id session-id
            :cwd default-directory
            :identifier identifier
            :summary dg/agent-shell--session-summary))))

(defun dg/agent-shell--collect-active-sessions (&optional exclude-buffer)
  "Collect persistable data for all live agent-shell buffers with session IDs.
EXCLUDE-BUFFER is omitted from the result if non-nil."
  (delq nil
        (mapcar (lambda (buf)
                  (unless (eq buf exclude-buffer)
                    (dg/agent-shell--buffer-session-data buf)))
                (dg/agent-shell--get-all-buffers))))

(defun dg/agent-shell-save-active-sessions (&optional exclude-buffer)
  "Write active agent-shell session metadata to `dg/agent-shell-active-file'.
EXCLUDE-BUFFER, when non-nil, is omitted (e.g. a buffer being killed)."
  (interactive)
  (let ((sessions (dg/agent-shell--collect-active-sessions exclude-buffer)))
    (with-temp-file dg/agent-shell-active-file
      (let ((print-length nil)
            (print-level nil))
        (insert ";; -*- mode: lisp-data; -*-\n")
        (insert ";; Auto-generated by dg-agent-shell. Do not edit.\n")
        (prin1 sessions (current-buffer))
        (insert "\n")))
    (when (called-interactively-p 'interactive)
      (message "Saved %d agent-shell session%s"
               (length sessions)
               (if (= 1 (length sessions)) "" "s")))))

(defun dg/agent-shell--save-on-buffer-kill ()
  "Re-save the session list when an agent-shell buffer is killed."
  (when (derived-mode-p 'agent-shell-mode)
    (let ((dying-buffer (current-buffer)))
      (run-at-time 0 nil
                   (lambda ()
                     (dg/agent-shell-save-active-sessions dying-buffer))))))

(add-hook 'kill-emacs-hook #'dg/agent-shell-save-active-sessions)
(add-hook 'kill-buffer-hook #'dg/agent-shell--save-on-buffer-kill)

(defun dg/agent-shell--read-active-sessions ()
  "Read saved sessions from `dg/agent-shell-active-file'."
  (when (file-exists-p dg/agent-shell-active-file)
    (with-temp-buffer
      (insert-file-contents dg/agent-shell-active-file)
      (goto-char (point-min))
      (condition-case nil
          (read (current-buffer))
        (error nil)))))

(defun dg/agent-shell--read-summary-archive ()
  "Read the summary archive file as a list of plists."
  (when (file-exists-p dg/agent-shell-summary-archive-file)
    (with-temp-buffer
      (insert-file-contents dg/agent-shell-summary-archive-file)
      (goto-char (point-min))
      (condition-case nil
          (read (current-buffer))
        (error nil)))))

(defun dg/agent-shell--write-summary-archive (entries)
  "Write ENTRIES (list of plists) to the summary archive file."
  (with-temp-file dg/agent-shell-summary-archive-file
    (let ((print-length nil)
          (print-level nil))
      (insert ";; -*- mode: lisp-data; -*-\n")
      (insert ";; Append-only archive of agent-shell session summaries.\n")
      (prin1 entries (current-buffer))
      (insert "\n"))))

(defun dg/agent-shell--archive-summary (session-id summary &optional cwd)
  "Upsert SESSION-ID's SUMMARY in the archive, optionally with CWD context."
  (when (and session-id summary (not (string-empty-p summary)))
    (let* ((existing (or (dg/agent-shell--read-summary-archive) '()))
           (without (seq-remove (lambda (e)
                                  (equal (plist-get e :session-id) session-id))
                                existing))
           (project (and cwd (file-name-nondirectory
                              (directory-file-name cwd))))
           (entry (list :session-id session-id
                        :summary summary
                        :project (or project "")
                        :cwd (or cwd "")
                        :updated-at (format-time-string "%FT%T%z"))))
      (dg/agent-shell--write-summary-archive (cons entry without)))))

(defun dg/agent-shell-archive-current-summaries ()
  "One-shot backfill: archive every live and active-file summary we know about."
  (interactive)
  (let* ((existing (or (dg/agent-shell--read-summary-archive) '()))
         (by-id (let ((m (make-hash-table :test 'equal)))
                  (dolist (e existing) (puthash (plist-get e :session-id) e m))
                  m))
         (added 0))
    (dolist (buf (dg/agent-shell--get-all-buffers))
      (with-current-buffer buf
        (when-let* ((id (map-nested-elt agent-shell--state '(:session :id)))
                    (s dg/agent-shell--session-summary))
          (puthash id (list :session-id id
                            :summary s
                            :project (file-name-nondirectory
                                      (directory-file-name default-directory))
                            :cwd default-directory
                            :updated-at (format-time-string "%FT%T%z"))
                   by-id)
          (cl-incf added))))
    (dolist (entry (or (ignore-errors (dg/agent-shell--read-active-sessions)) '()))
      (when-let* ((id (plist-get entry :session-id))
                  (s (plist-get entry :summary))
                  ((not (gethash id by-id))))
        (puthash id (list :session-id id
                          :summary s
                          :project (file-name-nondirectory
                                    (directory-file-name (or (plist-get entry :cwd) "")))
                          :cwd (or (plist-get entry :cwd) "")
                          :updated-at (format-time-string "%FT%T%z"))
                 by-id)
        (cl-incf added)))
    (let (out)
      (maphash (lambda (_ v) (push v out)) by-id)
      (dg/agent-shell--write-summary-archive out))
    (message "Archive: %d total entries (%d touched) at %s"
             (hash-table-count by-id)
             added
             (abbreviate-file-name dg/agent-shell-summary-archive-file))))

(defun dg/agent-shell--current-session-ids ()
  "Return session IDs for all currently-open agent-shell buffers."
  (delq nil
        (mapcar (lambda (buf)
                  (with-current-buffer buf
                    (map-nested-elt agent-shell--state '(:session :id))))
                (dg/agent-shell--get-all-buffers))))

(defun dg/agent-shell--format-relative-time (time)
  "Format TIME relative to now, e.g. '5m ago', '2h ago'."
  (when time
    (let ((seconds (float-time (time-subtract (current-time) time))))
      (cond
       ((< seconds 60)    (format "%ds ago"  (truncate seconds)))
       ((< seconds 3600)  (format "%dm ago"  (truncate (/ seconds 60))))
       ((< seconds 86400) (format "%dh ago"  (truncate (/ seconds 3600))))
       (t                 (format "%dd ago"  (truncate (/ seconds 86400))))))))

(defun dg/agent-shell--buffer-status (buf)
  "Return the activity status of agent-shell BUF: `permission', `working', or `ready'."
  (cond
   ((assq buf dg/agent-shell--pending-permissions) 'permission)
   ((map-elt (buffer-local-value 'agent-shell--state buf) :active-requests) 'working)
   (t 'ready)))

(defvar dg/agent-shell-dashboard-buffer-name "*agent-shell-dashboard*"
  "Name of the agent-shell dashboard buffer.")

(defvar-local dg/agent-shell-dashboard--saved-window-config nil
  "Window configuration saved when the dashboard was opened.")

(defvar-local dg/agent-shell-dashboard--row-positions nil
  "Buffer positions of rendered rows, in display order.")

(defvar-local dg/agent-shell-dashboard--columns nil
  "Per-column metadata: list of plists with :header-pos and :first-row-pos.")

(defvar-local dg/agent-shell-dashboard--highlight-overlays nil
  "Overlays highlighting the row at point, refreshed in `post-command-hook'.")

(defvar-local dg/agent-shell-dashboard--row-status-overlays nil
  "Persistent overlays applied to working / permission rows on render.")

(defface dg/agent-shell-dashboard-working-row-face
  '((((background dark))  :background "#1f2d3d")
    (((background light)) :background "#e7eef6"))
  "Persistent row background for sessions currently working."
  :group 'dg-agent-shell)

(defface dg/agent-shell-dashboard-permission-row-face
  '((((background dark))  :background "#3a2a1a")
    (((background light)) :background "#f4ece0"))
  "Persistent row background for sessions awaiting a permission decision."
  :group 'dg-agent-shell)

(defface dg/agent-shell-dashboard-awaiting-row-face
  '((((background dark))  :background "#5e5028")
    (((background light)) :background "#fef9b8"))
  "Persistent row background for sessions whose agent finished
recently and are waiting for the user's next prompt.
Gold-tinted to read as `your turn' on the fairyfloss palette."
  :group 'dg-agent-shell)

(defcustom dg/agent-shell-dashboard-awaiting-minutes 15
  "Promote a ready session to the `awaiting' status when its last
prompt was submitted within this many minutes."
  :type 'number
  :group 'dg-agent-shell)

(defcustom dg/agent-shell-dashboard-jump-keys
  "asdfjkl;qwertyuiopzxcvbnm"
  "Letters used as single-key shortcuts in `dg/agent-shell-dashboard-jump'."
  :type 'string
  :group 'dg-agent-shell)

(defvar dg/agent-shell-dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g")   #'dg/agent-shell-dashboard-refresh)
    (define-key map (kbd "n")   #'dg/agent-shell-dashboard-next)
    (define-key map (kbd "p")   #'dg/agent-shell-dashboard-previous)
    (define-key map (kbd "q")   #'dg/agent-shell-dashboard-quit)
    (define-key map (kbd "RET") #'dg/agent-shell-dashboard-visit)
    (define-key map (kbd "o")   #'dg/agent-shell-dashboard-visit-other-window)
    (define-key map (kbd "f")   #'dg/agent-shell-dashboard-fork)
    (define-key map (kbd "k")   #'dg/agent-shell-dashboard-kill)
    (define-key map (kbd "s")   #'dg/agent-shell-dashboard-send)
    (define-key map (kbd "N")   #'dg/agent-shell-dashboard-new-session-here)
    (define-key map (kbd "M")   #'dg/agent-shell-start-new-session-pick-repo)
    (define-key map (kbd "?")   #'dg/agent-shell-transient-menu)
    (define-key map (kbd "j")   #'dg/agent-shell-dashboard-jump)
    (define-key map (kbd "r")   #'dg/agent-shell-dashboard-reload)
    map)
  "Keymap for `dg/agent-shell-dashboard-mode'.")

(define-derived-mode dg/agent-shell-dashboard-mode special-mode "AgentDash"
  "Magit-style dashboard for live and closed agent-shell sessions."
  (setq truncate-lines t)
  (setq-local revert-buffer-function
              (lambda (&rest _) (dg/agent-shell-dashboard-refresh)))
  (add-hook 'post-command-hook
            #'dg/agent-shell-dashboard--update-highlight nil t))

(defun dg/agent-shell-dashboard--clear-highlight ()
  "Remove the row-highlight overlays."
  (mapc #'delete-overlay dg/agent-shell-dashboard--highlight-overlays)
  (setq dg/agent-shell-dashboard--highlight-overlays nil))

(defun dg/agent-shell-dashboard--apply-row-status-overlays ()
  "Tint working / permission rows with a persistent background.
Cursor's hl-line overlay has higher priority and so wins on the
row at point."
  (mapc #'delete-overlay dg/agent-shell-dashboard--row-status-overlays)
  (setq dg/agent-shell-dashboard--row-status-overlays nil)
  (let ((pos (point-min))
        (max (point-max)))
    (while (< pos max)
      (let* ((next (or (next-single-property-change pos 'dg-row) max))
             (row (get-text-property pos 'dg-row))
             (face (and row
                        (pcase (plist-get row :status)
                          ('working    'dg/agent-shell-dashboard-working-row-face)
                          ('permission 'dg/agent-shell-dashboard-permission-row-face)
                          ('awaiting   'dg/agent-shell-dashboard-awaiting-row-face)))))
        (when face
          (let ((ov (make-overlay pos next)))
            (overlay-put ov 'face face)
            (overlay-put ov 'priority -100)
            (push ov dg/agent-shell-dashboard--row-status-overlays)))
        (setq pos next)))))

(defun dg/agent-shell-dashboard--update-highlight ()
  "Highlight just the cell at point — i.e., the single line of the
row that the cursor is currently on. The other line of the same
row stays untouched so its persistent status background remains
visible (working / permission / awaiting tints)."
  (dg/agent-shell-dashboard--clear-highlight)
  (when-let ((row (get-text-property (point) 'dg-row)))
    (let* ((end (or (next-single-property-change (point) 'dg-row) (point-max)))
           (start (let ((p (point)))
                    (while (and (> p (point-min))
                                (eq (get-text-property (1- p) 'dg-row) row))
                      (setq p (1- p)))
                    p))
           (ov (make-overlay start end)))
      (overlay-put ov 'face 'hl-line)
      (overlay-put ov 'priority -50)
      (push ov dg/agent-shell-dashboard--highlight-overlays))))

(defun dg/agent-shell-dashboard--row-from-buffer (buf)
  "Build a dashboard row plist from live agent-shell BUF, or nil."
  (with-current-buffer buf
    (when-let ((id (map-nested-elt agent-shell--state '(:session :id))))
      (let* ((raw-status (dg/agent-shell--buffer-status buf))
             (last-time dg/agent-shell--last-prompt-time)
             (mins-since (and last-time
                              (/ (float-time
                                  (time-subtract (current-time) last-time))
                                 60.0)))
             (status (if (and (eq raw-status 'ready)
                              mins-since
                              (< mins-since
                                 dg/agent-shell-dashboard-awaiting-minutes))
                         'awaiting
                       raw-status)))
        (list :session-id id
              :buffer buf
              :cwd default-directory
              :identifier (map-elt (map-elt agent-shell--state :agent-config)
                                   :identifier)
              :summary dg/agent-shell--session-summary
              :status status
              :last-prompt-time dg/agent-shell--last-prompt-time
              :last-prompt-text dg/agent-shell--last-prompt-text)))))

(defun dg/agent-shell-dashboard--rows ()
  "Build the list of dashboard rows, deduped by session id.
Sources, in priority order: live buffers, active-sessions file, summary archive."
  (let ((seen (make-hash-table :test 'equal))
        (rows nil))
    (dolist (buf (dg/agent-shell--get-all-buffers))
      (when-let ((row (dg/agent-shell-dashboard--row-from-buffer buf)))
        (puthash (plist-get row :session-id) t seen)
        (push row rows)))
    (dolist (entry (or (ignore-errors (dg/agent-shell--read-active-sessions)) '()))
      (when-let ((id (plist-get entry :session-id))
                 ((not (gethash id seen))))
        (puthash id t seen)
        (push (list :session-id id
                    :buffer nil
                    :cwd (plist-get entry :cwd)
                    :identifier (plist-get entry :identifier)
                    :summary (plist-get entry :summary)
                    :status 'closed
                    :updated-at nil
                    :last-prompt-time nil
                    :last-prompt-text nil)
              rows)))
    (let ((archive (or (ignore-errors (dg/agent-shell--read-summary-archive)) '())))
      (dolist (entry archive)
        (when-let ((id (plist-get entry :session-id))
                   ((not (gethash id seen))))
          (puthash id t seen)
          (push (list :session-id id
                      :buffer nil
                      :cwd (plist-get entry :cwd)
                      ;; Archive entries predate per-agent identifiers.
                      ;; Default to claude-code since that's our only agent.
                      :identifier 'claude-code
                      :summary (plist-get entry :summary)
                      :status 'closed
                      :updated-at (plist-get entry :updated-at)
                      :last-prompt-time nil
                      :last-prompt-text nil)
                rows)))
      ;; Backfill missing summaries on rows from earlier sources.
      (dolist (row rows)
        (unless (plist-get row :summary)
          (when-let ((entry (seq-find
                             (lambda (e)
                               (equal (plist-get e :session-id)
                                      (plist-get row :session-id)))
                             archive)))
            (plist-put row :summary (plist-get entry :summary))))))
    (sort rows #'dg/agent-shell-dashboard--row-less-p)))

(defun dg/agent-shell-dashboard--row-time (row)
  "Return the most relevant timestamp for ROW, or nil."
  (or (plist-get row :last-prompt-time)
      (and (plist-get row :updated-at)
           (ignore-errors (date-to-time (plist-get row :updated-at))))))

(defun dg/agent-shell-dashboard--row-less-p (a b)
  "Return non-nil if dashboard row A should sort before B.
Live ahead of closed; within each group, newest activity first."
  (let ((live-a (plist-get a :buffer))
        (live-b (plist-get b :buffer))
        (ta (dg/agent-shell-dashboard--row-time a))
        (tb (dg/agent-shell-dashboard--row-time b)))
    (cond
     ((and live-a (not live-b)) t)
     ((and (not live-a) live-b) nil)
     ((and ta tb) (time-less-p tb ta))
     (ta t)
     (tb nil)
     (t (string< (or (plist-get a :session-id) "")
                 (or (plist-get b :session-id) ""))))))

(defun dg/agent-shell-dashboard--row-is-today (row)
  "Return non-nil if ROW's most-recent activity is on today's calendar date."
  (when-let ((time (dg/agent-shell-dashboard--row-time row)))
    (string= (format-time-string "%Y-%m-%d" time)
             (format-time-string "%Y-%m-%d" (current-time)))))

(defun dg/agent-shell-dashboard--status-glyph (status &optional is-today)
  "Return a propertized one-character glyph for row STATUS.
If IS-TODAY is non-nil, closed rows are rendered in a brighter face
to distinguish today's killed sessions from older archived ones."
  (pcase status
    ('ready      (propertize "●" 'face 'success))
    ('awaiting   (propertize "◉" 'face '(:inherit font-lock-variable-name-face
                                          :weight bold)))
    ('working    (propertize "▶" 'face '(:inherit font-lock-keyword-face
                                          :weight bold)))
    ('permission (propertize "!" 'face '(:inherit warning :weight bold)))
    ('closed     (propertize "○" 'face (if is-today
                                            'font-lock-string-face
                                          'shadow)))
    (_           (propertize "·" 'face 'shadow))))

(defun dg/agent-shell-dashboard--row-project (row)
  "Return the project basename for ROW's cwd, or empty string."
  (or (and (plist-get row :cwd)
           (file-name-nondirectory
            (directory-file-name (plist-get row :cwd))))
      ""))

(defcustom dg/agent-shell-dashboard-column-width 80
  "Width in characters of each project column in the dashboard."
  :type 'integer
  :group 'dg-agent-shell)

(defcustom dg/agent-shell-dashboard-column-gap 2
  "Number of blank chars between adjacent project columns."
  :type 'integer
  :group 'dg-agent-shell)

(defcustom dg/agent-shell-dashboard-pinned-projects '("infra")
  "Project names rendered as dedicated full-height leftmost columns.
Pinned columns appear in this list's order, left to right.  All
remaining projects flow into right-side column bands.  An empty
list reverts to the uniform banded layout across all projects."
  :type '(repeat string)
  :group 'dg-agent-shell)

(defun dg/agent-shell-dashboard--row-cells (row width)
  "Return two cells (line1 line2) representing ROW, each WIDTH-wide.
Each cell is a plist with :string and :row keys."
  (let* ((status (plist-get row :status))
         (is-today (dg/agent-shell-dashboard--row-is-today row))
         (glyph (dg/agent-shell-dashboard--status-glyph status is-today))
         (activity (or (dg/agent-shell--format-relative-time
                        (dg/agent-shell-dashboard--row-time row))
                       (if (eq status 'closed) "closed" "—")))
         (summary (or (plist-get row :summary) ""))
         (preview (replace-regexp-in-string
                   "[ \t\n\r]+" " "
                   (or (plist-get row :last-prompt-text) "")))
         (line1 (format "  %s  %-7s  %s"
                        glyph
                        (propertize activity 'face 'shadow)
                        summary))
         (line2 (concat "        "
                        (propertize "> " 'face 'shadow)
                        (propertize (if (string-empty-p preview) "—" preview)
                                    'face 'shadow))))
    (list (list :string (truncate-string-to-width line1 width nil ?\s)
                :row row
                :row-start t)
          (list :string (truncate-string-to-width line2 width nil ?\s)
                :row row))))

(defun dg/agent-shell-dashboard--group-cells (group width)
  "Return list of cells for GROUP rendered in a WIDTH-char column.
Each cell is a plist with :string and optional :row."
  (let* ((project (car group))
         (rows (cdr group))
         (n-live (seq-count (lambda (r) (plist-get r :buffer)) rows))
         (n-closed (- (length rows) n-live))
         (header (concat
                  (propertize (if (string-empty-p project) "(none)" project)
                              'face (if (zerop n-live)
                                        '(:inherit shadow :height 1.4)
                                      '(:inherit font-lock-function-name-face
                                        :height 1.4 :weight bold)))
                  "  "
                  (propertize (format "(%d live, %d closed)" n-live n-closed)
                              'face 'shadow)))
         (cells (list (list :string (truncate-string-to-width header width nil ?\s))
                      (list :string (make-string width ?\s)))))
    (dolist (row rows)
      (setq cells (append cells (dg/agent-shell-dashboard--row-cells row width))))
    cells))

(defun dg/agent-shell-dashboard--group-rows (rows)
  "Group ROWS by project. Returns alist of (PROJECT . ROWS).
Sections are sorted live-first, then by most recent activity."
  (let ((groups nil))
    (dolist (row rows)
      (let* ((project (or (dg/agent-shell-dashboard--row-project row) ""))
             (cell (assoc project groups)))
        (if cell
            (setcdr cell (cons row (cdr cell)))
          (push (cons project (list row)) groups))))
    (dolist (cell groups)
      (setcdr cell (nreverse (cdr cell))))
    (sort groups #'dg/agent-shell-dashboard--group-less-p)))

(defun dg/agent-shell-dashboard--group-newest-time (rows)
  "Return the most recent activity time across ROWS, or nil."
  (car (sort (delq nil (mapcar #'dg/agent-shell-dashboard--row-time rows))
             (lambda (x y) (time-less-p y x)))))

(defun dg/agent-shell-dashboard--group-less-p (a b)
  "Sort group A before B by liveness, then most-recent activity, then name."
  (let* ((rows-a (cdr a))
         (rows-b (cdr b))
         (live-a (seq-some (lambda (r) (plist-get r :buffer)) rows-a))
         (live-b (seq-some (lambda (r) (plist-get r :buffer)) rows-b))
         (ta (dg/agent-shell-dashboard--group-newest-time rows-a))
         (tb (dg/agent-shell-dashboard--group-newest-time rows-b)))
    (cond
     ((and live-a (not live-b)) t)
     ((and (not live-a) live-b) nil)
     ((and ta tb) (time-less-p tb ta))
     (ta t)
     (tb nil)
     (t (string< (car a) (car b))))))

(defun dg/agent-shell-dashboard--insert-cell (cell)
  "Insert CELL at point, stamping `dg-row' and recording first-row-pos.
Returns the buffer position where the cell starts."
  (let ((cell-start (point))
        (str (plist-get cell :string))
        (row (plist-get cell :row)))
    (insert str)
    (when row
      (when (plist-get cell :row-start)
        (push cell-start dg/agent-shell-dashboard--row-positions))
      (add-text-properties cell-start (point) (list 'dg-row row)))
    cell-start))

(defun dg/agent-shell-dashboard--insert-column-band (groups width gap)
  "Insert a band of side-by-side GROUPS, each WIDTH chars wide, GAP between.
Records each column's header-pos and first-row-pos in
`dg/agent-shell-dashboard--columns'."
  (let* ((columns (mapcar (lambda (g) (dg/agent-shell-dashboard--group-cells g width))
                          groups))
         (height (apply #'max (mapcar #'length columns)))
         (blank (list :string (make-string width ?\s)))
         (gap-str (make-string gap ?\s))
         (last-col-idx (1- (length columns)))
         (header-positions (make-vector (length columns) nil))
         (first-row-positions (make-vector (length columns) nil)))
    (dotimes (line-idx height)
      (let ((col-idx 0))
        (dolist (col columns)
          (let* ((cell (or (nth line-idx col) blank))
                 (str (plist-get cell :string))
                 (row (plist-get cell :row))
                 (cell-start (point)))
            (when (= line-idx 0)
              (aset header-positions col-idx cell-start))
            (insert str)
            (when row
              (when (plist-get cell :row-start)
                (push cell-start dg/agent-shell-dashboard--row-positions)
                (unless (aref first-row-positions col-idx)
                  (aset first-row-positions col-idx cell-start)))
              (add-text-properties cell-start (point) (list 'dg-row row))))
          (when (< col-idx last-col-idx)
            (insert gap-str))
          (cl-incf col-idx)))
      (insert "\n"))
    (insert "\n")
    (dotimes (col-idx (length columns))
      (push (list :project (car (nth col-idx groups))
                  :header-pos (aref header-positions col-idx)
                  :first-row-pos (aref first-row-positions col-idx))
            dg/agent-shell-dashboard--columns))))

(defun dg/agent-shell-dashboard--insert-asymmetric (pinned-groups right-groups width gap)
  "Render PINNED-GROUPS as dedicated full-height left columns.
RIGHT-GROUPS are laid out in bands to the right of the pinned ones.
Column metadata is recorded in `dg/agent-shell-dashboard--columns'
in left-to-right order: pinned first, then right-side band-by-band."
  (let* ((gap-str (make-string gap ?\s))
         (blank-cell (list :string (make-string width ?\s)))
         (pinned-columns (mapcar (lambda (g) (dg/agent-shell-dashboard--group-cells g width))
                                 pinned-groups))
         (n-pinned (length pinned-columns))
         (left-block-width (if (zerop n-pinned)
                               0
                             (+ (* width n-pinned) (* gap n-pinned))))
         (right-area-width (max 80 (- (max 80 (frame-width)) left-block-width)))
         (cols-per-band (max 1 (/ right-area-width (+ width gap))))
         (right-bands (seq-partition right-groups cols-per-band))
         (right-lines nil)
         (band-idx 0))
    (dolist (band right-bands)
      (let* ((cols (mapcar (lambda (g) (dg/agent-shell-dashboard--group-cells g width))
                           band))
             (band-h (apply #'max (mapcar #'length cols))))
        (dotimes (line-idx band-h)
          (push (list :type 'data
                      :band-idx band-idx
                      :line-in-band line-idx
                      :cells (mapcar (lambda (col) (or (nth line-idx col) blank-cell))
                                     cols))
                right-lines))
        (push (list :type 'spacer) right-lines))
      (cl-incf band-idx))
    (setq right-lines (nreverse right-lines))
    (let* ((max-pinned-h (if (zerop n-pinned)
                             0
                           (apply #'max (mapcar #'length pinned-columns))))
           (total (max max-pinned-h (length right-lines)))
           ;; Per-pinned-column tracking: vectors indexed by pinned col idx.
           (pinned-headers (make-vector n-pinned nil))
           (pinned-firsts  (make-vector n-pinned nil))
           ;; Right-side tracking, keyed by (band-idx . col-idx).
           (right-tracker (make-hash-table :test 'equal)))
      (dotimes (line-idx total)
        ;; Pinned columns, left to right.
        (let ((p-idx 0))
          (dolist (col pinned-columns)
            (let* ((cell (or (nth line-idx col) blank-cell))
                   (cell-start (dg/agent-shell-dashboard--insert-cell cell)))
              (when (= line-idx 0)
                (aset pinned-headers p-idx cell-start))
              (when (and (plist-get cell :row-start)
                         (not (aref pinned-firsts p-idx)))
                (aset pinned-firsts p-idx cell-start)))
            (insert gap-str)
            (cl-incf p-idx)))
        ;; Right-side cells (one band's worth, per line-idx).
        (let ((right-line (nth line-idx right-lines)))
          (when (and right-line (eq (plist-get right-line :type) 'data))
            (let ((b-idx (plist-get right-line :band-idx))
                  (line-in-band (plist-get right-line :line-in-band))
                  (cells (plist-get right-line :cells))
                  (col-idx 0)
                  (last-col (1- (length (plist-get right-line :cells)))))
              (dolist (cell cells)
                (let ((right-cell-start (dg/agent-shell-dashboard--insert-cell cell))
                      (key (cons b-idx col-idx)))
                  (let ((entry (gethash key right-tracker)))
                    (when (= line-in-band 0)
                      (puthash key (cons right-cell-start (cdr entry)) right-tracker))
                    (when (and (plist-get cell :row-start)
                               (or (not entry) (not (cdr entry))))
                      (puthash key
                               (cons (or (car (gethash key right-tracker))
                                         right-cell-start)
                                     right-cell-start)
                               right-tracker))))
                (when (< col-idx last-col)
                  (insert gap-str))
                (cl-incf col-idx)))))
        (insert "\n"))
      ;; Pinned columns come first in jump/column order.
      (dotimes (p-idx n-pinned)
        (push (list :project (car (nth p-idx pinned-groups))
                    :header-pos (aref pinned-headers p-idx)
                    :first-row-pos (aref pinned-firsts p-idx))
              dg/agent-shell-dashboard--columns))
      ;; Then right-side columns, band-by-band, col-by-col.
      (dotimes (b (length right-bands))
        (dotimes (c (length (nth b right-bands)))
          (let ((entry (gethash (cons b c) right-tracker)))
            (push (list :project (car (nth c (nth b right-bands)))
                        :header-pos (car entry)
                        :first-row-pos (cdr entry))
                  dg/agent-shell-dashboard--columns)))))))

(defun dg/agent-shell-dashboard-refresh ()
  "Re-render the dashboard contents, preserving the row at point.
Projects are laid out as side-by-side columns; if more projects
exist than fit horizontally, extra projects wrap to a second band."
  (interactive)
  (let* ((inhibit-read-only t)
         (saved-id (and (eq major-mode 'dg/agent-shell-dashboard-mode)
                        (plist-get (get-text-property (point) 'dg-row)
                                   :session-id)))
         (rows (dg/agent-shell-dashboard--rows))
         (live (seq-filter (lambda (r) (plist-get r :buffer)) rows))
         (closed (seq-remove (lambda (r) (plist-get r :buffer)) rows))
         (groups (dg/agent-shell-dashboard--group-rows rows))
         (width dg/agent-shell-dashboard-column-width)
         (gap dg/agent-shell-dashboard-column-gap)
         (pinned-names dg/agent-shell-dashboard-pinned-projects)
         ;; Resolve pinned project names to groups, preserving the requested order.
         (pinned-groups (delq nil (mapcar (lambda (n) (assoc n groups)) pinned-names)))
         (effective-groups
          (if pinned-groups
              (seq-remove (lambda (g) (memq g pinned-groups)) groups)
            groups))
         (cols-per-band (max 1 (/ (max 80 (frame-width)) (+ width gap))))
         (bands (seq-partition effective-groups cols-per-band)))
    (erase-buffer)
    (setq dg/agent-shell-dashboard--row-positions nil)
    (setq dg/agent-shell-dashboard--columns nil)
    (insert (propertize
             (format "Agent Shell  —  %d live, %d closed across %d project%s\n\n"
                     (length live) (length closed) (length groups)
                     (if (= 1 (length groups)) "" "s"))
             'face 'shadow))
    (cond
     (pinned-groups
      (dg/agent-shell-dashboard--insert-asymmetric
       pinned-groups effective-groups width gap))
     (t
      (dolist (band bands)
        (dg/agent-shell-dashboard--insert-column-band band width gap))))
    (setq dg/agent-shell-dashboard--row-positions
          (sort dg/agent-shell-dashboard--row-positions #'<))
    (setq dg/agent-shell-dashboard--columns
          (nreverse dg/agent-shell-dashboard--columns))
    (dg/agent-shell-dashboard--apply-row-status-overlays)
    (cond
     ((and saved-id
           (cl-loop for pos in dg/agent-shell-dashboard--row-positions
                    for r = (get-text-property pos 'dg-row)
                    when (equal saved-id (plist-get r :session-id))
                    return (progn (goto-char pos) t))))
     (dg/agent-shell-dashboard--row-positions
      (goto-char (car dg/agent-shell-dashboard--row-positions)))
     (t (goto-char (point-min))))))

(defun dg/agent-shell-dashboard--column-slot (pos)
  "Return the horizontal column slot index for buffer POS."
  (save-excursion
    (goto-char pos)
    (/ (current-column)
       (+ dg/agent-shell-dashboard-column-width
          dg/agent-shell-dashboard-column-gap))))

(defun dg/agent-shell-dashboard-next ()
  "Move to the next dashboard row in the same column."
  (interactive)
  (let* ((cur-slot (dg/agent-shell-dashboard--column-slot (point)))
         (next (seq-find (lambda (pos)
                           (and (> pos (point))
                                (= cur-slot
                                   (dg/agent-shell-dashboard--column-slot pos))))
                         dg/agent-shell-dashboard--row-positions)))
    (when next (goto-char next))))

(defun dg/agent-shell-dashboard-previous ()
  "Move to the previous dashboard row in the same column."
  (interactive)
  (let* ((cur-slot (dg/agent-shell-dashboard--column-slot (point)))
         (prev (cl-loop for pos in (reverse dg/agent-shell-dashboard--row-positions)
                        when (and (< pos (point))
                                  (= cur-slot
                                     (dg/agent-shell-dashboard--column-slot pos)))
                        return pos)))
    (when prev (goto-char prev))))

(defun dg/agent-shell-dashboard--row-at-point ()
  "Return the row plist at point, or signal a `user-error'."
  (or (get-text-property (point) 'dg-row)
      (user-error "No dashboard row at point")))

(defun dg/agent-shell-dashboard--ensure-buffer (row)
  "Return a live buffer for ROW, resuming the session if it is closed."
  (let ((buf (plist-get row :buffer)))
    (if (and buf (buffer-live-p buf))
        buf
      (or (dg/agent-shell--resume-session row)
          (user-error "Could not resume session")))))

(defun dg/agent-shell-dashboard-visit ()
  "Switch to the row's buffer (resuming first if it is closed)."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (buf (dg/agent-shell-dashboard--ensure-buffer row)))
    (pop-to-buffer-same-window buf)))

(defun dg/agent-shell-dashboard-visit-other-window ()
  "Display the row's buffer in another window, keeping focus here."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (buf (dg/agent-shell-dashboard--ensure-buffer row)))
    (display-buffer buf)))

(defun dg/agent-shell-dashboard-reload ()
  "Hard-reload the row's session in place.
Kills the current buffer (if any) and reopens a fresh one
resuming the same session id under the same cwd.  Use when the
agent has finished but the buffer didn't return control —
basically a fork-with-the-same-id-and-close-the-stale-one."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (session-id (or (plist-get row :session-id)
                         (user-error "Row has no session id")))
         (buf (plist-get row :buffer))
         (entry (list :session-id session-id
                      :cwd (plist-get row :cwd)
                      :identifier (or (plist-get row :identifier) 'claude-code)
                      :summary (plist-get row :summary))))
    (when (and buf (buffer-live-p buf))
      (let ((windows (get-buffer-window-list buf nil nil)))
        (kill-buffer buf)
        (dolist (w windows)
          (when (window-live-p w)
            (ignore-errors (delete-window w))))))
    (let ((new-buf (dg/agent-shell--resume-session entry)))
      (when new-buf
        (message "Reloaded session into %s" (buffer-name new-buf))))
    (dg/agent-shell-dashboard-refresh)))

(defun dg/agent-shell-dashboard-new-session-here ()
  "Start a new Claude Code session in the project of the row at point.
Falls back to the dashboard buffer's `default-directory' when the
cursor isn't on a row (e.g. on a section header)."
  (interactive)
  (let* ((row (get-text-property (point) 'dg-row))
         (cwd (and row (plist-get row :cwd))))
    (cond
     ((and cwd (file-directory-p cwd))
      (let* ((default-directory (file-name-as-directory (expand-file-name cwd)))
             (agent-shell-cwd-function (lambda () default-directory)))
        (dg/agent-shell-start-new-session)))
     (t (dg/agent-shell-start-new-session)))))

(defun dg/agent-shell-dashboard-fork ()
  "Fork the row's session into a new shell."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (data (or (and (plist-get row :buffer)
                        (dg/agent-shell--buffer-session-data
                         (plist-get row :buffer)))
                   row))
         (buf (dg/agent-shell--resume-session data)))
    (when buf
      (message "Forked into %s" (buffer-name buf)))
    (dg/agent-shell-dashboard-refresh)))

(defun dg/agent-shell-dashboard--forget-session (session-id)
  "Remove SESSION-ID from the active-sessions file and summary archive.
Does not touch the underlying agent's on-disk session log; if the
agent retains conversation history elsewhere, that needs to be
cleaned up separately."
  (let* ((active (or (ignore-errors (dg/agent-shell--read-active-sessions)) '()))
         (filtered (seq-remove
                    (lambda (e) (equal (plist-get e :session-id) session-id))
                    active)))
    (with-temp-file dg/agent-shell-active-file
      (let ((print-length nil)
            (print-level nil))
        (insert ";; -*- mode: lisp-data; -*-\n")
        (insert ";; Auto-generated by dg-agent-shell. Do not edit.\n")
        (prin1 filtered (current-buffer))
        (insert "\n"))))
  (let* ((archive (or (ignore-errors (dg/agent-shell--read-summary-archive)) '()))
         (filtered (seq-remove
                    (lambda (e) (equal (plist-get e :session-id) session-id))
                    archive)))
    (dg/agent-shell--write-summary-archive filtered)))

(defun dg/agent-shell-dashboard-kill ()
  "Kill or forget the row at point depending on its state.
On a live row: kill the buffer and any windows displaying it.
On a closed row: permanently forget the session, removing it
from the active-sessions file and summary archive."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (buf (plist-get row :buffer))
         (session-id (plist-get row :session-id))
         (label (or (plist-get row :summary)
                    (and session-id
                         (substring session-id 0 (min 8 (length session-id))))
                    "this row")))
    (cond
     ((and buf (buffer-live-p buf))
      (when (yes-or-no-p (format "Kill %s? " (buffer-name buf)))
        (let ((windows (get-buffer-window-list buf nil nil)))
          (kill-buffer buf)
          (dolist (w windows)
            (when (window-live-p w)
              (ignore-errors (delete-window w)))))
        (dg/agent-shell-dashboard-refresh)))
     ((null session-id)
      (user-error "Row has no session id"))
     (t
      (when (yes-or-no-p
             (format "Forget closed session \"%s\" permanently? " label))
        (dg/agent-shell-dashboard--forget-session session-id)
        (dg/agent-shell-dashboard-refresh))))))

(defun dg/agent-shell-dashboard-send ()
  "Pop a compose buffer to send a prompt to the row's session."
  (interactive)
  (let* ((row (dg/agent-shell-dashboard--row-at-point))
         (buf (dg/agent-shell-dashboard--ensure-buffer row)))
    (dg/agent-shell--show-prompt
     buf
     (lambda (text)
       (with-current-buffer buf
         (agent-shell-queue-request text))))))

(defun dg/agent-shell-dashboard--render-jump-view (labeled)
  "Erase buffer and render only project headers with giant labels.
Letters are placed at the same horizontal column as the dashboard
showed each project, so the eye lands in the right place."
  (let* ((inhibit-read-only t)
         (descriptors (mapcar #'cdr labeled))
         (lines (make-hash-table :test 'eql)))
    ;; Collect (line-num . line-string) per relevant line, before erasing.
    (dolist (pair labeled)
      (let* ((ch (car pair))
             (d (cdr pair))
             (project (plist-get d :project))
             (h-pos (plist-get d :header-pos))
             (fr-pos (plist-get d :first-row-pos)))
        (when h-pos
          (let* ((line (line-number-at-pos h-pos))
                 (col (save-excursion (goto-char h-pos) (current-column)))
                 (existing (gethash line lines "")))
            (puthash line
                     (dg/agent-shell-dashboard--place-at-col
                      existing col
                      (propertize (or project "")
                                  'face '(:inherit font-lock-function-name-face
                                          :height 1.5 :weight bold)))
                     lines)))
        (when fr-pos
          (let* ((line (line-number-at-pos fr-pos))
                 (col (save-excursion (goto-char fr-pos) (current-column)))
                 (existing (gethash line lines "")))
            (puthash line
                     (dg/agent-shell-dashboard--place-at-col
                      existing col
                      (propertize (format " %c " ch)
                                  'face '(:foreground "black"
                                          :background "yellow"
                                          :weight bold
                                          :height 5.0)))
                     lines)))))
    (erase-buffer)
    (insert (propertize "Pick a column:\n\n" 'face 'shadow))
    (let* ((line-keys (sort (hash-table-keys lines) #'<))
           (max-line (or (car (last line-keys)) 0)))
      (dotimes (i max-line)
        (insert (gethash (1+ i) lines "") "\n")))))

(defun dg/agent-shell-dashboard--place-at-col (existing col str)
  "Return EXISTING line with STR placed starting at column COL.
Pads with spaces if EXISTING is shorter than COL.  Overwrites
existing characters at and after COL."
  (let ((existing-w (string-width existing))
        (str-w (string-width str)))
    (cond
     ((>= col existing-w)
      (concat existing (make-string (- col existing-w) ?\s) str))
     (t
      (concat (substring existing 0 col)
              str
              (if (>= (+ col str-w) existing-w)
                  ""
                (substring existing (+ col str-w))))))))

(defun dg/agent-shell-dashboard-jump ()
  "Jump to the first row of a column via single-key shortcuts.
Replaces the dashboard contents with a switch-window-style label
view while waiting for input, then restores the dashboard and
moves point to the chosen column's first row."
  (interactive)
  (let* ((targets (seq-filter (lambda (c) (plist-get c :first-row-pos))
                              dg/agent-shell-dashboard--columns))
         (keys (string-to-list dg/agent-shell-dashboard-jump-keys)))
    (when (null targets)
      (user-error "No columns to jump to"))
    (let* ((labeled (cl-loop for tgt in targets
                             for ch in keys
                             collect (cons ch tgt)))
           (chosen-idx nil)
           (saved-point (point)))
      (unwind-protect
          (progn
            (dg/agent-shell-dashboard--render-jump-view labeled)
            (let* ((ch (read-char "Jump to column: "))
                   (idx (cl-position ch labeled :key #'car :test #'eq)))
              (cond
               ((or (eq ch ?\C-g) (eq ch 7)) nil)
               (idx (setq chosen-idx idx))
               (t (message "No such column: %c" ch)))))
        (dg/agent-shell-dashboard-refresh)
        (cond
         (chosen-idx
          (let* ((new-targets (seq-filter (lambda (c) (plist-get c :first-row-pos))
                                          dg/agent-shell-dashboard--columns))
                 (tgt (nth chosen-idx new-targets)))
            (when tgt (goto-char (plist-get tgt :first-row-pos)))))
         (t (goto-char (min saved-point (point-max)))))))))

(defun dg/agent-shell-dashboard-quit ()
  "Bury the dashboard and restore the saved window configuration."
  (interactive)
  (let ((cfg dg/agent-shell-dashboard--saved-window-config))
    (setq dg/agent-shell-dashboard--saved-window-config nil)
    (quit-window)
    (when cfg (set-window-configuration cfg))))

(defun dg/agent-shell-dashboard ()
  "Open the agent-shell dashboard, taking over the current frame.
The pre-existing window layout is restored when you press `q'.
Keys: RET visit, o open-in-other-window, n/p navigate, f fork,
k kill, s send prompt, N new session, M new session (pick repo),
g refresh, q quit and restore."
  (interactive)
  (let ((buf (get-buffer-create dg/agent-shell-dashboard-buffer-name))
        (cfg (current-window-configuration)))
    (with-current-buffer buf
      (dg/agent-shell-dashboard-mode)
      (setq-local dg/agent-shell-dashboard--saved-window-config cfg)
      (dg/agent-shell-dashboard-refresh))
    (pop-to-buffer-same-window buf)
    (delete-other-windows)))

(defun dg/agent-shell--all-known-summaries ()
  "Return a hash table mapping session-id to our session summary.
Live buffers > active-sessions file > long-term summary archive."
  (let ((map (make-hash-table :test 'equal)))
    (dolist (entry (or (ignore-errors (dg/agent-shell--read-summary-archive))
                       '()))
      (when-let* ((id (plist-get entry :session-id))
                  (s (plist-get entry :summary)))
        (puthash id s map)))
    (dolist (entry (or (ignore-errors (dg/agent-shell--read-active-sessions))
                       '()))
      (when-let* ((id (plist-get entry :session-id))
                  (s (plist-get entry :summary)))
        (puthash id s map)))
    (dolist (buf (dg/agent-shell--get-all-buffers))
      (with-current-buffer buf
        (when-let* ((id (map-nested-elt agent-shell--state '(:session :id)))
                    (s dg/agent-shell--session-summary))
          (puthash id s map))))
    map))

(defun dg/agent-shell--session-selection-columns-advice (cols)
  "Append `summary' column to COLS for the session-selection prompt."
  (append cols '(summary)))

(advice-add 'agent-shell--session-selection-columns
            :filter-return
            #'dg/agent-shell--session-selection-columns-advice)

(defun dg/agent-shell--session-column-value-advice (orig-fun column acp-session)
  "Provide value for our `summary' COLUMN; delegate to ORIG-FUN otherwise.
ACP-SESSION is the alist describing the session being labelled."
  (if (eq column 'summary)
      (let* ((id (map-elt acp-session 'sessionId))
             (summaries (dg/agent-shell--all-known-summaries))
             (s (and id (gethash id summaries))))
        (or s ""))
    (funcall orig-fun column acp-session)))

(advice-add 'agent-shell--session-column-value
            :around
            #'dg/agent-shell--session-column-value-advice)

(defun dg/agent-shell--session-column-face-advice (orig-fun column)
  "Face for our `summary' COLUMN; delegate to ORIG-FUN otherwise."
  (if (eq column 'summary)
      'font-lock-doc-face
    (funcall orig-fun column)))

(advice-add 'agent-shell--session-column-face
            :around
            #'dg/agent-shell--session-column-face-advice)

(defun dg/agent-shell-restore-active-sessions ()
  "Restore agent-shell sessions saved in `dg/agent-shell-active-file'.
Each session is reopened via ACP session resume/load, replaying
its conversation history.  Skips sessions already open and ones
whose cwd no longer exists."
  (interactive)
  (let* ((sessions (dg/agent-shell--read-active-sessions))
         (existing-ids (dg/agent-shell--current-session-ids))
         (restored 0)
         (skipped 0))
    (dolist (entry sessions)
      (let* ((session-id (plist-get entry :session-id))
             (cwd (plist-get entry :cwd))
             (summary (plist-get entry :summary))
             (identifier (plist-get entry :identifier))
             (config-fn (alist-get identifier dg/agent-shell--identifier-to-config-fn)))
        (cond
         ((member session-id existing-ids)
          (cl-incf skipped))
         ((not (and config-fn (fboundp config-fn)))
          (message "agent-shell: no config builder for %S, skipping %s"
                   identifier session-id)
          (cl-incf skipped))
         ((not (and cwd (file-directory-p cwd)))
          (message "agent-shell: cwd %s no longer exists, skipping" cwd)
          (cl-incf skipped))
         (t
          (let* ((default-directory cwd)
                 (agent-shell-cwd-function (lambda () cwd))
                 (config (funcall config-fn)))
            (agent-shell-start :config config :session-id session-id)
            (when summary
              (dolist (buf (dg/agent-shell--get-all-buffers))
                (with-current-buffer buf
                  (when (and (not dg/agent-shell--session-summary)
                             (equal session-id
                                    (map-nested-elt agent-shell--state
                                                    '(:session :id))))
                    (setq-local dg/agent-shell--session-summary summary))))))
          (cl-incf restored)))))
    (message "agent-shell: restored %d session%s, skipped %d"
             restored (if (= 1 restored) "" "s") skipped)))

(provide 'dg-agent-shell)
;;; dg-agent-shell.el ends here
(require 'agent-shell)
