;;; -*- lexical-binding: t; -*-
;;; Magit paints every added line one flat green, which wipes out the syntax
;;; highlighting -- magit-diff buffers have no font-lock of their own.
;;; diff-mode does: `diff-font-lock-syntax' renders each hunk in its source
;;; language's faces underneath the added/removed backgrounds, which is what
;;; the GitHub UI does.  So re-render the diff magit is showing in diff-mode.
;;;
;;; M-d in any magit buffer.  From a magit-diff buffer it reuses that buffer's
;;; exact range, args and file restriction; anywhere else it prompts.  A prefix
;;; arg always prompts.

(use-package diff-mode
  :config
  (setq diff-font-lock-syntax t)
  (setq diff-font-lock-prettify nil)
  (setq diff-refine 'font-lock))

(defun dg-magit-diff-syntax--revisions (range)
  "Split magit's RANGE into the (OLD NEW) revisions diff-mode wants.
A nil NEW means the right-hand side is the working tree, which is what
tells `diff-syntax-fontify-hunk' to read the file straight off disk
instead of asking git for it."
  (cond
   ((null range) (list "HEAD" nil))
   ((string-match "\\`\\(.*?\\)\\.\\.\\.?\\(.*\\)\\'" range)
    (let ((old (match-string 1 range))
          (new (match-string 2 range)))
      (list (if (equal old "") "HEAD" old)
            (if (equal new "") nil new))))
   (t (list range nil))))

(defconst dg-magit-diff-syntax--summary-args
  '("--stat" "--shortstat" "--numstat" "--dirstat" "--summary" "--name-only"
    "--name-status")
  "Diff args that suppress the hunks entirely, leaving nothing to highlight.")

(defun dg-magit-diff-syntax--git-args (range typearg args files)
  (append (list "diff")
          (and typearg (list typearg))
          (seq-remove (lambda (arg)
                        (seq-some (lambda (summary) (string-prefix-p summary arg))
                                  dg-magit-diff-syntax--summary-args))
                      args)
          (and range (list range))
          (and files (cons "--" files))))

(defun dg-magit-diff-syntax (&optional prompt)
  "Show the diff magit is displaying in `diff-mode', with syntax highlighting.
With a prefix arg PROMPT, always ask for the range instead of reusing
the current magit-diff buffer's."
  (interactive "P")
  (let* ((reuse (and (derived-mode-p 'magit-diff-mode) (not prompt)))
         (range (if reuse
                    magit-buffer-range
                  (magit-diff-read-range-or-commit "Diff range" nil prompt)))
         (typearg (and reuse (bound-and-true-p magit-buffer-typearg)))
         (args (and reuse magit-buffer-diff-args))
         (files (and reuse magit-buffer-diff-files))
         (toplevel (magit-toplevel))
         (buffer (get-buffer-create
                  (format "*diff: %s %s*"
                          (f-filename (directory-file-name toplevel))
                          (or range typearg "unstaged")))))

    (with-current-buffer buffer
      (let ((inhibit-read-only t)
            (default-directory toplevel))
        (erase-buffer)
        (apply #'magit-git-insert
               (dg-magit-diff-syntax--git-args range typearg args files))
        (diff-mode)

        ;; Without these, `diff-syntax-fontify-hunk' falls back to matching
        ;; the raw "b/foo.el" out of the hunk header against the filesystem,
        ;; which never resolves and leaves the hunk unhighlighted.  Claiming
        ;; the Git backend is also what lets the removed side be fontified:
        ;; diff-mode fetches that revision itself.
        (setq-local default-directory toplevel)
        (setq-local diff-default-directory toplevel)
        (setq-local diff-vc-backend 'Git)
        (setq-local diff-vc-revisions (dg-magit-diff-syntax--revisions range))

        (font-lock-flush)
        (goto-char (point-min))))

    (pop-to-buffer buffer)))

(with-eval-after-load 'magit
  (define-key magit-mode-map (kbd "M-d") #'dg-magit-diff-syntax))
