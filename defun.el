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

(defun sc-check-what-servers-have-restarted ()
  (interactive)
  (multi-occur-in-matching-buffers "tail-catalina" "INFO: Server startup in" 1)
  (set-buffer "*Occur*")
  (rename-buffer "*sc-restarted*")
  (multi-occur-in-matching-buffers "tail-catalina" "ERROR," 1)
  (set-buffer "*Occur*")
  (rename-buffer "*sc-errors*"))

(defun sc-search-catalina-logs-for-errors ()
  (interactive)
  )

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
  (kill-matching-buffers-rudely "*tail-catalina-"))

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

(defun open-qa-mongo-db()
  (interactive)
  (async-shell-command (concat "mongo " ip-and-port-of-qa-mongo) "*qa-mongo*"))

(defun open-dev-mongo-db ()
  (interactive)
  (async-shell-command (concat "mongo " ip-and-port-of-dev-mongo) "*dev-mongo*"))

(defun open-existing-hnew-shell ()
  (interactive)
  (let ((buffer "*ssh-hnew*"))
    (if (eq nil (get-buffer buffer))
        (save-window-excursion
          (async-shell-command "ssh hnew" buffer)
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil))
      (switch-to-buffer buffer))))

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

(defun sc--update-build ()
  (search-forward "#")
  ;; (delete-char -1)
  (let ((currentLineText (buffer-substring (line-beginning-position) (point)))
        (newVersion (buffer-substring (point) (line-end-position)))
        (product '(("auth" . "webauth&newtag=builds/sharecare/rc/")
                   ("pub" . "webpub&newtag=builds/sharecare/rc/")
                   ("Data" . "data&newtag=builds/data/rc/")
                   ("ETL" . "schedulemaster&newtag=builds/schedulemaster/rc/")
                   ("Sync" . "schedule&newtag=builds/schedule/rc/")))
        (update-build-url))
    ;; (delete-region (line-beginning-position) (line-end-position))
    (loop for cell in product do
          (let ((vikAbbrev (car cell))
                (productAndNewTag (cdr cell)))
            (if (and (string-match vikAbbrev currentLineText)
                     (not (string-match "UNCHANGED" newVersion)))
                (progn
                  (setq update-build-url
                        (concat
                         "https://admin.be.jamconsultg.com/kohana/adminui/updatebuildtag?site=sharecare&product="
                         productAndNewTag newVersion "&buildtype=qa"))
                  (url-retrieve update-build-url 'sc-check-current-build)))))))


(defun sc-check-current-build (&optional rest)
  (let ((json-object-type 'alist)
        (build-number))
    (save-excursion
      (setq build-number
            (aref (cdr (assoc 'data (car (-filter
                                          (lambda (item)
                                            (cdr (assoc 'selected item)))
                                          (append
                                           (cdar (json-read-from-string
                                                  (extract-json-from-http-response
                                                   (current-buffer)))) nil) )))) 0)))
    (kill-buffer (current-buffer))
    (set-buffer "*scratch*")
    (end-of-line)
    (newline)
    (insert (cadr (split-string build-number "/")) " updated to " (car (last (split-string build-number "/"))))))

(defun sc-restart-all-5-boxes ()
  (interactive)
  (let ((buf (url-retrieve-synchronously "https://admin.be.jamconsultg.com/kohana/adminui/showrunningsystems?site=sharecare"))
        (restart-url-prefix "https://admin.be.jamconsultg.com/kohana/adminui/changeappstate?site=sharecare&appname=tomcat&systems=")
        (qa-boxes nil))
    (set-buffer buf)
    (goto-char (point-min))
    (setq qa-boxes
          (-filter (lambda (item) (or (string= (caddr (nth 5 item)) "scqawebauth2f")
                                      ;; (string= (caddr (nth 5 item)) "scqawebpub2f")
                                      (string= (caddr (nth 5 item)) "scqadata2f")
                                      (string= (caddr (nth 5 item)) "scqaschedule2f")
                                      (string= (caddr (nth 5 item)) "scqaschedulemaster2f")))
                   (cdr (-remove (lambda (item) (stringp item))
                                 (car (xml-parse-region
                                       (+ 1 (re-search-forward "^$"))
                                       (point-max) buf))))))
    (-each (-map (lambda (item)
                   (let ((id-string (split-string (cdaadr item) "\\^")))
                     (cons (caddr (nth 5 item))
                           (concat restart-url-prefix
                                   (car id-string)
                                   "^"
                                   (cadr id-string)
                                   ",&action=Restart"))))
                 qa-boxes)
           (lambda (item)
             (url-retrieve (cdr item) (lambda (status)))))))


(defun sc-update-all-builds ()
  (interactive)
  (sc--update-build)
  (sc--update-build)
  (sc--update-build)
  (sc--update-build))

(defun tex-without-changing-windows ()
  (interactive)
  (save-buffer)
  (save-window-excursion
    (tex-file)))


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
  (jump-to-register :magit-fullscreen))

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
