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
  "Generate a 3-6 word summary describing what we're working on in this session. Reply with ONLY the summary, no other text."
  "Prompt used to request session summaries.")

(defvar dg/agent-shell--pending-permissions nil
  "Alist of (buffer . tool-call-title) for sessions awaiting permission.")

(defvar dg/agent-shell--selected-buffer nil
  "Cached agent-shell buffer selection for the current command.")

(use-package agent-shell
  :ensure t
  :bind (("C-M-s-/" . dg/agent-shell-transient-menu)
         ("<end>" . dg/agent-shell-transient-menu))
  :custom
  (agent-shell-highlight-blocks t)
  (agent-shell-anthropic-default-model-id "claude-opus-4-7")
  (agent-shell-anthropic-default-session-mode-id "bypassPermissions")

  :config
  (setq agent-shell-prefer-viewport-interaction nil)

  (setq agent-shell-session-strategy 'prompt)

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
  (setq agent-shell-show-welcome-message nil)

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
                ;; Iterate backward through lines, skipping empty and status lines
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
                  (message "Summary for %s: %s" (buffer-name) dg/agent-shell--session-summary))))))))))

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

(defvar dg/agent-shell--prompt-buffer " *agent-shell-prompt*"
  "Buffer name for composing agent-shell prompts.")

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
  (when-let* ((buf (get-buffer dg/agent-shell--prompt-buffer)))
    (kill-buffer buf)))

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
         (existing-buf (get-buffer dg/agent-shell--prompt-buffer))
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
      (let* ((buf (get-buffer-create dg/agent-shell--prompt-buffer))
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
  "Start a new Claude Code session and pop a compose buffer for the first prompt.
Buffer is uniquely named (with timestamp) so multiple sessions can
coexist for the same project."
  (interactive)
  (let* ((config (agent-shell-anthropic-make-claude-code-config))
         (timestamp (format-time-string "%H%M%S"))
         (unique-buffer-name (format "%s-%s" (map-elt config :buffer-name) timestamp))
         (before (dg/agent-shell--get-all-buffers)))
    (map-put! config :buffer-name unique-buffer-name)
    (agent-shell-start :config config)
    (let* ((after (dg/agent-shell--get-all-buffers))
           (new-buffer (car (seq-difference after before))))
      (if new-buffer
          (dg/agent-shell--show-prompt
           new-buffer
           (lambda (text)
             (with-current-buffer new-buffer
               (agent-shell-queue-request text))))
        (message "Could not locate new agent-shell buffer")))))

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
    ("V" "Dashboard (live)" dg/agent-shell-dashboard)
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

(defun dg/agent-shell--format-status (status)
  "Return a propertized label for STATUS."
  (pcase status
    ('permission (propertize "permission" 'face 'warning))
    ('working    (propertize "working"    'face 'font-lock-keyword-face))
    ('ready      (propertize "ready"      'face 'success))))

(defun dg/agent-shell--sort-by-prompt-time (a b)
  "Compare dashboard entries A and B by buffer's `dg/agent-shell--last-prompt-time'.
Returned in ascending order; the column flip flag puts newest at top
and pushes entries with no recorded prompt time to the bottom."
  (let* ((buf-a (car a))
         (buf-b (car b))
         (time-a (and (buffer-live-p buf-a)
                      (buffer-local-value 'dg/agent-shell--last-prompt-time buf-a)))
         (time-b (and (buffer-live-p buf-b)
                      (buffer-local-value 'dg/agent-shell--last-prompt-time buf-b))))
    (cond
     ((and time-a time-b) (time-less-p time-a time-b))
     (time-a nil)
     (time-b t)
     (t nil))))

(defun dg/agent-shell--dashboard-entries ()
  "Build `tabulated-list-entries' for the agent-shell dashboard."
  (mapcar
   (lambda (buf)
     (with-current-buffer buf
       (let* ((status (dg/agent-shell--format-status
                       (dg/agent-shell--buffer-status buf)))
              (project (file-name-nondirectory
                        (directory-file-name default-directory)))
              (summary (or dg/agent-shell--session-summary ""))
              (activity (or (dg/agent-shell--format-relative-time
                             dg/agent-shell--last-prompt-time)
                            "--"))
              (last-prompt (or dg/agent-shell--last-prompt-text ""))
              (preview (replace-regexp-in-string
                        "[ \t\n\r]+" " " last-prompt)))
         (list buf (vector status activity project summary preview)))))
   (dg/agent-shell--get-all-buffers)))

(defun dg/agent-shell-dashboard-switch ()
  "Switch to the agent-shell buffer at point in the dashboard."
  (interactive)
  (let ((buf (tabulated-list-get-id)))
    (cond
     ((not (and buf (buffer-live-p buf)))
      (user-error "No live buffer at point"))
     (t (switch-to-buffer buf)))))

(defvar dg/agent-shell-dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map (kbd "RET") #'dg/agent-shell-dashboard-switch)
    map)
  "Keymap for `dg/agent-shell-dashboard-mode'.")

(define-derived-mode dg/agent-shell-dashboard-mode tabulated-list-mode "AgentDash"
  "Dashboard for live agent-shell sessions, sorted by recent activity."
  (setq tabulated-list-format
        `[("Status"      11 t)
          ("Activity"    14 ,#'dg/agent-shell--sort-by-prompt-time)
          ("Project"     25 t)
          ("Summary"     36 t)
          ("Last prompt" 80 nil)])
  (setq tabulated-list-padding 1)
  (setq tabulated-list-sort-key (cons "Activity" t))
  (setq-local revert-buffer-function
              (lambda (&rest _)
                (setq tabulated-list-entries (dg/agent-shell--dashboard-entries))
                (tabulated-list-print t)))
  (tabulated-list-init-header))

(defun dg/agent-shell-dashboard ()
  "Pop a dashboard of live agent-shell sessions sorted by most recent activity.
RET on a row switches to that buffer; g refreshes."
  (interactive)
  (let ((buf (get-buffer-create "*agent-shell-dashboard*")))
    (with-current-buffer buf
      (dg/agent-shell-dashboard-mode)
      (setq tabulated-list-entries (dg/agent-shell--dashboard-entries))
      (tabulated-list-print))
    (pop-to-buffer buf)))

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
