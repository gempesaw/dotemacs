(defun google ()
  "Googles a query or region if any."
  (interactive)
  (browse-url
   (concat
    "http://www.google.com/search?ie=utf-8&oe=utf-8&q="
    (url-hexify-string (if mark-active
                           (buffer-substring (region-beginning) (region-end))
                         (read-string "Google: "))))))

(defun compile-again (pfx)
  "Run the same compile as the last time.

If there was no last time, or there is a prefix argument, this acts like
M-x compile."
  (interactive "p")
  (save-window-excursion
    (if (and (eq pfx 1)
             compilation-last-buffer)
        (progn
          (set-buffer compilation-last-buffer)
          (revert-buffer t t))
      (call-interactively 'compile))))

(defun replace-last-sexp ()
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%s" value))))

(defun add-semicolon-at-end-of-line ()
  (interactive)
  (save-excursion
    (end-of-line)
    (insert ";")))

(defun add-semi-eol-and-goto-next-line-indented ()
  (interactive)
  (add-semicolon-at-end-of-line)
  (end-of-line)
  (forward-line)
  (indent-according-to-mode)
  (back-to-indentation))

(defun create-newline-from-anywhere()
  (interactive)
  (end-of-line)
  (if (string-equal major-mode 'python-mode)
      (newline-and-indent)
    (reindent-then-newline-and-indent)))

(defun describe-variable-at-point ()
  (interactive)
  (let ((symb (variable-at-point)))
    (when (and symb (not (equal symb 0)))
      (save-window-excursion
        (message (describe-variable (variable-at-point)))))))

(defun extract-json-from-http-response (buffer)
  (let ((json nil))
    (save-excursion
      (set-buffer buffer)
      (goto-char (point-min))
      (re-search-forward "^$" nil 'move)
      (setq json (buffer-substring-no-properties (point) (point-max))))
    ;; (kill-buffer (current-buffer)))
    json))

(defun tail-entire-log (remote-box)
  (interactive "sBox to tail: ")
  (switch-to-buffer (tail-log remote-box "-n +0")))

(defun tail-short-log (remote-box)
  (interactive "sBox to tail: ")
  (switch-to-buffer (tail-log remote-box "")))

(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

(defun rotate-windows ()
  "Rotate your windows"
  (interactive)
  (cond ((not (> (count-windows)1))
         (message "You can't rotate a single window!"))
        (t
         (setq i 1)
         (setq numWindows (count-windows))
         (while  (< i numWindows)
           (let* (
                  (w1 (elt (window-list) i))
                  (w2 (elt (window-list) (+ (% i numWindows) 1)))

                  (b1 (window-buffer w1))
                  (b2 (window-buffer w2))

                  (s1 (window-start w1))
                  (s2 (window-start w2))
                  )
             (set-window-buffer w1  b2)
             (set-window-buffer w2 b1)
             (set-window-start w1 s2)
             (set-window-start w2 s1)
             (setq i (1+ i)))))))

(setq cleanup-buffer-tabs t)
(defun cleanup-buffer-safe ()
  "Perform a bunch of safe operations on the whitespace content of a buffer.
Does not indent buffer, because it is used for a before-save-hook, and that
might be bad."
  (interactive)
  (when cleanup-buffer-tabs
    (untabify (point-min) (point-max)))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'utf-8))

(defun dg-cleanup-buffer-toggle-tabs ()
  (interactive)
  (message
   (format "tabs cleanup: %s"
           (setq cleanup-buffer-tabs (not cleanup-buffer-tabs)))))

(defun dg-use-tabs-for-whitespace ()
  (interactive)
  (setq-local cleanup-buffer-tabs nil)
  (setq-local indent-tabs-mode t)
  (setq-local tab-width 4))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (cleanup-buffer-safe)
  (indent-region (point-min) (point-max))
  (if (s-equals-p "python-mode" major-mode)
      (python-black-buffer)
    (when lsp-mode (lsp-format-buffer))))

(defun magit-toggle-whitespace ()
  (interactive)
  (if (member "-w" magit-diff-options)
      (magit-dont-ignore-whitespace)
    (magit-ignore-whitespace)))

(defun magit-ignore-whitespace ()
  (interactive)
  (add-to-list 'magit-diff-options "-w")
  (magit-refresh))

(defun magit-dont-ignore-whitespace ()
  (interactive)
  (setq magit-diff-options (remove "-w" magit-diff-options))
  (magit-refresh))

(defun magit-quit-session ()
  "Restores the previous window configuration and kills the magit buffer"
  (interactive)
  (kill-buffer)
  (jump-to-register 265))

(defun paredit--is-at-start-of-sexp ()
  (and (looking-at "(\\|\\[")
       (not (nth 3 (syntax-ppss))) ;; inside string
       (not (nth 4 (syntax-ppss))))) ;; inside comment

(defun paredit-duplicate-closest-sexp ()
  (interactive)
  ;; skips to start of current sexp
  (while (not (paredit--is-at-start-of-sexp))
    (paredit-backward))
  (set-mark-command nil)
  ;; while we find sexps we move forward on the line
  (while (and (bounds-of-thing-at-point 'sexp)
              (<= (point) (car (bounds-of-thing-at-point 'sexp)))
              (not (= (point) (line-end-position))))
    (forward-sexp)
    (while (looking-at " ")
      (forward-char)))
  (kill-ring-save (mark) (point))
  ;; go to the next line and copy the sexprs we encountered
  (paredit-newline)
  (yank)
  (exchange-point-and-mark))

(defun find-function-C-source (fun-or-var &optional file type)
  (save-window-excursion
    (with-help-window (help-buffer)
      (prin1 fun-or-var)
      ;; Use " is " instead of a colon so that
      ;; it is easier to get out the function name using forward-sexp.
      (princ " is ")
      (describe-function-1 fun-or-var)
      (with-current-buffer standard-output
        ;; Return the text we displayed.
        (buffer-string))))
  (cons (help-buffer) 0))

(defun get-file-as-string (filePath)
  "Return FILEPATH's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string
     (buffer-string) "\n" t)))

(defun escape-quotes-in-region ()
  (interactive)
  (if (and transient-mark-mode mark-active)
      (save-restriction
        (narrow-to-region (region-beginning) (region-end))
        (goto-char (point-min))
        (while (re-search-forward "\"" nil t)
          (replace-match "\\\\\"" nil nil)))))

(defun markdown-preview-with-syntax-highlighting (&optional output-buffer-name)
  "Run `markdown' on the current buffer and preview the output in a browser."
  (interactive)
  (browse-url-of-buffer
   (with-current-buffer (markdown markdown-output-buffer-name)
     (goto-char (point-min))
     (if (> (length markdown-css-paths) 0)
         (insert "<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\""
                 markdown-css-path
                 "\"  />\n"))

     (if (> (length markdown-script-path) 0)
         (progn
           (insert "<script type=\"text/javascript\" src=\""
                   markdown-script-path
                   "\"  /></script>\n")
           (insert "<script type=\"text/javascript\">hljs.initHighlightingOnLoad();</script>")))
     markdown-output-buffer-name)))


(defun switch-between-buffers (interesting-buffer)
  (interactive)
  (if (not (string= interesting-buffer (buffer-name)))
      (switch-to-buffer interesting-buffer nil t)
    (switch-to-prev-buffer)
    nil))

(defun toggle-app-and-home (app cb)
  (interactive)
  (if (or (string-match-p app (buffer-name))
          (progn
            (other-window 1)
            (string-match-p app (buffer-name))))
      (jump-to-register 6245)
    (when (window-configuration-p 6245) (jump-to-register 6245))
    (window-configuration-to-register 6245)
    (funcall cb)))

;; http://emacs-fu.blogspot.com/2013/03/editing-with-root-privileges-once-more.html
(defun find-file-as-root ()
  "Like `ido-find-file, but automatically edit the file with
root-privileges (using tramp/sudo), if the file is not writable
by user."
  (interactive)
  (let ((file (ido-read-file-name "Edit as root: ")))
    (setq file (concat "/sudo:root@localhost:" file))
    (find-file file)))

;; http://ergoemacs.org/emacs/elisp_delete-current-file.html
(defun delete-current-file ( no-backup-p)
  "Delete the file associated with the current buffer.

Also close the current buffer.  If no file is associated, just close buffer without prompt for save.

A backup file is created with filename appended  ~ date time stamp ~ . Existing file of the same name is overwritten.

when called with `universal-argument', don't create backup."
  (interactive "P")
  (let (fName)
    (when (buffer-file-name) ; buffer is associated with a file
      (setq fName (buffer-file-name))
      (save-buffer fName)
      (if  no-backup-p
          (progn )
        (copy-file fName (concat fName "~" (format-time-string "%Y%m%d_%H%M%S") "~") t)
        )
      (delete-file fName)
      (message " %s  deleted." fName)
      )
    (kill-buffer (current-buffer))))

(defun smarter-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.

Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.

If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

;; http://www.emacswiki.org/emacs/SwitchingBuffers
(defun switch-to-other-buffer ()
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun prelude-auto-save-command ()
  "Save the current buffer if `prelude-auto-save' is not nil."
  (when (and buffer-file-name
             (buffer-modified-p (current-buffer))
             (file-writable-p buffer-file-name))
    (save-buffer)))

(defun s-second-half (separator string)
  "Return the second half of a STRING split on SEPARATOR"
  (cadr (s-split separator string)))

(defun open-cron-env ()
  "Open up a shell with the same envs as your cron

Prior to using this command, you'll probably want to put the
following in your crontab:

    * * * * * env > ~/cronenv

 and then comment it once it writes the ~/cronenv file.

http://stackoverflow.com/questions/2135478/how-to-simulate-the-environment-cron-executes-a-script-with"
  (interactive)
  (let ((buf "*cronenv*"))
    (async-shell-command "env - `cat ~/cronenv` /bin/sh" buf buf)))

(defun smother-process-query-on-exit (buffer)
  (set-process-query-on-exit-flag
   (get-buffer-process buffer) nil))

(defun cwd ()
  (interactive)
  (s-second-half " " (pwd)))

(defun open-in-finder ()
  (interactive)
  (save-window-excursion
    (async-shell-command "open -R ." "*open-in-finder*" nil)))

(defun open-line-and-indent ()
  (interactive)
  (save-excursion
    (newline 1)
    (when (not (string-equal major-mode 'python-mode))
      (indent-according-to-mode))))

(defun epoch (time)
  (interactive "nTime as epoch: ")
  (message "%s" (format-time-string "%D %R" (seconds-to-time time))))

(progn
  (defun dg-vsplit-last-buffer (prefix)
    "Split the window vertically and display the previous buffer."
    (interactive "p")
    (split-window-vertically)
    (other-window 1 nil)
    (if (= prefix 1)
        (switch-to-next-buffer)))

  (defun dg-hsplit-last-buffer (prefix)
    "Split the window horizontally and display the previous buffer."
    (interactive "p")
    (split-window-horizontally)
    (other-window 1 nil)
    (if (= prefix 1) (switch-to-next-buffer)))

  (global-set-key (kbd "C-x 2") 'dg-vsplit-last-buffer)
  (global-set-key (kbd "C-x 3") 'dg-hsplit-last-buffer))

(defun dg-reset-tags-table-list ()
  (interactive)
  (setq tags-table-list
        (-reject (lambda (file) (string-match (pcre-to-elisp ":|Trash") file))
                 tags-table-list)))

(progn
  (setq ar-auto-recompile nil)
  (defun ar-auto-re-compile ()
    (interactive)
    (setq ar-auto-recompile (not ar-auto-recompile))
    (message (format "Auto recompile is now %s" (if ar-auto-recompile "ON" "OFF"))))

  (defadvice save-buffer (after ar-auto-recompile activate)
    (save-window-excursion
      (let ((comp-proc (get-buffer-process (get-buffer "*compilation*"))))
        (when (and ar-auto-recompile
                   (get-buffer-window "*compilation*" t)
                   (not (and comp-proc
                             (eq (process-status comp-proc) 'run)))
                   (not (s-matches-p "magit" (buffer-name (current-buffer))))
                   (not (s-matches-p "COMMIT_EDITMSG" (buffer-name (current-buffer)))))
          (set-buffer compilation-last-buffer)
          (revert-buffer t t))))))

(defun dg-remove-remote-items ()
  (interactive)
  (let* ((lists '(tags-table-list projectile-known-projects)))
    (mapc (lambda (list)
            (set list (-filter (lambda (it)
                                 (not (string-match ":" it)))
                               (symbol-value list))))
          lists)))

(defun dg-cleanup-tags-table ()
  (interactive)
  (dg-remove-remote-items)
  (setq tags-table-list (--filter (file-exists-p it) tags-table-list)))


(progn
  (defvar dg-stratopan-password ""
    "My password to stratopan.

The defvar keeps things from going nuts; it's actually defined
out side of git, of course.")
  (defun dg-stratopan-password ()
    (interactive)
    (kill-new (format "%s" dg-stratopan-password)))

  (defun dg-alias-password ()
    (interactive)
    (kill-new (with-temp-buffer
                (insert-file-contents "~/git-alias-zebra-token")
                (buffer-string)))))

(progn
  (defun dg-camelcase-to-hyphen (&optional text)
    (if text
        (let ((string (substring-no-properties text)))
          (substring-no-properties
           (replace-regexp-in-string "." 'dg-hyphenate-char string t)
           1))
      ""))

  (defun dg-hyphenate-char (char)
    (if (string= char (upcase char))
        (format "-%s" (downcase char))
      char)))

(defun dg-browse-url-or-file ()
  (interactive)
  (let ((url (or (thing-at-point 'filename)
                 (thing-at-point 'url))))
    (when url
      (when (s-starts-with-p "/" url)
        (setq url (format "file://%s" url)))
      (when (s-contains-p "github.com" url)
        (setq url (s-replace "github.com:" "github.com/" (s-replace "[^:]//" "/tree/main/" url))))
      (browse-url url))))

(defun dg-kubernetes-exec-pod ()
  (interactive)
  (let ((pod (thing-at-point 'sexp)))
    (end-of-buffer)
    ;; use previous kc alias
    (comint-previous-input 1)
    (beginning-of-line)
    (forward-word)
    (delete-region (point) (line-end-position))
    (insert (format " exec -it %s -- /bin/sh" pod))))

(defun dg-base64-encode-region-no-break ()
  (interactive)
  (base64-encode-region (mark) (point) t))

(defun dg-open-curl ()
  (interactive)
  (beginning-of-line)
  (while (search-forward " -H " nil t)
    (backward-char 3)
    (insert " \\")
    (open-line 1)
    (next-line)
    (beginning-of-line))
  (beginning-of-line))

(provide 'dg-defun)
