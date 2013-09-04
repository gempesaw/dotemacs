(defun google ()
  "Googles a query or region if any."
  (interactive)
  (browse-url
   (concat
    "http://www.google.com/search?ie=utf-8&oe=utf-8&q="
    (url-hexify-string (if mark-active
                           (buffer-substring (region-beginning) (region-end))
                         (read-string "Google: "))))))

;; I don't want M-x term to ask me about what shell to run
;; this is pulled from term.el (C-h f term)
(defun cterm ()
  "Start a terminal-emulator in a new buffer.
The buffer is in Term mode; see `term-mode' for the commands to
use in that buffer.

I've redefined this in `defun.el', so that it doesn't ask for the
shell to run, and so it doesn't ask before getting killed.

\\<term-raw-map>Type \\[switch-to-buffer] to switch to another buffer."
  (interactive)
  (set-buffer (term-ansi-make-term "terminal" "/bin/bash"))
  (term-mode)
  (term-line-mode)
  (term-set-escape-char ?\C-x)
  ;; Don't ask about killing terminals
  (set-process-query-on-exit-flag (get-process "terminal") nil)
  (switch-to-buffer "terminal"))

(defun compile-again (pfx)
  """Run the same compile as the last time.

If there was no last time, or there is a prefix argument, this acts like
M-x compile.
"""
(interactive "p")
(if (and (eq pfx 1)
         compilation-last-buffer)
    (progn
      (set-buffer compilation-last-buffer)
      (revert-buffer t t))
  (call-interactively 'compile)))

(defun run-feature-in-all-browsers ()
  "passes the current file to a perl script that runs it in all
browsers."
  (interactive)
  (save-window-excursion
    (async-shell-command
     (concat "perl -w /opt/honeydew/bin/multipleBrowsers.pl "
             (buffer-file-name))
     "run-feature-in-all-browsers"))
  (set-buffer "run-feature-in-all-browsers")
  (dired-other-window "/Users/dgempesaw/tmp/sauce/"))

(defun reload-my-init ()
  (interactive)
  (load-file "/Users/dgempesaw/opt/dotemacs/init.el"))

(defun replace-last-sexp ()
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%s" value))))

(defun kill-matching-buffers-rudely (regexp &optional internal-too)
  "Kill buffers whose name matches the specified REGEXP. This
function, unlike the built-in `kill-matching-buffers` does so
WITHOUT ASKING. The optional second argument indicates whether to
kill internal buffers too."
  (interactive "sKill buffers matching this regular expression: \nP")
  (dolist (buffer (buffer-list))
    (let ((name (buffer-name buffer)))
      (when (and name (not (string-equal name ""))
                 (or internal-too (/= (aref name 0) ?\s))
                 (string-match regexp name))
        (kill-buffer buffer)))))

(defun tail-log (remote-box-name lines-to-show)
  "Tails a catalina.out log in the background

It automatically will retry if the log doesn't exist. The first
argument is the name of the box: (\"qascauth\", \"qascpub\",
\"qascdata\", \"qaschedule\", \"qaschedulemaster\", \"qavideo\"
).  The second argument is the number of lines to show: this is
usually nil or \"-n +0\" to show the entire log. For example,

\(tail-log \"qascpub\" nil\)
\(tail-log \"qascpub\" \"-n +0\"\)

Returns the buffer in which the tail is occuring."
  (save-window-excursion
    (let ((tail-options " --retry --follow=name ")
          (filename " /opt/tomcat/logs/catalina.out"))
      (let ((ssh-tail-command
             (concat "ssh qa@" remote-box-name " tail " tail-options lines-to-show filename))
            (tail-log-buffer-name
             (concat "*tail-catalina-" remote-box-name "*")))
        (async-shell-command ssh-tail-command tail-log-buffer-name)
        (set-process-query-on-exit-flag (get-buffer-process tail-log-buffer-name) nil)
        (get-buffer tail-log-buffer-name)))))

(defun delete-all-pngs-on-desktop ()
  "Opens a dired to desktop, marks all pngs, and tries to delete
them, asking user for confirmation"
  (interactive)
  (save-window-excursion
    (dired "~/Desktop")
    (revert-buffer)
    (dired-mark-files-regexp "png" nil)
    (dired-do-delete)))

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
  (reindent-then-newline-and-indent))

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

(defun cleanup-buffer-safe ()
  "Perform a bunch of safe operations on the whitespace content of a buffer.
Does not indent buffer, because it is used for a before-save-hook, and that
might be bad."
  (interactive)
  (untabify (point-min) (point-max))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'utf-8))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (cleanup-buffer-safe)
  (indent-region (point-min) (point-max)))

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

(defun execute-feature (&optional arg)
  (interactive "p")
  (let ((filename (buffer-file-name (current-buffer)))
        (command "w /opt/honeydew/bin/honeydew.pl -isMine")
        (compile-command))
    (setq command (concat command " -feature=" filename))
    (if (eq arg 64)
        (setq command (concat command " -database ")))
    (if (eq arg 16)
        (setq command (concat "d" command)))
    (if (>= arg 4)
        (let ((browser (ido-completing-read "browser: "
                                            '("phantomjs localhost"
                                              "chrome"
                                              "firefox"
                                              "ie 10"
                                              "ie 9"
                                              "ie 8")))
              (hostname (ido-completing-read "hostname: "
                                             '("localhost"
                                               "www.qa.sharecare.com"
                                               "www.stage.sharecare.com"
                                               "www.sharecare.com"
                                               "www.qa.startle.com"
                                               "www.stage.startle.com"
                                               "www.startle.com"
                                               "www.qa.doctoroz.com"
                                               "www.stage.doctoroz.com"
                                               "www.doctoroz.com")))
              (sauce (ido-completing-read "sauce: " '("nil" "t"))))
          (setq command (concat command
                                (if (string= sauce "t") " -sauce")
                                " -browser='" browser " webdriver'"
                                " -hostname='http://" hostname "'"))))
    (setq compile-command (concat "perl -" command))
    (compile compile-command t)))

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

(defun reset-ssh-connections ()
  (interactive)
  (let ((tramp-buffers
         (-filter (lambda (item)
                    (string-match "tramp" (buffer-name item)))
                  (buffer-list))))
    (while tramp-buffers
      (kill-buffer (car tramp-buffers))
      (setq tramp-buffers (cdr tramp-buffers))))
  (delete-hung-ssh-sessions))

(defun delete-hung-ssh-sessions ()
  (interactive)
  (let ((cm-socket-files (directory-files "~/.ssh/cm_socket" nil nil t)))
    (while cm-socket-files
      (let ((filename (car cm-socket-files)))
        (if (not (or (string= "." filename)
                     (string= ".." filename)))
            (delete-file (concat "~/.ssh/cm_socket/" filename)))
        (setq cm-socket-files (cdr cm-socket-files))))))

(defun get-file-as-string (filePath)
  "Return FILEPATH's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string
     (buffer-string) "\n" t)))

(defun get-remote-names ()
  (interactive)
  (let ((ssh-config (get-file-as-string ssh-config-path) )
        (ssh-host-names))
    (while ssh-config
      (let ((line (car ssh-config)))
        (if (and (string-match-p "Host " line)
                 (not (string-match-p "*" line))
                 (not (string-match-p "^# " line)))
            (setq ssh-host-names (cons (cadr (split-string line " "))
                                       ssh-host-names))))
      (setq ssh-config (cdr ssh-config)))
    ssh-host-names))

(defun get-user-for-remote-box ()
  (interactive)
  (let ((ssh-config (get-file-as-string ssh-config-path) )
        (ssh-remote-info)
        (ssh-user-remote-pairs))
    (while ssh-config
      (let ((host-line (car ssh-config))
            (user-line (caddr ssh-config)))
        (if (and (string-match-p "Host " host-line)
                 (not (string-match-p "*" host-line))
                 (not (string-match-p "*" user-line))
                 (not (string-match-p "^# " host-line))
                 (not (string-match-p "^# " user-line)))
            (add-to-list 'ssh-user-remote-pairs
                         `(,(car (last (split-string host-line " ")))
                           ,(car (last (split-string user-line " "))))))
        (setq ssh-config (cdr ssh-config))))
    ssh-user-remote-pairs))

(defun open-ssh-connection (&optional pfx)
  (interactive)
  (let ((remote-info (get-user-for-remote-box))
        (buffer)
        (box))
    (if (eq nil pfx)
        (setq box (ido-completing-read "Which box: " (mapcar 'car remote-info)))
      (setq box pfx))
    (setq buffer (concat "*ssh-" box "*"))
    (let ((default-directory (concat "/" box ":/home/" (cadr (assoc box remote-info)) "/")))
      (shell buffer))
    (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))

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
     (if (> (length markdown-css-path) 0)
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

;; http://emacs-fu.blogspot.com/2013/03/editing-with-root-privileges-once-more.html
(defun find-file-as-root ()
  "Like `ido-find-file, but automatically edit the file with
root-privileges (using tramp/sudo), if the file is not writable
by user."
  (interactive)
  (let ((file (ido-read-file-name "Edit as root: ")))
    (unless (file-writable-p file)
      (setq file (concat "/sudo:root@localhost:" file)))
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

(defun execute-perl (&optional arg)
  (interactive "p")
  (let ((command (concat "w " (buffer-file-name (current-buffer))))
        (compile-command))
    (if (string-match-p "default.pm" (buffer-name (current-buffer)))
        (setq compile-command "perl /opt/honeydew/bin/makePod.pl")
      (when (eq arg 16)
        ;; debug on C-u C-u
        (setq command (concat "d" command)))
      (when (eq arg 4)
        ;; ask questions on C-u
        (setq command (read-from-minibuffer "Edit command: perl -" command )))
      (setq compile-command (concat "perl -" command)))
    (compile compile-command t)
    (if (eq arg 16)
        (progn
          (pop-to-buffer "*compilation*")
          (goto-char (point-max))
          (insert "c")))))

(defun offlineimap-rudely-restart ()
  (interactive)
  (shell-command "pkill -u dgempesaw -s 9 -f offlineimap")
  (offlineimap-quit)
  (offlineimap))

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

(defun php-send-buffer ()
  (interactive)
  (with-current-buffer "*PHP*"
    (erase-buffer))
  (php-send-region (point-min) (point-max)))

(defun php-send-line ()
  (interactive)
  (with-current-buffer "*PHP*" (erase-buffer))
  (php-send-region (point-at-bol) (point-at-eol)))

(defun php-send-region (start end)
  "Send the region between `start' and `end' to PHP for execution.
The output will appear in the buffer *PHP*."
  (interactive "r")
  (let ((php-buffer (get-buffer-create "*PHP*"))
        (code (buffer-substring-no-properties start end)))
    ;; Calling 'php -r' will fail if we send it code that starts with
    ;; '<?php', which is likely.  So we run the code through this
    ;; function to check for that prefix and remove it.
    (cl-flet ((clean-php-code (code)
                              (setq php-most-recent-compilation-code
                                    (if (string-prefix-p "<?php" code t)
                                        (substring code 5)
                                      code))))
      (display-buffer php-buffer)
      (call-process "php" nil php-buffer nil "-r" (clean-php-code code))
      (with-current-buffer php-buffer
        (insert (current-time-string))))))

(defun php-recompile-php-buffer ()
  (interactive)
  (let ((php-buffer "*PHP*"))
    (with-current-buffer php-buffer
      (erase-buffer)
      (call-process "php" nil php-buffer nil "-r" php-most-recent-compilation-code)
      (insert (current-time-string)))))

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

(defun jabber-alert-message-say (from buffer text proposed-alert)
  (interactive)
  (unless (eq (window-buffer (selected-window)) buffer)
    (let ((voice (if (eq 1 (random 2)) "Victoria" "Vicki"))
          (text (car (s-split "\n" text)))
          (from (car (s-split "@" (s-chop-prefix "qa@conference.sharecare.com/" from)))))
      (setq from (cond ((string= from "ebarrsmith") "Erin")
                       ((string= from "cmitchell") "Carl")
                       ((string= from "olebedev") "Olivia")
                       ((string= from "cthompson") "Carmen")
                       ((string= from "jhall") "Janet")
                       ((string= from "jcox") "Jeff")
                       ((string= from "vsatam") "Vikrant")
                       (t from)))
      (start-process "jabber-hello" " *jabber-say-buffer*" "say" "-v" voice " \"" from " says, '" text "'\""))))

(defun mu4e-toggle-html2text-width ()
  (interactive)
  (message
   (setq mu4e-html2text-command
         (concat "html2text -nobs -width "
                 (if (string-match "1000" mu4e-html2text-command)
                     "72"
                   "1000")
                 " -utf8 | sed 's/&quot;/\"/g'"))))

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


(defun delete-other-window (&optional kill-window-buffer-too)
  "Display an overlay in each window showing a unique key, then
ask user which window to delete.

If `kill-window-buffer-too` is non-nil, also delete the buffer in
the window."
  (interactive)
  (if (> (length (window-list)) 1)
      (progn
        (let ((index (prompt-for-selected-window "Delete window: "))
              (delete-window-function (if kill-window-buffer-too
                                          'delete-window-and-kill-buffer
                                        'delete-window)))
          (apply-to-window-index delete-window-function index "")))))

(defun delete-window-and-kill-buffer (&optional window)
  "Delete WINDOW and kill it's associated buffer.
WINDOW defaults to the currently selected window.
Return nil."
  (interactive)
  (let ((window (window-normalize-window window)))
    (kill-buffer (window-buffer window))
    (delete-window window))
  nil)

(provide 'dg-defun)