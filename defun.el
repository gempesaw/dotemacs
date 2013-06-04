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

(defun hdew-prove-all ()
  "runs all the tests in the honeydew folder"
  (interactive)
  (let ((buf "*hdew-prove-all*"))
    (if (string= buf (buffer-name (current-buffer)))
        (async-shell-command
         "prove -I /opt/honeydew/lib/ -j9 --state=failed" buf)
      (async-shell-command
       "prove -I /opt/honeydew/lib/ -j9 --state=save,slow /opt/honeydew/t/" buf))))


(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))

(defun reload-my-init ()
  (interactive)
  (load-file "/Users/dgempesaw/opt/dotemacs/init.el"))

(defun sc-copy-build-numbers ()
  (interactive)
  (re-search-forward "auth")
  (beginning-of-line)
  (copy-region-as-kill (point) (save-excursion
                                 (forward-line 7)
                                 (point))))

(defun sc-open-catalina-logs ()
  (interactive)
  (switch-to-buffer "*scratch*" nil 'force-same-window)
  (delete-other-windows)
  (let ((qa-boxes '("qaschedmaster" "qascauth" "qawebarmy" "qascpub" "qascdata" "qasched"))
        (buffer-prefix "tail-catalina-"))
    (dolist (remote-box-alias qa-boxes)
      (tail-log remote-box-alias nil)))
  (switch-to-buffer "*tail-catalina-qascauth*" nil 'force-same-window)
  (split-window-right)
  (split-window-below)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qawebarmy*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qasched*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qascdata*" nil 'force-same-window)
  (split-window-below)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qascpub*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qaschedmaster*" nil 'force-same-window)
  (set-process-filter (get-buffer-process "*tail-catalina-qascauth*") 'sc-auto-restart-pub-after-auth)
  (set-process-filter (get-buffer-process "*tail-catalina-qascpub*") 'sc-deploy-assets-after-pub)
  (balance-windows))

(defun sc-check-what-servers-have-restarted ()
  (interactive)
  (multi-occur-in-matching-buffers "tail-catalina" "INFO: Server startup in" 1)
  (set-buffer "*Occur*")
  (rename-buffer "*sc-restarted*")
  (multi-occur-in-matching-buffers "tail-catalina" "ERROR," 1)
  (set-buffer "*Occur*")
  (rename-buffer "*sc-errors*"))

(defun start-qa-file-copy ()
  (interactive)
  (save-window-excursion
    (message "okay, pub restarted, let's push some assets!")
    (async-shell-command "ssh qa@qascpub . pushStaticAndAssets.sh" "build-file-copy")))

(defun replace-last-sexp ()
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%s" value))))

(defun sc-close-qa-catalina ()
  (interactive)
  (kill-matching-buffers-rudely "*tail-catalina-")
  (kill-matching-buffers-rudely "*sc-errors*")
  (kill-matching-buffers-rudely "*sc-restarted*")
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
    (if (or (eq nil (get-buffer-process buffer))
            (eq nil (get-buffer buffer)))
        (save-window-excursion
          (async-shell-command "ssh hnew" buffer)
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))
    (switch-to-buffer buffer)))

(defun my-w3m-rename-buffer (url)
  "Renames the current buffer to be the current URL"
  (rename-buffer url t))

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
                   ("webarmy" . "webarmy&newtag=builds/sharecare/rc/")
                   ("Data" . "data&newtag=builds/data/rc/")
                   ("Tasks" . "schedulemaster&newtag=builds/schedulemaster/rc/")
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
    (insert (message (concat
                      (cadr (split-string build-number "/"))
                      " updated to "
                      (car (last (split-string build-number "/"))))))))

(defun sc-resolve-qa-boxes ()
  (interactive)
  (let ((buf (url-retrieve-synchronously "https://admin.be.jamconsultg.com/kohana/adminui/showrunningsystems?site=sharecare"))
        (note)
        (name)
        (boxes))
    (set-buffer buf)
    (goto-char 1)
    (replace-string "\n" "")
    (goto-char 1)
    (setq parsed-xml (cdddar (xml-parse-region
                              (re-search-forward "/xml")
                              (point-max) buf)))
    (kill-buffer buf)
    (-filter
     (lambda (item)
       (if (setq note (caddar (last item)))
           (progn
             (setq name (caddr (nth 3 item)))
             (and (not (string-match "Disable" note))
                  (or (string= name "scqawebpub2f")
                      (string= name "scqawebarmy2f")
                      (string= name "scqadata2f")
                      (string= name "scqaschedule2f")
                      (string= name "scqaschedulemaster2f")
                      (string= name "scqawebauth2f"))))))
     parsed-xml)))

(defun sc-restart-qa-boxes (&optional all)
  (interactive)
  (if (not (string-match "tail.*qa" (buffer-name (current-buffer))))
      (message "Try again from a tail-qa buffer! No accidents :)")
    (let ((restart-url-prefix "https://admin.be.jamconsultg.com/kohana/adminui/changeappstate?site=sharecare&appname=tomcat&systems="))
      (-each
       (-filter
        (lambda (item)
          (if (eq nil all)
              (string-match "auth" (car item))
            (not (string-match "auth" (car item)))))
        (-map
         (lambda (item)
           (let ((id-string (split-string (cdaadr item) "\\^")))
             (cons (caddr (nth 3 item))
                   (concat restart-url-prefix
                           (car id-string)
                           "^"
                           (cadr id-string)
                           ",&action=Restart"))))
         (sc-resolve-qa-boxes)))
       (lambda (item)
         (message (concat "restarting " (car item)))
         ;; (message (cdr item))
         (url-retrieve (cdr item) (lambda (status) (kill-buffer (current-buffer)))))))))

(defun sc-update-all-builds ()
  (interactive)
  (sc-copy-build-numbers)
  (make-frame-command)
  (switch-to-buffer "*-jabber-groupchat-qa@conference.sharecare.com-*")
  (goto-char (point-max))
  (insert "Restarting QA")
  (jabber-chat-buffer-send)
  (pop-to-buffer (get-buffer-create "*scratch*"))
  (goto-char (point-max))
  (yank)
  (re-search-backward "SC2")
  (sc--update-build)
  (sc--update-build)
  (sc--update-build)
  (sc--update-build))

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
  ;; µ is 265
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
                                            '("chrome"
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
  (with-help-window (help-buffer)
    (prin1 fun-or-var)
    ;; Use " is " instead of a colon so that
    ;; it is easier to get out the function name using forward-sexp.
    (princ " is ")
    (describe-function-1 fun-or-var)
    (with-current-buffer standard-output
      ;; Return the text we displayed.
      (buffer-string))) fun-or-var)

(defun sc-auto-restart-pub-after-auth (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (process-mark proc))
      (insert string)
      (set-marker (process-mark proc) (point))
      (if (string-match-p "Initializing Log4J" string)
          (progn
            (message "auth server has started, restarting pub now!")
            (sc-restart-qa-boxes t)
            (set-process-filter proc nil))))))

(defun sc-deploy-assets-after-pub (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (process-mark proc))
      (insert string)
      (set-marker (process-mark proc) (point))
      (if (string-match-p "Initializing Log4J" string)
          (progn
            (message "pub server has restarted, deploying assets now!")
            (start-qa-file-copy)
            (set-process-filter proc nil))))))

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

(require 'tramp)
(defun open-ssh-connection (&optional pfx)
  (interactive "p")
  (let ((remote-info (get-user-for-remote-box))
        (buffer)
        (box))
    (setq box (ido-completing-read "Which box: " (mapcar 'car remote-info)))
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

(defun sc-kabocha-test ()
  (interactive)
  (async-shell-command "sh /opt/kabocha/run-tests" "*kabocha-run-tests*"))

(defun sc-kabocha-self-test ()
  (interactive)
  (async-shell-command "cd /opt/kabocha;prove" "*kabocha-run-tests*"))

(defun sc-kabocha-test-sso ()
  (interactive)
  (async-shell-command "sh /opt/kabocha/run-sso-tests" "*kabocha-run-tests*"))

(defun sc-hdew-push-to-prod ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (and (not (eq nil (search-forward "Result: PASS" nil t)))
             (not (string= "*hdew-prove-all*" (buffer-name (current-buffer)))))
        (message "Try again from a successful hdew prove buffer!")
      (async-shell-command "ssh hnew . pullAndDeployHoneydew" "*hdew-prod*"))))

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
    (if (eq arg 16)
        ;; debug on C-u C-u
        (setq command (concat "d" command)))
    (if (eq arg 4)
        ;; ask questions on C-u
        (setq command (read-from-minibuffer "Edit command: perl -" command )))
    (setq compile-command (concat "perl -" command))
    (compile compile-command t)
    (if (eq arg 16)
        (progn
          (pop-to-buffer "*compilation*")
          (goto-char (point-max))
          (insert "c")))))

(defun offlineimap-rudely-restart ()
  (interactive)
  (let ((pid (car (get-file-as-string "~/.offlineimap/pid"))))
    (while (string-match "offline" (cadr (split-string (shell-command-to-string (concat "ps " pid)) "\n")))
      (shell-command (concat "kill -9 " pid))))
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

(defun sc-start-selenium-server ()
  (interactive)
  (let ((selenium-proc-name "selenium-webdriver")
        (selenium-version "2.32.0")
        (selenium-buffer nil)
        (selenium-file))
    (setq selenium-buffer (concat "*" selenium-proc-name "-" selenium-version "*"))
    (setq selenium-file (concat "/opt/selenium-server-standalone-" selenium-version ".jar"))
    (save-window-excursion
      (when (and (eq nil (get-buffer selenium-buffer)) (file-exists-p selenium-file))
        (set-process-query-on-exit-flag
         (start-process selenium-proc-name selenium-buffer
                        "java" "-jar" selenium-file "-Dwebdriver.chrome.driver=/opt/chromedriver")
         nil)
        (switch-to-buffer selenium-buffer)
        (setq buffer-read-only t)))))

(defun sc-open-jira-ticket-at-point ()
  (interactive)
  (let ((ticket (thing-at-point 'sexp)))
    (unless (string-match-p "^[A-z]+-[0-9]+$" ticket)
      (setq ticket (read-from-minibuffer "Not sure if this is a ticket: " ticket)))
    (browse-url (concat "http://arnoldmedia.jira.com/browse/" ticket))))

(defun php-send-buffer ()
  (interactive)
  (with-current-buffer "*PHP*"
    (erase-buffer))
  (php-send-region (point-min) (point-max)))

(defun php-send-line ()
  (interactive)
  (with-current-buffer "*PHP*" (erase-buffer))
  (php-send-region (point-at-bol) (point-at-eol)))
