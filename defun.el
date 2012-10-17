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

;; This buffer is for notes you don't want to save, and for Lisp evaluation.
;; If you want to create a file, visit that file with C-x C-f,
;; then enter the text in that file's own buffer.

(defun run-feature-in-all-browsers ()
  "passes the current file to a perl script that runs it in all
browsers."
  (interactive)
  (async-shell-command
   (concat "perl -w /opt/honeydew/bin/multipleBrowsers.pl "
           (buffer-file-name))
   "run-feature-in-all-browsers")
  (set-buffer "run-feature-in-all-browsers")
  (dired-other-window "/Users/dgempesaw/tmp/sauce/")
  )

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


(defun open-qa-catalina-late ()
  (interactive)
  (make-frame-command)
  (switch-to-buffer "*scratch*" nil 'force-same-window)
  (tail-log "auth" " -n +0 ")
  (tail-log "pub" " -n +0 ")
  (tail-log "data" " -n +0 ")
  (check-build-timestamp-on-remote-box)
  (delete-other-windows)
  (split-window-horizontally)
  (split-window-vertically)
  (split-window-vertically)
  (balance-windows)
  (switch-to-buffer "qascauth" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "qascpub" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "qascdata" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "check-build-timestamp" nil 'force-same-window))

(defun open-qa-catalina-early ()
  (interactive)
  (make-frame-command)
  (switch-to-buffer "*scratch*" nil 'force-same-window)
  (tail-log "auth" nil)
  (tail-log "pub" nil)
  (tail-log "data" nil)
  (check-build-timestamp-on-remote-box)
  (delete-other-windows)
  (split-window-horizontally)
  (split-window-vertically)
  (split-window-vertically)
  (balance-windows)
  (switch-to-buffer "qascauth" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "qascpub" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "qascdata" nil 'force-same-window)
  (end-of-buffer)
  (other-window 1)
  (switch-to-buffer "check-build-timestamp" nil 'force-same-window)
  )

(defun check-build-timestamp-on-remote-box ()
  (interactive)
  (async-shell-command "ssh qa@qascpub ls -al /tmp/builds" "check-build-timestamp"))

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
  (kill-buffer "qascauth")
  (kill-buffer "qascpub")
  (kill-buffer "qascdata")
  (kill-buffer "check-build-timestamp")
  (kill-buffer "qa-file-copy"))

(defun tail-log (box-type lines-to-show)
  "Tails a catalina.out log in the background

It automatically will retry if the log doesn't exist. The first
argument is the type of box (auth, pub, or data). The second
argument is the number of lines to show: this is usually nil or
\"-n +0\" to show the entire log. For example,

\(tail-log \"pub\" nil\)
\(tail-log \"pub\" \"-n +0\"\)"
  (save-window-excursion
    (let ((tail-options " --retry --follow=name ")
          (filename " /opt/tomcat/logs/catalina.out"))
      (let ((ssh-tail-command
             (concat "ssh qa@qasc" box-type " tail " tail-options lines-to-show filename))
            (tail-log-buffer-name
             (concat "qasc" box-type)))
        (async-shell-command ssh-tail-command tail-log-buffer-name)
        (set-process-query-on-exit-flag (get-buffer-process tail-log-buffer-name) nil)
        ))))


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
