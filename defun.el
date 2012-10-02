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
   "prove -I /opt/honeydew/lib/ -j9 --state=save,slow /opt/honeydew/t/"))


(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))

(defun reload-my-init ()
  (interactive)
  (load-file "/Users/dgempesaw/opt/dotemacs/init.el"))


(defun open-qa-catalina ()
  (interactive)
  (make-frame-command)
  (delete-other-windows)
  (split-window-horizontally)
  (split-window-vertically)
  (split-window-vertically)
  (balance-windows)
  (find-file "/ssh:qascauth:/opt/tomcat/logs/catalina.out" t)
  (end-of-buffer)
  (other-window 1)
  (find-file "/ssh:qascpub:/opt/tomcat/logs/catalina.out" t)
  (end-of-buffer)
  (other-window 1)
  (find-file "/ssh:qascdata:/opt/tomcat/logs/catalina.out" t)
  (end-of-buffer)
  (other-window 1)
  (check-build-timestamp-on-remote-box)
  )

(defun check-build-timestamp-on-remote-box ()
  (interactive)
  (async-shell-command "ssh qa@qascpub . lsw.sh" "qa-file-copy"))

(defun start-qa-file-copy ()
  (interactive)
  (async-shell-command "ssh qa@qascpub . pushStaticAndAssets.sh" "qa-file-copy"))


