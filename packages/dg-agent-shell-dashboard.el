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
  :load-path "~/opt/agent-shell-dashboard"
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

  (defvar dg/agent-shell-dashboard-magit-context-lines 5
    "Diff lines each side of point sent when no region is active.")

  (defun dg/agent-shell-dashboard--magit-diff-snippet ()
    "Literal diff text for the magit position, straight from the buffer.
With an active region: the highlighted text verbatim.  Otherwise the
lines around point (`dg/agent-shell-dashboard-magit-context-lines' each
side), clamped to the current hunk so it never spills into a
neighbouring hunk or file header.  Nil when point is not on a hunk and
no region is active.

Taken from the magit buffer rather than re-read from disk: the buffer
is exactly what the user is looking at, including staged/unstaged and
other in-flight state a fresh read would miss."
    (if (use-region-p)
        (string-trim-right
         (buffer-substring-no-properties (region-beginning) (region-end)))
      (when (magit-section-match 'hunk)
        (let* ((n dg/agent-shell-dashboard-magit-context-lines)
               (hunk (magit-current-section))
               (lo (oref hunk start))
               (hi (oref hunk end))
               (beg (max lo (save-excursion (forward-line (- n))
                                            (line-beginning-position))))
               (end (min hi (save-excursion (forward-line (1+ n))
                                            (line-beginning-position)))))
          (string-trim-right (buffer-substring-no-properties beg end))))))

  (defun dg/agent-shell-dashboard--magit-context ()
    "Context string for a magit diff position, or nil when not applicable.
Returns the working-tree FILE:LINE (or FILE:START-END across a region)
as the anchor, followed by the literal diff text from the buffer as a
```diff``` fragment (see `dg/agent-shell-dashboard--magit-diff-snippet').

The reference tells the agent where the change lives in the worktree;
the fragment is the exact diff the user is viewing, so in-flight and
staged/unstaged state is preserved instead of being re-derived from
whatever happens to be on disk."
    (when (and (featurep 'magit)
               (derived-mode-p 'magit-diff-mode 'magit-status-mode
                               'magit-revision-mode)
               (magit-section-match '(hunk file)))
      (let* ((ref (if (and (use-region-p) (magit-section-match 'hunk))
                      (pcase-let ((`(,file . ,bl) (dg/agent-shell-dashboard--magit-file-line
                                                   (region-beginning)))
                                  (`(,_ . ,el) (dg/agent-shell-dashboard--magit-file-line
                                                (region-end))))
                        (cond ((and file bl el (/= bl el)) (format "%s:%d-%d" file bl el))
                              ((and file bl) (format "%s:%d" file bl))
                              (file file)))
                    (pcase-let ((`(,file . ,line) (dg/agent-shell-dashboard--magit-file-line)))
                      (when file
                        (if line (format "%s:%d" file line) file)))))
             (snippet (dg/agent-shell-dashboard--magit-diff-snippet)))
        (when ref
          (if (and snippet (not (string-empty-p (string-trim snippet))))
              (format "%s\n\n```diff\n%s\n```" ref snippet)
            ref)))))

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

  ;; ----------------------------------------------------------------
  ;; Route context from a worktree back to the session that owns it
  ;; ----------------------------------------------------------------

  ;; Sending a worktree file:line to whichever session happens to be
  ;; handy is worse than useless — that session has no idea why the
  ;; worktree exists.  Sessions almost always run from the main checkout,
  ;; so cwd does not identify the owner; the signal is which transcript
  ;; talks about the worktree.
  ;;
  ;; That signal is learned once, incrementally, off the hot path: after
  ;; each response we scan only the text that arrived since the last scan
  ;; and cache the result buffer-locally.  Dispatch then reads a variable.
  ;; Never scan on a keypress — Emacs is single threaded and a sweep
  ;; across a few dozen multi-hundred-KB session buffers locks the UI.

  (defvar-local dg/agent-shell-dashboard--buffer-worktree nil
    "Worktree this session is working in, as an absolute directory.
Learned incrementally by `dg/agent-shell-dashboard--learn-worktree'.")

  (defvar-local dg/agent-shell-dashboard--worktree-scan-pos nil
    "Position this buffer's worktree scan has already covered.")

  (defvar-local dg/agent-shell-dashboard--diff-session-buffer nil
    "agent-shell buffer this magit diff buffer was opened on behalf of.")

  (defun dg/agent-shell-dashboard--linked-worktree-p (dir)
    "Non-nil when DIR is a linked git worktree rather than a main checkout.
A linked worktree's `.git' is a file pointing at the real gitdir; a
primary checkout's is a directory."
    (let ((dotgit (expand-file-name ".git" dir)))
      (and (file-exists-p dotgit) (not (file-directory-p dotgit)))))

  (defun dg/agent-shell-dashboard--learn-worktree ()
    "Record the newest worktree mentioned in text added since the last scan.
Cheap by construction: each call looks only at what arrived since the
previous call, so the cost is spread across a session's lifetime instead
of landing on whoever asks the question."
    (when (derived-mode-p 'agent-shell-mode)
      (save-excursion
        (let ((start (max (point-min)
                          (or dg/agent-shell-dashboard--worktree-scan-pos
                              (point-min))))
              (found nil))
          (goto-char start)
          (while (re-search-forward
                  "\\(?:\\.claude\\|\\.agent-shell\\)/worktrees/[A-Za-z0-9._+-]+"
                  nil t)
            (setq found (match-string-no-properties 0)))
          (setq dg/agent-shell-dashboard--worktree-scan-pos (point-max))
          (when found
            (let ((dir (file-name-as-directory
                        (expand-file-name
                         found (or (ignore-errors (magit-toplevel))
                                   default-directory)))))
              (when (dg/agent-shell-dashboard--linked-worktree-p dir)
                (setq dg/agent-shell-dashboard--buffer-worktree dir))))))))

  (advice-add 'agent-shell-dashboard--check-for-summary-capture
              :after #'dg/agent-shell-dashboard--learn-worktree)

  (defun dg/agent-shell-dashboard--backfill-worktrees-step (buffers)
    "Learn one buffer's worktree, then reschedule for the rest of BUFFERS.
Chained rather than queued: timers that are all due run back to back
without yielding, so scheduling every buffer up front would still hand
Emacs one long uninterruptible block."
    (when buffers
      (let ((buf (car buffers)))
        (when (buffer-live-p buf)
          (with-current-buffer buf
            (dg/agent-shell-dashboard--learn-worktree))))
      (run-with-idle-timer
       0.2 nil #'dg/agent-shell-dashboard--backfill-worktrees-step (cdr buffers))))

  (defun dg/agent-shell-dashboard-backfill-worktrees ()
    "Learn every live session's worktree in the background.
Sessions that predate the incremental scan have nothing cached; this
walks them one buffer per idle slice so nothing blocks the UI."
    (interactive)
    (let ((buffers (agent-shell-dashboard--all-buffers)))
      (run-with-idle-timer
       0.2 nil #'dg/agent-shell-dashboard--backfill-worktrees-step buffers)
      (message "Learning worktrees for %d sessions in the background"
               (length buffers))))

  (defun dg/agent-shell-dashboard--context-worktree ()
    "Linked worktree the current buffer belongs to, or nil.
Checks `default-directory' before asking git, so the common case of a
magit diff already rooted in the worktree costs a single file test."
    (when (and (featurep 'magit)
               (derived-mode-p 'magit-diff-mode 'magit-status-mode
                               'magit-revision-mode))
      (let ((dir (file-name-as-directory (expand-file-name default-directory))))
        (if (dg/agent-shell-dashboard--linked-worktree-p dir)
            dir
          (when-let* ((top (ignore-errors (magit-toplevel))))
            (and (dg/agent-shell-dashboard--linked-worktree-p top)
                 (file-name-as-directory (expand-file-name top))))))))

  (defun dg/agent-shell-dashboard--session-for-worktree (dir)
    "Return the session whose cached worktree is DIR, or nil.
Reads buffer-local variables only — no buffer text is searched."
    (let ((dir (file-name-as-directory (expand-file-name dir))))
      (cl-find-if
       (lambda (buf)
         (or (equal dir (file-name-as-directory
                         (expand-file-name
                          (buffer-local-value 'default-directory buf))))
             (equal dir (buffer-local-value
                         'dg/agent-shell-dashboard--buffer-worktree buf))))
       (agent-shell-dashboard--all-buffers))))

  (defun dg/agent-shell-dashboard--context-target-buffer ()
    "Session that should receive context from the current buffer.
Prefers the session a diff was explicitly opened for, then the session
that owns the worktree the context comes from, then the default."
    (or (let ((stamped dg/agent-shell-dashboard--diff-session-buffer))
          (and (buffer-live-p stamped) stamped))
        (when-let* ((worktree (dg/agent-shell-dashboard--context-worktree))
                    (buf (dg/agent-shell-dashboard--session-for-worktree worktree)))
          (message "Routing to %s (owns %s)"
                   (buffer-name buf)
                   (file-name-nondirectory (directory-file-name worktree)))
          buf)
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
    "Append current-buffer context into an agent-shell viewport.
File buffers contribute their absolute path with line number(s);
non-file buffers contribute the active region or current line.

Context coming out of a linked worktree is routed to the session that
owns that worktree rather than to the default session — see
`dg/agent-shell-dashboard--context-target-buffer'."
    (interactive)
    (let* ((shell-buffer (dg/agent-shell-dashboard--context-target-buffer))
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
  ;; Diff the worktree a session works in
  ;; ----------------------------------------------------------------

  ;; agent-shell buffers stay rooted at the repo the session launched
  ;; from (default-directory is the main checkout); the agent creates
  ;; its `dg/<ticket>-<topic>' worktree itself, so Emacs has no stored
  ;; pointer to it.  Recover it from the one durable trace: the worktree
  ;; paths the agent typed into the transcript.  Cross-check those
  ;; against the repo's real worktrees so we never diff a stale guess.

  (defun dg/agent-shell-dashboard--session-worktrees (shell-buffer)
    "Worktrees SHELL-BUFFER's transcript mentions, most-recent first.
Each element is a cons (DIR . LABEL).  Scans the transcript backward
for `.claude'/`.agent-shell' worktree paths the agent typed, keeps the
first (most recent) mention of each, and validates it still exists on
disk.  Deliberately avoids `magit-list-worktrees', which stats every
worktree in the repo and costs seconds on a repo with many."
    (with-current-buffer shell-buffer
      (let ((top (expand-file-name (magit-toplevel)))
            (seen (make-hash-table :test 'equal))
            candidates)
        (save-excursion
          (goto-char (point-max))
          (while (re-search-backward
                  "\\(?:\\.claude\\|\\.agent-shell\\)/worktrees/[A-Za-z0-9._+-]+" nil t)
            (let ((dir (file-name-as-directory
                        (expand-file-name (match-string-no-properties 0) top))))
              (when (and (not (gethash dir seen))
                         (file-directory-p dir)
                         ;; A linked worktree has a `.git' file at its
                         ;; root; a plain directory that merely lives
                         ;; under .../worktrees/ does not.
                         (file-exists-p (expand-file-name ".git" dir)))
                (puthash dir t seen)
                (push (cons dir (file-name-nondirectory (directory-file-name dir)))
                      candidates)))))
        (nreverse candidates))))

  (defun dg/agent-shell-dashboard--diff-base ()
    "Resolve a base rev for the worktree in `default-directory'."
    (let ((mb (or (ignore-errors (magit-main-branch)) "main")))
      (or (cl-find-if #'magit-rev-verify
                      (list (concat "origin/" mb) mb
                            "origin/main" "origin/master" "main" "master"))
          "HEAD~")))

  (defun dg/agent-shell-dashboard-diff-session ()
    "Show a magit diff of the worktree the chosen session works in.
Uses the current agent-shell buffer, else prompts for one, finds the
worktrees its transcript mentions, and opens a range diff of the
selected worktree against the repo's main branch.  With no worktree
mentioned, falls back to `magit-status' in the session's directory."
    (interactive)
    (let* ((shell-buffer (if (derived-mode-p 'agent-shell-mode)
                             (current-buffer)
                           (dg/agent-shell-dashboard--prompt-for-buffer
                            "Diff worktree of session: ")))
           (worktrees (dg/agent-shell-dashboard--session-worktrees shell-buffer)))
      (if (null worktrees)
          (let ((default-directory (buffer-local-value 'default-directory shell-buffer)))
            (message "No worktree found in transcript; showing status of %s"
                     default-directory)
            (magit-status-setup-buffer default-directory))
        (let* ((dir (if (= 1 (length worktrees))
                        (car (car worktrees))
                      (let ((choice (completing-read
                                     "Worktree: " (mapcar #'cdr worktrees) nil t)))
                        (car (rassoc choice worktrees)))))
               (default-directory dir))
          (magit-diff-range (concat (dg/agent-shell-dashboard--diff-base) "..."))
          ;; Remember who this diff was opened for, so sending context
          ;; back from it needs no lookup at all.
          (when-let* ((diff-buffer (magit-get-mode-buffer 'magit-diff-mode)))
            (with-current-buffer diff-buffer
              (setq dg/agent-shell-dashboard--diff-session-buffer shell-buffer)))
          (with-current-buffer shell-buffer
            (setq dg/agent-shell-dashboard--buffer-worktree dir))))))

  ;; ----------------------------------------------------------------
  ;; Restore a session's context from its saved transcript
  ;; ----------------------------------------------------------------

  ;; Claude prunes the session state behind `--resume', but agent-shell's
  ;; own `<repo>/.agent-shell/transcripts/<timestamp>.md' files outlive
  ;; it by a wide margin (754 vs 142 for infra when this was written), so
  ;; they are the durable record.  They are named by start time rather
  ;; than session id, but each carries a `**Session ID:**' header line —
  ;; so a cheap scan of the first couple KB of each file recovers the
  ;; mapping even for sessions whose buffer is long gone.

  (defvar dg/agent-shell-dashboard--transcript-index-cache (make-hash-table :test 'equal)
    "Cache of DIR -> (MTIME . HASH of session-id -> transcript path).")

  (defvar dg/agent-shell-dashboard-transcript-tail-exchanges 6
    "How many trailing exchanges a prefix-arg restore inlines.")

  (defun dg/agent-shell-dashboard--transcript-dir (cwd)
    "Return the transcripts directory for CWD, or nil when absent.
Falls back to the enclosing repo root, since a session started in a
subdirectory still writes to the project's transcripts directory."
    (when cwd
      (cl-find-if
       #'file-directory-p
       (delq nil
             (list (expand-file-name ".agent-shell/transcripts/" cwd)
                   (when-let* ((top (ignore-errors
                                      (let ((default-directory cwd))
                                        (magit-toplevel)))))
                     (expand-file-name ".agent-shell/transcripts/" top)))))))

  (defun dg/agent-shell-dashboard--transcript-index (dir)
    "Hash of session-id -> transcript paths for DIR, cached on DIR's mtime.
Each value is a list of paths, newest first: resuming a session starts a
fresh transcript under the same id, so one session commonly spans several
files and the older ones still hold context the newest lacks.  Only the
head of each file is read, keeping a scan of several hundred transcripts
well under a keypress's worth of latency.

Transcripts written before agent-shell began stamping a `**Session ID:**'
header cannot be matched at all; those are reachable only through the
interactive picker."
    (let* ((mtime (file-attribute-modification-time (file-attributes dir)))
           (cached (gethash dir dg/agent-shell-dashboard--transcript-index-cache)))
      (if (and cached (equal (car cached) mtime))
          (cdr cached)
        (let ((index (make-hash-table :test 'equal)))
          ;; `directory-files' sorts ascending and filenames are start
          ;; timestamps, so pushing yields newest-first per id.
          (dolist (file (directory-files dir t "\\.md\\'"))
            (with-temp-buffer
              (ignore-errors
                (insert-file-contents file nil 0 2048)
                (goto-char (point-min))
                (when (re-search-forward "^\\*\\*Session ID:\\*\\* +\\([0-9a-fA-F-]+\\)"
                                         nil t)
                  (let ((id (match-string 1)))
                    (puthash id (cons file (gethash id index)) index))))))
          (puthash dir (cons mtime index)
                   dg/agent-shell-dashboard--transcript-index-cache)
          index))))

  (defun dg/agent-shell-dashboard--jsonl-for-session (session-id cwd)
    "Path to Claude's raw JSONL log for SESSION-ID under CWD, if it survives.
Claude mangles the cwd into the directory name by replacing `/' and
`.' with `-'."
    (when (and session-id cwd agent-shell-dashboard-claude-projects-dir)
      (let* ((mangled (replace-regexp-in-string
                       "[/.]" "-" (directory-file-name (expand-file-name cwd))))
             (path (expand-file-name
                    (format "%s/%s.jsonl" mangled session-id)
                    agent-shell-dashboard-claude-projects-dir)))
        (and (file-exists-p path) path))))

  (defun dg/agent-shell-dashboard--pick-transcript (dir)
    "Prompt for a transcript in DIR, newest first, annotated with its topic."
    (let* ((files (nreverse
                   (sort (directory-files dir t "\\.md\\'") #'string<)))
           (choices
            (mapcar
             (lambda (file)
               (cons (format "%s  %s"
                             (file-name-base file)
                             (or (dg/agent-shell-dashboard--transcript-topic file) ""))
                     file))
             files)))
      (unless choices
        (user-error "No transcripts in %s" dir))
      (cdr (assoc (completing-read "Transcript: " (mapcar #'car choices) nil t)
                  choices))))

  (defun dg/agent-shell-dashboard--transcript-topic (file)
    "First non-blank line of FILE's opening user message, for annotation."
    (with-temp-buffer
      (ignore-errors
        (insert-file-contents file nil 0 8192)
        (goto-char (point-min))
        (when (re-search-forward "^## User (" nil t)
          (forward-line 1)
          (while (and (looking-at-p "^[[:space:]]*$") (not (eobp)))
            (forward-line 1))
          (truncate-string-to-width
           (buffer-substring-no-properties
            (line-beginning-position) (line-end-position))
           90)))))

  (defun dg/agent-shell-dashboard--transcript-tail (file n)
    "Last N exchanges of FILE as a string, or nil.
Anchors on the timestamped `## User (' / `## Agent (' headers that
delimit exchanges; a bare `^## ' would match headings inside the
agent's own prose."
    (with-temp-buffer
      (ignore-errors
        (insert-file-contents file)
        (goto-char (point-max))
        (let ((count 0)
              (pos nil))
          (while (and (< count n)
                      (re-search-backward "^## \\(?:User\\|Agent\\) (" nil t))
            (setq pos (point))
            (cl-incf count))
          (when pos
            (buffer-substring-no-properties pos (point-max)))))))

  (defun dg/agent-shell-dashboard--restore-target ()
    "Resolve (BUFFER SESSION-ID CWD) for the restore command.
From the dashboard, uses the row at point — resuming it when its
buffer is gone, which is the usual state for a session old enough to
have lost its context.  Elsewhere uses the current agent-shell buffer
or prompts."
    (if-let* ((row (and (derived-mode-p 'agent-shell-dashboard-mode)
                        (get-text-property (point) 'dg-row))))
        (let* ((cached (plist-get row :buffer))
               (sid (plist-get row :session-id))
               (buf (or (and (buffer-live-p cached) cached)
                        (agent-shell-dashboard--find-live-buffer-for-session sid)
                        (agent-shell-dashboard--resume-session row)
                        (user-error "Could not resume session"))))
          (list buf sid (or (plist-get row :cwd)
                            (buffer-local-value 'default-directory buf))))
      (let ((buf (if (derived-mode-p 'agent-shell-mode)
                     (current-buffer)
                   (dg/agent-shell-dashboard--prompt-for-buffer
                    "Restore context in session: "))))
        (list buf
              (with-current-buffer buf
                (map-nested-elt agent-shell--state '(:session :id)))
              (buffer-local-value 'default-directory buf)))))

  (defun dg/agent-shell-dashboard-restore-context-from-transcript (&optional with-tail)
    "Inject a prompt telling the session to restore context from its transcript.
Finds the transcript via the live buffer's own `agent-shell--transcript-file'
when available, else by session id through the transcript index, else by
prompting.  The prompt is injected into the compose viewport rather than
sent, so it can be edited or extended before submitting.

We hand over the path rather than the contents: transcripts average a
couple hundred KB and run to several MB, so the agent should read and
slice the file itself.  With a prefix arg (WITH-TAIL), the last
`dg/agent-shell-dashboard-transcript-tail-exchanges' exchanges are also
inlined for immediate orientation."
    (interactive "P")
    (pcase-let* ((`(,shell-buffer ,session-id ,cwd)
                  (dg/agent-shell-dashboard--restore-target))
                 (dir (dg/agent-shell-dashboard--transcript-dir cwd))
                 (live-file (and (buffer-live-p shell-buffer)
                                 (buffer-local-value 'agent-shell--transcript-file
                                                     shell-buffer)))
                 (indexed (and dir session-id
                               (gethash session-id
                                        (dg/agent-shell-dashboard--transcript-index dir))))
                 ;; Newest first, with the live buffer's own transcript
                 ;; promoted to the front when it is not already there.
                 (transcripts
                  (or (let ((all (if (and live-file (file-exists-p live-file))
                                     (cons live-file (remove live-file indexed))
                                   indexed)))
                        (and all (delq nil all)))
                      (and dir
                           (progn
                             (message "No transcript matched session %s; pick one"
                                      (or session-id "?"))
                             (list (dg/agent-shell-dashboard--pick-transcript dir))))
                      (user-error "No transcripts directory for %s" cwd)))
                 (transcript (car transcripts))
                 (jsonl (dg/agent-shell-dashboard--jsonl-for-session session-id cwd))
                 (tail (and with-tail
                            (dg/agent-shell-dashboard--transcript-tail
                             transcript
                             dg/agent-shell-dashboard-transcript-tail-exchanges)))
                 (context
                  (concat
                   "If you have lost the context of this session, restore it from"
                   " the transcript saved at:\n\n  " transcript
                   "\n\nRead it before answering — start from the end and work"
                   " backward, since the most recent exchanges matter most."
                   (when (cdr transcripts)
                     (concat "\n\nThis session was resumed, so earlier stretches of"
                             " it live in these transcripts too, newest first:\n"
                             (mapconcat (lambda (f) (concat "  " f))
                                        (cdr transcripts) "\n")))
                   (when jsonl
                     (concat "\n\nA raw JSONL log with tool-call detail is also at:\n  "
                             jsonl))
                   (when tail
                     (concat "\n\nThe last few exchanges, inline:\n\n"
                             "--- BEGIN TRANSCRIPT TAIL ---\n"
                             tail
                             "\n--- END TRANSCRIPT TAIL ---")))))
      (pop-to-buffer shell-buffer)
      (agent-shell-viewport--show-buffer
       :shell-buffer shell-buffer
       :append context)
      (let ((viewport (agent-shell-viewport--buffer :shell-buffer shell-buffer)))
        (dg/agent-shell-dashboard--install-banner viewport shell-buffer)
        (dg/agent-shell-dashboard--compose-point-to viewport 'start))
      (message "Transcript: %s%s"
               (file-name-nondirectory transcript)
               (if (cdr transcripts)
                   (format " (+%d earlier)" (length (cdr transcripts)))
                 ""))))

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
  (define-key agent-shell-dashboard-mode-map (kbd "t")
              #'dg/agent-shell-dashboard-restore-context-from-transcript)
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
      ("f" "Send flycheck error" dg/agent-shell-dashboard-send-flycheck-error)
      ("t" "Restore context from transcript"
       dg/agent-shell-dashboard-restore-context-from-transcript)]
     ["Summary"
      ("T" "Generate All Summaries" dg/agent-shell-dashboard-generate-all-summaries)]
     ["Persistence"
      ("d" "Diff session worktree" dg/agent-shell-dashboard-diff-session)
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
