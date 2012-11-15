(defun google ()
  "Googles a query or region if any."
  (interactive)
  (w3m-browse-url
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

(define-key global-map [remap term] 'cterm)

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

(defun hdew-prove-all ()
  "runs all the tests in the honeydew folder"
  (interactive)
  (async-shell-command
   "prove -I /opt/honeydew/lib/ -j9 --state=save,slow /opt/honeydew/t/" "*hdew-prove-all*"))


(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))

(defun reload-my-init ()
  (interactive)
  (load-file "/Users/dgempesaw/opt/dotemacs/init.el"))

(defun open-catalina-logs ()
  (interactive)
  (make-frame-command)
  (switch-to-buffer "*scratch*" nil 'force-same-window)
  (delete-other-windows)
  (let ((qa-boxes '("qascauth" "qascpub" "qascdata" "qasched" "qaschedmaster"))
        (buffer-prefix "tail-catalina-"))
    (dolist (remote-box-alias qa-boxes)
      (tail-log remote-box-alias nil)
      (if (string-match-p buffer-prefix (buffer-name (current-buffer)))
          (progn
            (balance-windows)
            (split-window-vertically)))
      (switch-to-buffer (concat "*" buffer-prefix remote-box-alias "*")
                        nil 'force-same-window)
      (goto-char (point-max))
      (other-window 1)))
  (balance-windows))

  (interactive)
  (multi-occur-in-matching-buffers "tail-catalina" "ERROR," 1))

(defun start-qa-file-copy ()
  (interactive)
  (async-shell-command "ssh qa@qascpub . pushStaticAndAssets.sh" "qa-file-copy"))

(defun replace-last-sexp ()
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%s" value))))

(defun close-qa-catalina ()
  (interactive)
  (kill-matching-buffers-rudely "*tail-catalina-")
  (delete-frame))

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
  (reindent-then-newline-and-indent))

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

(defun open-qa-mongo-db()
  (interactive)
  (async-shell-command (concat "mongo " ip-and-port-of-qa-mongo) "*qa-mongo*"))

(defun my-w3m-rename-buffer (url)
  "Renames the current buffer to be the current URL"
  (rename-buffer url t))

(defun open-existing-ssh-shell (remote-box)
  (interactive "sWhat box: ")
  (let ((buffer (concat "*ssh-" remote-box "*")))
    (if (eq nil (get-buffer buffer))
        (save-window-excursion
          (async-shell-command (concat "ssh " remote-box)
                               (generate-new-buffer-name buffer))
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))
    (switch-to-buffer buffer)))

(defun tail-entire-log (remote-box)
  (interactive "sBox to tail: ")
  (switch-to-buffer (tail-log remote-box "-n +0")))
