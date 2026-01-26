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

(defvar dg/agent-shell-summary-interval 10
  "Number of prompts between automatic summary generation.")

(defconst dg/agent-shell--summary-prompt
  "Generate a 3-6 word summary describing what we're working on in this session. Reply with ONLY the summary, no other text."
  "Prompt used to request session summaries.")

(defvar dg/agent-shell--permission-notification-enabled t
  "When non-nil, show completing-read prompt when agent-shell requests permission.")

(defvar dg/agent-shell--selected-buffer nil
  "Cached agent-shell buffer selection for the current command.")

(use-package agent-shell
  :ensure t
  :bind ("C-M-s-/" . dg/agent-shell-transient-menu)
  :custom
  (markdown-overlays-highlight-blocks nil)
  (agent-shell-anthropic-default-model-id "claude-opus-4-5-20251101")
  (agent-shell-anthropic-default-session-mode-id "acceptEdits")

  :config
  (setq agent-shell-mcp-servers
        `(((name . "linear")
           (type . "http")
           (url . "https://mcp.linear.app/mcp")
           (headers . (((name . "Authorization")
                        (value . ,(concat "Bearer " (dg/auth-source-get-password "linear.app")))))))))
  (defun dg/agent-shell--disable-markdown-overlays (orig-fun &rest args)
    "Skip markdown-overlays-put in agent-shell buffers for avy performance."
    (unless (derived-mode-p 'agent-shell-mode)
      (apply orig-fun args)))
  (advice-add 'markdown-overlays-put :around #'dg/agent-shell--disable-markdown-overlays)

  (setq agent-shell-header-style nil)
  (setq agent-shell-show-welcome-message nil)

  (defun dg/agent-shell--setup-new-session ()
    "Setup new agent-shell session with Opus model."
    (run-with-timer 10 nil
                    (lambda ()
                      (when (buffer-live-p (current-buffer))
                        (with-current-buffer (current-buffer)
                          (when (agent-shell--state)
                            (acp-send-request
                             :client (map-elt (agent-shell--state) :client)
                             :request (acp-make-session-set-model-request
                                       :session-id (map-nested-elt (agent-shell--state) '(:session :id))
                                       :model-id "claude-opus-4-5-20251101")
                             :on-success (lambda (response) (message "Switched to Opus model"))
                             :on-failure (lambda (error raw) (message "Failed to switch model: %S" error)))))))))

  (add-hook 'agent-shell-mode-hook #'dg/agent-shell--setup-new-session)

  (defun dg/agent-shell--track-prompt-submission (orig-fun &rest args)
    "Advice around `shell-maker-submit' to track prompts and capture last prompt."
    (when (derived-mode-p 'agent-shell-mode)
      (let ((input (string-trim (buffer-substring-no-properties
                                 (shell-maker--prompt-end-position) (point-max)))))
        (unless (string-empty-p input)
          (if (string= input dg/agent-shell--summary-prompt)
              (setq dg/agent-shell--summary-pending t)
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
        (let ((search-pattern (concat "^Claude Code> " (regexp-quote dg/agent-shell--summary-prompt))))
          (when (re-search-backward search-pattern nil t)
            (when (re-search-forward "<shell-maker-end-of-prompt>\n" nil t)
              (let* ((start (point))
                     (end (if (re-search-forward "^Claude Code> " nil t)
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

(defun dg/agent-shell--prompt-permission (buffer state request client)
  "Show a completing-read prompt for permission request.
BUFFER is the agent-shell buffer, STATE is the session state,
REQUEST is the ACP request, CLIENT is the ACP client."
  (let* ((tool-call (alist-get 'toolCall (alist-get 'params request)))
         (tool-call-id (alist-get 'toolCallId tool-call))
         (title (or (alist-get 'title tool-call) "Unknown action"))
         (kind (or (alist-get 'kind tool-call) ""))
         (options (alist-get 'options (alist-get 'params request)))
         (actions (agent-shell--make-permission-actions options))
         (kind-to-key '(("allow_once" . "y")
                        ("reject_once" . "n")
                        ("allow_always" . "!")))
         (choices (append
                   (mapcar (lambda (action)
                             (let* ((action-kind (map-elt action :kind))
                                    (key (cdr (assoc action-kind kind-to-key))))
                               (cons (format "%s - %s" (or key "?") (map-elt action :option))
                                     action-kind)))
                           actions)
                   '(("i - Ignore (do nothing)" . nil))))
         (prompt (format "[%s] %s (%s): "
                         (buffer-name buffer)
                         title
                         kind))
         (choice (completing-read prompt choices nil t)))
    (when-let* ((response-type (cdr (assoc choice choices)))
                (action (seq-find (lambda (a) (string= (map-elt a :kind) response-type)) actions)))
      (with-current-buffer buffer
        (agent-shell--send-permission-response
         :client client
         :request-id (alist-get 'id request)
         :option-id (map-elt action :option-id)
         :state state
         :tool-call-id tool-call-id
         :message-text (format "Permission: %s" (map-elt action :option))))
      (when (string= response-type "reject_once")
        (with-current-buffer buffer
          (agent-shell-interrupt t))))))

(defun dg/agent-shell--notify-permission-request (orig-fun &rest args)
  "Advice around `agent-shell--on-request' to notify on permission requests.
Calls ORIG-FUN with ARGS, then shows completing-read if it was a permission request."
  (let* ((request (plist-get args :request))
         (method (alist-get 'method request)))
    (prog1 (apply orig-fun args)
      (when (and dg/agent-shell--permission-notification-enabled
                 (equal method "session/request_permission"))
        (let* ((state (plist-get args :state))
               (buffer (map-elt state :buffer))
               (client (map-elt state :client)))
          (run-with-timer
           0.1 nil
           (lambda ()
             (when (buffer-live-p buffer)
               (dg/agent-shell--prompt-permission buffer state request client)))))))))

(advice-add 'agent-shell--on-request :around #'dg/agent-shell--notify-permission-request)

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
  "Get the agent-shell buffer in the same git repo root as the current buffer.
If current buffer is not in a repo, prompt to select from existing agent-shell buffers.
The selection is cached for the duration of the current command."
  (add-hook 'post-command-hook #'dg/agent-shell--clear-selected-buffer nil t)
  (or dg/agent-shell--selected-buffer
      (let ((project-buffers (agent-shell-project-buffers)))
        (setq dg/agent-shell--selected-buffer
              (if project-buffers
                  (seq-first project-buffers)
                (let ((all-buffers (dg/agent-shell--get-all-buffers)))
                  (cond
                   ((null all-buffers) nil)
                   ((= 1 (length all-buffers)) (car all-buffers))
                   (t (get-buffer (completing-read "Select agent-shell buffer: "
                                                   (mapcar #'buffer-name all-buffers) nil t))))))))))

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
  "Send MESSAGE to the agent-shell buffer."
  (dg/agent-shell--validate-process)
  (let ((shell-buffer (dg/agent-shell--get-buffer)))
    (with-current-buffer shell-buffer
      (goto-char (point-max))
      (insert message)
      (shell-maker-submit))))

(defun dg/agent-shell-ask ()
  "Send a bare prompt to agent-shell."
  (interactive)
  (dg/agent-shell--validate-process)
  (let ((prompt (read-string "Ask agent-shell: ")))
    (when (string-empty-p (string-trim prompt))
      (user-error "Prompt cannot be empty"))
    (dg/agent-shell--send-message prompt)))

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

(defalias 'dg/agent-shell-set-model
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-set-session-model)
  "Set model in agent-shell buffer without switching focus.")

(defalias 'dg/agent-shell-cycle-mode
  (dg/agent-shell--make-buffer-wrapper #'agent-shell-cycle-session-mode)
  "Cycle session mode in agent-shell buffer without switching focus.")

(defun dg/agent-shell-start-or-switch ()
  "Switch to existing agent-shell buffer for this project, or start a new Claude Code session."
  (interactive)
  (if-let* ((shell-buffer (agent-shell-project-buffers)))
      (switch-to-buffer shell-buffer)
    (agent-shell-anthropic-start-claude-code)))

(defun dg/agent-shell-start-new-session ()
  "Start a NEW Claude Code session for this directory, even if one exists.
This creates a uniquely named buffer (with timestamp) allowing multiple
independent Claude sessions for the same project."
  (interactive)
  (let* ((config (agent-shell-anthropic-make-claude-code-config))
         (timestamp (format-time-string "%H%M%S"))
         (original-buffer-name (map-elt config :buffer-name))
         (unique-buffer-name (format "%s-%s" original-buffer-name timestamp)))
    (map-put! config :buffer-name unique-buffer-name)
    (agent-shell-start :config config)))

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

(defun dg/agent-shell-execute-request ()
  "Intelligently send context to agent-shell based on current buffer state.
If buffer is a file: send file context with line/region
If buffer is not a file and region is active: send region
If buffer is not a file and no region: send current line"
  (interactive)
  (dg/agent-shell--validate-process)
  (let* ((shell-buffer (dg/agent-shell--get-buffer))
         (shell-cwd (with-current-buffer shell-buffer (agent-shell-cwd)))
         (file-path (buffer-file-name))
         (has-region (use-region-p))
         (start-line (if has-region
                         (line-number-at-pos (region-beginning))
                       (line-number-at-pos)))
         (end-line (if has-region
                       (line-number-at-pos (region-end))
                     (line-number-at-pos)))
         (prompt (read-string "agent-shell additional prompt (optional): "))
         (file-in-repo (and file-path
                            (file-in-directory-p file-path shell-cwd)))
         context-text
         message-text)

    (cond
     ((and file-path file-in-repo)
      (let ((relative-path (file-relative-name file-path shell-cwd)))
        (setq context-text
              (if (and has-region (not (= start-line end-line)))
                  (format "%s:%d-%d" relative-path start-line end-line)
                (format "%s:%d" relative-path start-line)))
        (setq message-text
              (if (string-empty-p (string-trim prompt))
                  context-text
                (format "%s\n\n%s" prompt context-text)))))

     (file-path
      (let ((content (if has-region
                         (buffer-substring-no-properties (region-beginning) (region-end))
                       (buffer-substring-no-properties
                        (line-beginning-position)
                        (line-end-position)))))
        (setq message-text
              (if (string-empty-p (string-trim prompt))
                  content
                (format "%s\n\n%s" prompt content)))))

     (has-region
      (let ((region-text (buffer-substring-no-properties (region-beginning) (region-end))))
        (setq message-text
              (if (string-empty-p (string-trim prompt))
                  region-text
                (format "%s\n\n%s" prompt region-text)))))

     (t
      (let ((line-text (buffer-substring-no-properties
                        (line-beginning-position)
                        (line-end-position))))
        (setq message-text
              (if (string-empty-p (string-trim prompt))
                  line-text
                (format "%s\n\n%s" prompt line-text))))))

    (dg/agent-shell--send-message message-text)))

(defun dg/agent-shell-execute-request-pick-buffer ()
  "Execute request with context, but prompt to pick which agent-shell buffer to send to."
  (interactive)
  (let ((dg/agent-shell--selected-buffer
         (dg/agent-shell--prompt-for-buffer "Send to agent-shell buffer: ")))
    (dg/agent-shell-execute-request)))

(defun dg/agent-shell-send-flycheck-error ()
  "Copy current flycheck error(s) and send to agent-shell with file context.
If region is active, copy all errors in the region and send all line numbers.
Otherwise, copy the error at point and send its line number."
  (interactive)
  (require 'flycheck)
  (dg/agent-shell--validate-process)
  (let* ((shell-buffer (dg/agent-shell--get-buffer))
         (shell-cwd (with-current-buffer shell-buffer (agent-shell-cwd)))
         (file-path (buffer-file-name))
         (has-region (use-region-p))
         (file-in-repo (and file-path
                            (file-in-directory-p file-path shell-cwd))))

    (let* ((errors (if has-region
                       (flycheck-overlay-errors-in (region-beginning) (region-end))
                     (flycheck-overlay-errors-at (point))))
           (error-messages (delq nil (mapcar #'flycheck-error-message errors))))

      (unless error-messages
        (user-error "No flycheck errors found"))

      (let* ((error-text (string-join error-messages "\n"))
             (context-text
              (if (and file-path file-in-repo)
                  (let ((relative-path (file-relative-name file-path shell-cwd)))
                    (if has-region
                        (let* ((start (region-beginning))
                               (end (region-end))
                               (errors (flycheck-overlay-errors-in start end))
                               (line-numbers (delete-dups
                                              (mapcar (lambda (err)
                                                        (line-number-at-pos (flycheck-error-pos err)))
                                                      errors))))
                          (if (= (length line-numbers) 1)
                              (format "%s:%d" relative-path (car line-numbers))
                            (format "%s:%s" relative-path
                                    (mapconcat #'number-to-string
                                               (sort line-numbers #'<)
                                               ","))))
                      (format "%s:%d" relative-path (line-number-at-pos))))
                (buffer-substring-no-properties
                 (if has-region (region-beginning) (line-beginning-position))
                 (if has-region (region-end) (line-end-position)))))
             (message-text (format "%s\n\n%s" error-text context-text)))

        (dg/agent-shell--send-message message-text)))))

(require 'transient)

(transient-define-prefix dg/agent-shell-transient-menu--internal ()
  "Agent Shell AI Pair Programming Interface."
  ["Agent Shell: AI pair programming with ACP"
   ["Core"
    ("S" "Start/Open Session" dg/agent-shell-start-or-switch)
    ("N" "Start NEW Session" dg/agent-shell-start-new-session)
    ("b" "Switch to Buffer" dg/agent-shell-switch-to-buffer)
    ("t" "Toggle Buffer" agent-shell-toggle)
    ("M" "Set Model" dg/agent-shell-set-model)
    ("m" "Cycle Mode" dg/agent-shell-cycle-mode)
    ("C-c C-c" "Interrupt" dg/agent-shell-interrupt)]
   ["Send to Agent"
    ("s" "Ask (bare prompt)" dg/agent-shell-ask)
    ("x" "Execute with context" dg/agent-shell-execute-request)
    ("X" "Execute (pick buffer)" dg/agent-shell-execute-request-pick-buffer)
    ("f" "Send flycheck error" dg/agent-shell-send-flycheck-error)
    ("F" "Send file" agent-shell-send-file)
    ("r" "Send region" agent-shell-send-region)
    ("w" "Send DWIM" agent-shell-send-dwim)]
   ["Navigation"
    ("n" "Next Item" dg/agent-shell-next-item)
    ("p" "Previous Item" dg/agent-shell-previous-item)]
   ["Permissions"
    ("y" "Accept (Yes)" dg/agent-shell-accept-permission)
    ("n" "Reject (No)" dg/agent-shell-reject-permission)
    ("!" "Always Accept" dg/agent-shell-always-accept-permission)
    ("v" "View Diff" dg/agent-shell-view-diff)]
   ["Debug"
    ("d" "View Traffic" agent-shell-view-traffic)
    ("V" "Version" agent-shell-version)
    ("l" "Toggle Logging" agent-shell-toggle-logging)
    ("L" "Reset Logs" agent-shell-reset-logs)]
   ["Summary"
    ("T" "Generate All Summaries" dg/agent-shell-generate-all-summaries)]])

(defun dg/agent-shell-transient-menu ()
  "Save current buffer and invoke agent-shell transient menu."
  (interactive)
  (when (buffer-file-name)
    (save-buffer))
  (dg/agent-shell-transient-menu--internal))

(with-eval-after-load 'key-chord
  (key-chord-define-global "z/" 'dg/agent-shell-transient-menu))

(provide 'dg-agent-shell)
;;; dg-agent-shell.el ends here
