;;; dg-agent-shell-dashboard.el --- Personal dashboard layer -*- lexical-binding: t; -*-

;; Layers the public agent-shell-dashboard package with personal
;; preferences (summary prompt, pinned projects) and a set of
;; extensions the upstream package intentionally leaves out:
;; execute-with-context commands that pre-insert file:line / region /
;; flycheck context into agent-shell's viewport via `:append', a
;; manual summary force-capture, and a personal transient menu wired
;; up to a global z/ key-chord.
;;
;; The base agent-shell config (MCP servers, auth-source helper,
;; agent-shell customs) still lives in dg-agent-shell.el.  This file
;; is the dashboard layer only.

(use-package agent-shell-dashboard
  ;; Point at the local working clone so edits in
  ;; ~/opt/agent-shell-dashboard take effect on next emacs restart
  ;; without round-tripping through GitHub + `package-vc-upgrade'.
  :load-path "/Users/gempesaw/opt/agent-shell-dashboard"
  :demand t
  :custom
  (agent-shell-dashboard-summary-prompt
   "Label this ENTIRE session the way I would name a project folder: by what it was opened to accomplish, weighting how it started over the most recent messages. Recent prompts are usually tangents, not the theme.

First line: the densest possible description of the session's core, under 78 characters. Give 2-4 key specifics separated by semicolons, most central first. Prefer concrete nouns — systems, repos, components, error names, and any central id like INFRA-1234. No field labels, no prefixes, no quotes, no trailing period; never write the words ticket, branch, topics, keywords, or summary.

Second line: 6-10 comma-separated search anchors spanning the whole conversation (ids, file paths, tool names, error strings) — extra search terms, not the headline.

Output only those two lines, nothing else.")
  (agent-shell-dashboard-pinned-projects '("infra"))
  ;; Point at the original dg-agent-shell data files so historic
  ;; summaries / active-sessions survive the migration to the public
  ;; package (its defaults sit at agent-shell-dashboard-* names).
  (agent-shell-dashboard-active-sessions-file
   (expand-file-name "agent-shell-active.el" user-emacs-directory))
  (agent-shell-dashboard-summary-archive-file
   (expand-file-name "agent-shell-summaries.el" user-emacs-directory))

  :config
  (require 'dash)
  (require 's)
  (require 'ht)
  (require 'transient)

  (agent-shell-dashboard-setup)

  ;; Suppress `agent-shell-viewport--clean-up's "Kill shell session
  ;; too?" prompt — closing a compose viewport should never offer to
  ;; nuke its shell.  The var is `defvar-local' so this default
  ;; carries into every new viewport buffer.
  (setq-default agent-shell-viewport--clean-up nil)

  ;; ----------------------------------------------------------------
  ;; Row-buffer helper used by the row-ops below
  ;; ----------------------------------------------------------------

  (defun dg/agent-shell-dashboard--row-buffer ()
    "Return the live buffer for the dashboard row at point or signal."
    (let* ((row (or (get-text-property (point) 'dg-row)
                    (user-error "No dashboard row at point")))
           (cached (plist-get row :buffer))
           (sid (plist-get row :session-id))
           (buf (or (and (buffer-live-p cached) cached)
                    (agent-shell-dashboard--find-live-buffer-for-session sid))))
      (unless (and buf (buffer-live-p buf))
        (user-error "Row has no live buffer"))
      buf))

  ;; ----------------------------------------------------------------
  ;; Buffer selection helpers
  ;; ----------------------------------------------------------------

  (defun dg/agent-shell-dashboard--buffer-display-name (buf)
    "Get display name for BUF including summary if available."
    (let* ((name (buffer-name buf))
           (summary (buffer-local-value 'agent-shell-dashboard--buffer-summary buf)))
      (if summary
          (format "%s [%s]" name summary)
        name)))

  (defun dg/agent-shell-dashboard--prompt-for-buffer (&optional prompt)
    "Prompt user to select an agent-shell buffer.
PROMPT defaults to `Select agent-shell buffer: '."
    (let ((all-buffers (agent-shell-dashboard--all-buffers)))
      (cond
       ((null all-buffers)
        (user-error "No agent-shell buffers available"))
       ((= 1 (length all-buffers))
        (car all-buffers))
       (t
        (let* ((display-names (--map (cons (dg/agent-shell-dashboard--buffer-display-name it) it)
                                     all-buffers))
               (choice (completing-read (or prompt "Select agent-shell buffer: ")
                                        (-map #'car display-names) nil t)))
          (cdr (assoc choice display-names)))))))

  (defun dg/agent-shell-dashboard--default-buffer ()
    "Choose a default agent-shell buffer for execute-with-context commands.
Current buffer if it's agent-shell, then the first project buffer,
then the first known buffer.  Signals if none exist."
    (let ((all (agent-shell-dashboard--all-buffers))
          (project-buffers (and (fboundp 'agent-shell-project-buffers)
                                (agent-shell-project-buffers))))
      (cond
       ((derived-mode-p 'agent-shell-mode) (current-buffer))
       (project-buffers (car project-buffers))
       (all (car all))
       (t (user-error "No agent-shell buffers available")))))

  ;; ----------------------------------------------------------------
  ;; Context builder + execute-with-context commands
  ;; ----------------------------------------------------------------

  (defun dg/agent-shell-dashboard--magit-file-line (&optional pos)
    "Resolve the working-tree FILE and LINE for the diff at POS (or point).
Returns a cons (FILE . LINE); LINE is nil when point is not inside a
hunk body.  FILE is the on-disk worktree path in whatever checkout the
magit buffer belongs to — a linked worktree resolves within itself,
because `magit-diff-visit-file--noselect' keys off this buffer's own
`magit-toplevel'.  Committed-revision diffs are not handled specially."
    (save-excursion
      (when pos (goto-char pos))
      (pcase-let ((`(,buf ,tpos)
                   (ignore-errors
                     (magit-diff-visit-file--noselect nil t))))
        (when (buffer-live-p buf)
          (with-current-buffer buf
            (cons (buffer-file-name)
                  (and tpos (line-number-at-pos tpos))))))))

  (defun dg/agent-shell-dashboard--magit-context ()
    "Context string for a magit diff position, or nil when not applicable.
Default: the working-tree FILE:LINE at point, matching how file
buffers are referenced so the agent reads live code, not a frozen
patch fragment.  With an active region inside a hunk: FILE:START-END
plus the selected lines as a ```diff``` fragment, for when the change
itself is the subject."
    (when (and (featurep 'magit)
               (derived-mode-p 'magit-diff-mode 'magit-status-mode
                               'magit-revision-mode)
               (magit-section-match '(hunk file)))
      (if (and (use-region-p) (magit-section-match 'hunk))
          (let* ((beg (dg/agent-shell-dashboard--magit-file-line
                       (region-beginning)))
                 (end (dg/agent-shell-dashboard--magit-file-line (region-end)))
                 (file (car beg))
                 (bl (cdr beg))
                 (el (cdr end))
                 (patch (ignore-errors
                          (magit-diff-hunk-region-patch
                           (magit-current-section)))))
            (concat
             (cond ((and file bl el (/= bl el)) (format "%s:%d-%d" file bl el))
                   ((and file bl) (format "%s:%d" file bl))
                   (t (or file "")))
             (and patch (format "\n\n```diff\n%s```" patch))))
        (pcase-let ((`(,file . ,line) (dg/agent-shell-dashboard--magit-file-line)))
          (when file
            (if line (format "%s:%d" file line) file))))))

  (defun dg/agent-shell-dashboard--build-context ()
    "Build context string from the current buffer state.
For file buffers: absolute path with line number(s).
For magit diff buffers: the working-tree FILE:LINE at point (see
`dg/agent-shell-dashboard--magit-context').
For other non-file buffers: region text or current line."
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
       ((dg/agent-shell-dashboard--magit-context))
       (has-region
        (buffer-substring-no-properties (region-beginning) (region-end)))
       (t
        (buffer-substring-no-properties
         (line-beginning-position) (line-end-position))))))

  (defun dg/agent-shell-dashboard--viewport-queue-send ()
    "Submit the current viewport compose via `agent-shell-queue-request'.
Always queues — never errors with `Busy, try later'.  Upstream's
`agent-shell-viewport-compose-send-and-kill' is supposed to do the
same in 0.55, but in practice still throws `Busy' in some cases
(its `agent-shell-viewport--busy-p' check disagrees with
`shell-maker-busy' inside `--insert-to-shell-buffer'); we keep this
override as the reliable path."
    (interactive)
    (let* ((prompt (s-trim (buffer-string)))
           (shell-buffer (agent-shell-viewport--shell-buffer))
           (viewport (current-buffer)))
      (when (s-blank? prompt)
        (user-error "Nothing to send"))
      (with-current-buffer shell-buffer
        (agent-shell-queue-request prompt))
      (kill-buffer viewport)
      (pop-to-buffer shell-buffer)))

  (defvar dg/agent-shell-dashboard-banner-lines 15
    "How many trailing session lines the compose banner shows.")

  (defun dg/agent-shell-dashboard--session-tail (shell-buffer n)
    "Return the last N non-blank-trimmed lines of SHELL-BUFFER's text."
    (with-current-buffer shell-buffer
      (save-excursion
        (goto-char (point-max))
        (let ((end (point)))
          (forward-line (- n))
          (let ((tail (s-trim-right
                       (buffer-substring-no-properties (point) end))))
            (if (s-blank? tail) "(empty session)" tail))))))

  (defun dg/agent-shell-dashboard--viewport-banner (shell-buffer)
    "Read-only banner naming SHELL-BUFFER, its summary, and its tail.
Rendered as an overlay `before-string' so it is display-only and
never becomes part of the composed prompt."
    (let* ((summary (and (boundp 'agent-shell-dashboard--buffer-summary)
                         (buffer-local-value
                          'agent-shell-dashboard--buffer-summary shell-buffer)))
           (tail (dg/agent-shell-dashboard--session-tail
                  shell-buffer dg/agent-shell-dashboard-banner-lines))
           (rule (propertize (concat (make-string 64 ?─) "\n") 'face 'shadow)))
      (concat
       (propertize (format "COMPOSING TO → %s\n" (buffer-name shell-buffer))
                   'face '(:inherit success :weight bold))
       (when (and (stringp summary) (not (s-blank? summary)))
         (propertize (format "  %s\n" summary) 'face 'font-lock-doc-face))
       rule
       (propertize (concat tail "\n") 'face 'shadow)
       rule
       "\n")))

  (defun dg/agent-shell-dashboard--install-banner (viewport shell-buffer)
    "Put a fresh compose banner for SHELL-BUFFER atop VIEWPORT."
    (when (buffer-live-p viewport)
      (with-current-buffer viewport
        (remove-overlays (point-min) (point-max) 'dg-target-banner t)
        (let ((ov (make-overlay (point-min) (point-min) viewport)))
          (overlay-put ov 'dg-target-banner t)
          (overlay-put ov 'before-string
                       (dg/agent-shell-dashboard--viewport-banner shell-buffer))))))

  (defun dg/agent-shell-dashboard--compose-point-to (viewport where)
    "Put point at WHERE (`start' or `end') of the compose area in VIEWPORT.
Used to place the cursor sensibly relative to the banner and any
appended context: `end' for a bare compose (nothing below to sit
above), `start' when context was appended so typing lands above it."
    (when (buffer-live-p viewport)
      (let (pos)
        (with-current-buffer viewport
          (setq pos (if (eq where 'start) (point-min) (point-max)))
          (goto-char pos))
        (when-let ((win (get-buffer-window viewport t)))
          (set-window-point win pos)))))

  (defun dg/agent-shell-dashboard--pop-viewport-edit (shell-buffer)
    "Pop SHELL-BUFFER's viewport in edit mode, even if the shell is busy.
Upstream opens the viewport in view-mode while a request is in
flight; we force edit-mode so composing while busy works.  C-c C-c
is rebound locally to `dg/agent-shell-dashboard--viewport-queue-send'
because upstream's compose-send-and-kill still errors `Busy' in
some shells even on 0.55."
    (let ((viewport (agent-shell-viewport--buffer :shell-buffer shell-buffer)))
      (with-current-buffer viewport
        (unless (derived-mode-p 'agent-shell-viewport-edit-mode)
          (agent-shell-viewport-edit-mode)
          (agent-shell-viewport--initialize))
        (use-local-map (copy-keymap (current-local-map)))
        (local-set-key (kbd "C-c C-c")
                       #'dg/agent-shell-dashboard--viewport-queue-send))
      (dg/agent-shell-dashboard--install-banner viewport shell-buffer)
      (pop-to-buffer viewport)
      (dg/agent-shell-dashboard--compose-point-to viewport 'end)))

  (defun dg/agent-shell-dashboard-ask ()
    "Pop a viewport edit buffer for the default shell, busy-tolerant."
    (interactive)
    (dg/agent-shell-dashboard--pop-viewport-edit
     (dg/agent-shell-dashboard--default-buffer)))

  (defun dg/agent-shell-dashboard-send ()
    "Override the dashboard's row send: viewport edit mode + queueing.
The upstream `agent-shell-prompt-compose' refuses while the agent
is busy; this wrapper bypasses that by submitting on C-c C-c via
`agent-shell-queue-request'."
    (interactive)
    (let* ((row (or (get-text-property (point) 'dg-row)
                    (user-error "No dashboard row at point")))
           (cached (plist-get row :buffer))
           (sid (plist-get row :session-id))
           (shell-buffer (or (and (buffer-live-p cached) cached)
                             (agent-shell-dashboard--find-live-buffer-for-session sid)
                             (agent-shell-dashboard--resume-session row)
                             (user-error "Could not resume session"))))
      (dg/agent-shell-dashboard--pop-viewport-edit shell-buffer)))

  (defun dg/agent-shell-dashboard-execute-request ()
    "Append current-buffer context into the default agent-shell viewport.
File buffers contribute their absolute path with line number(s);
non-file buffers contribute the active region or current line."
    (interactive)
    (let* ((shell-buffer (dg/agent-shell-dashboard--default-buffer))
           (context (dg/agent-shell-dashboard--build-context)))
      (pop-to-buffer shell-buffer)
      (agent-shell-viewport--show-buffer
       :shell-buffer shell-buffer
       :append context)
      (let ((viewport (agent-shell-viewport--buffer :shell-buffer shell-buffer)))
        (dg/agent-shell-dashboard--install-banner viewport shell-buffer)
        (dg/agent-shell-dashboard--compose-point-to viewport 'start))))

  (defun dg/agent-shell-dashboard-execute-request-pick-buffer ()
    "Same as `dg/agent-shell-dashboard-execute-request' but pick the target."
    (interactive)
    (let* ((shell-buffer (dg/agent-shell-dashboard--prompt-for-buffer
                          "Send to agent-shell buffer: "))
           (context (dg/agent-shell-dashboard--build-context)))
      (pop-to-buffer shell-buffer)
      (agent-shell-viewport--show-buffer
       :shell-buffer shell-buffer
       :append context)
      (let ((viewport (agent-shell-viewport--buffer :shell-buffer shell-buffer)))
        (dg/agent-shell-dashboard--install-banner viewport shell-buffer)
        (dg/agent-shell-dashboard--compose-point-to viewport 'start))))

  (defun dg/agent-shell-dashboard-send-flycheck-error ()
    "Copy current flycheck error(s) and send to agent-shell with file context.
If region is active, copy all errors in the region with all line
numbers.  Otherwise, copy the error at point and send its line
number."
    (interactive)
    (require 'flycheck)
    (let* ((shell-buffer (dg/agent-shell-dashboard--default-buffer))
           (file-path (buffer-file-name))
           (has-region (use-region-p))
           (errors (if has-region
                       (flycheck-overlay-errors-in (region-beginning) (region-end))
                     (flycheck-overlay-errors-at (point))))
           (error-messages (-non-nil (-map #'flycheck-error-message errors))))

      (unless error-messages
        (user-error "No flycheck errors found"))

      (let* ((error-text (s-join "\n" error-messages))
             (context-text
              (cond
               ((and file-path has-region)
                (let* ((line-numbers (-distinct
                                      (--map (line-number-at-pos
                                              (flycheck-error-pos it))
                                             errors))))
                  (if (= (length line-numbers) 1)
                      (format "%s:%d" file-path (car line-numbers))
                    (format "%s:%s" file-path
                            (s-join "," (-map #'number-to-string
                                              (sort line-numbers #'<)))))))
               (file-path
                (format "%s:%d" file-path (line-number-at-pos)))
               (t
                (buffer-substring-no-properties
                 (if has-region (region-beginning) (line-beginning-position))
                 (if has-region (region-end) (line-end-position))))))
             (message-text (format "%s\n\n%s" error-text context-text)))

        (with-current-buffer shell-buffer
          (agent-shell-queue-request message-text)))))

  ;; ----------------------------------------------------------------
  ;; Generate all summaries (manual force-capture)
  ;; ----------------------------------------------------------------

  (defun dg/agent-shell-dashboard-generate-all-summaries (&optional force)
    "Generate summaries for all agent-shell buffers.
First tries to extract from existing buffer content, then queues
new requests for buffers that have no summary yet.

With a prefix arg (FORCE non-nil), clears every buffer's existing
summary first so each one gets a fresh capture.  Useful after
relaxing the on-store truncation cap to widen existing rows."
    (interactive "P")
    (let ((all-buffers (agent-shell-dashboard--all-buffers))
          (extracted 0)
          (queued 0)
          (skipped 0))
      (if (null all-buffers)
          (user-error "No agent-shell buffers available")
        (dolist (buf all-buffers)
          (with-current-buffer buf
            (when force
              (setq agent-shell-dashboard--buffer-summary nil))
            (when (and agent-shell-dashboard--buffer-summary
                       (or (s-starts-with? "<shell-maker" agent-shell-dashboard--buffer-summary)
                           (s-starts-with? "▶" agent-shell-dashboard--buffer-summary)))
              (setq agent-shell-dashboard--buffer-summary nil))

            (cond
             (agent-shell-dashboard--buffer-summary
              (cl-incf skipped))

             (t
              (setq agent-shell-dashboard--summary-pending t)
              (agent-shell-dashboard--check-for-summary-capture)
              (cond
               (agent-shell-dashboard--buffer-summary
                (cl-incf extracted))

               ((shell-maker-busy)
                (setq agent-shell-dashboard--summary-pending nil)
                (cl-incf skipped))

               (t
                (setq agent-shell-dashboard--summary-pending nil)
                (condition-case nil
                    (progn
                      (agent-shell-queue-request agent-shell-dashboard-summary-prompt)
                      (setq agent-shell-dashboard--summary-pending t)
                      (run-with-timer 5 nil
                                      #'agent-shell-dashboard--poll-for-summary
                                      buf 10)
                      (cl-incf queued))
                  (error (cl-incf skipped)))))))))
        (message "Summaries: %d extracted, %d queued, %d skipped"
                 extracted queued skipped))))

  ;; ----------------------------------------------------------------
  ;; Bind row commands into the dashboard mode-map
  ;; ----------------------------------------------------------------

  ;; x / X make sense in the dashboard: jumping FROM the dashboard
  ;; (current-buffer = dashboard) wouldn't yield context, but the user
  ;; calls these from code buffers via the transient.  f stays on the
  ;; public `fork' binding — flycheck-send is a code-buffer command
  ;; reachable via the transient, not the dashboard keymap.
  (define-key agent-shell-dashboard-mode-map (kbd "s") #'dg/agent-shell-dashboard-send)
  (define-key agent-shell-dashboard-mode-map (kbd "x") #'dg/agent-shell-dashboard-execute-request)
  (define-key agent-shell-dashboard-mode-map (kbd "X") #'dg/agent-shell-dashboard-execute-request-pick-buffer)

  ;; ----------------------------------------------------------------
  ;; Personal transient menu
  ;; ----------------------------------------------------------------

  (transient-define-prefix dg/agent-shell-dashboard-transient-menu--internal ()
    "Agent Shell AI Pair Programming Interface."
    ["Agent Shell"
     ["Core"
      ("N" "Start NEW Session" agent-shell-dashboard-start-new-session)
      ("M" "Start NEW Session (pick repo)" agent-shell-dashboard-start-new-session-pick-repo)
      ("b" "Switch to Buffer" dg/agent-shell-dashboard-switch-to-buffer)
      ("r" "Reload current session" dg/agent-shell-dashboard-reload-current)
      ("F" "Fork (resume in new buffer)" dg/agent-shell-dashboard-fork-current)]
     ["Send to Agent"
      ("s" "Ask (bare prompt)" dg/agent-shell-dashboard-ask)
      ("x" "Execute with context" dg/agent-shell-dashboard-execute-request)
      ("X" "Execute (pick buffer)" dg/agent-shell-dashboard-execute-request-pick-buffer)
      ("f" "Send flycheck error" dg/agent-shell-dashboard-send-flycheck-error)]
     ["Summary"
      ("T" "Generate All Summaries" dg/agent-shell-dashboard-generate-all-summaries)]
     ["Persistence"
      ("d" "Dashboard" agent-shell-dashboard)
      ("P" "Save active sessions" agent-shell-dashboard-save-active-sessions)
      ("R" "Restore active sessions" agent-shell-dashboard-restore-active-sessions)]])

  ;; Transient entries that target the picked / default buffer rather than
  ;; the row at point.  These pick a sensible default buffer (current
  ;; agent-shell buffer, project buffer, or first known) and then dispatch.

  (defun dg/agent-shell-dashboard-switch-to-buffer ()
    "Prompt to select and switch to an agent-shell buffer."
    (interactive)
    (switch-to-buffer
     (dg/agent-shell-dashboard--prompt-for-buffer "Switch to agent-shell buffer: ")))

  (defun dg/agent-shell-dashboard-reload-current ()
    "Reload the default agent-shell session in place."
    (interactive)
    (let ((shell-buffer (dg/agent-shell-dashboard--default-buffer)))
      (with-current-buffer shell-buffer
        (call-interactively #'agent-shell-reload))))

  (defun dg/agent-shell-dashboard-fork-current ()
    "Fork the default agent-shell session into a new buffer."
    (interactive)
    (let* ((source (dg/agent-shell-dashboard--default-buffer))
           (data (or (agent-shell-dashboard--buffer-session-data source)
                     (user-error "Source buffer has no active session")))
           (new-buffer (agent-shell-dashboard--resume-session data)))
      (when new-buffer
        (pop-to-buffer new-buffer)
        (message "Forked %s -> %s" (buffer-name source) (buffer-name new-buffer)))))

  (defun dg/agent-shell-dashboard-transient-menu ()
    "Save current buffer and invoke the agent-shell transient menu."
    (interactive)
    (when (buffer-file-name)
      (save-buffer))
    (dg/agent-shell-dashboard-transient-menu--internal))

  ;; ----------------------------------------------------------------
  ;; Global key bindings
  ;; ----------------------------------------------------------------

  (global-set-key (kbd "C-M-s-/") #'dg/agent-shell-dashboard-transient-menu)
  (global-set-key (kbd "<end>")   #'dg/agent-shell-dashboard-transient-menu)

  (with-eval-after-load 'key-chord
    (key-chord-define-global "z/" #'dg/agent-shell-dashboard-transient-menu)))

(provide 'dg-agent-shell-dashboard)
;;; dg-agent-shell-dashboard.el ends here
