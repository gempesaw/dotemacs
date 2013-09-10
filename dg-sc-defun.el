(defun sc-hdew-prove-all ()
  "runs all the tests in the honeydew folder"
  (interactive)
  (let ((buf "*sc-hdew-prove-all*"))
    (start-process "generate-hdew-js-rules" nil "perl" "/opt/honeydew/bin/parseRules.pl")
    (if (string= buf (buffer-name (current-buffer)))
        (async-shell-command
         "prove -I /opt/honeydew/lib/ -j9 --state=failed  --trap --merge" buf)
      (async-shell-command
       "prove -I /opt/honeydew/lib/ -j9 --trap --merge --state=save,slow /opt/honeydew/t/ --rules='seq=0{5,6}-*' --rules='par=**'" buf))))


(defun sc-copy-build-numbers ()
  (interactive)
  (re-search-forward "auth")
  (beginning-of-line)
  (copy-region-as-kill (point) (save-excursion
                                 (forward-line 7)
                                 (point))))

(defun sc-open-catalina-logs ()
  (interactive)
  (unless (get-buffer-process "*tail-catalina-qascauth*")
    (let ((qa-boxes '("qaschedmaster"
                      "qascauth"
                      "qawebarmy"
                      "qascpub"
                      "qascdata")))
      (dolist (remote-box-alias qa-boxes)
        (tail-log remote-box-alias nil))
      (set-process-filter (get-buffer-process "*tail-catalina-qascauth*") 'sc-auto-restart-pub-after-auth)
      (set-process-filter (get-buffer-process "*tail-catalina-qascpub*") 'sc-deploy-assets-after-pub)
      (sc-switch-to-log-windows))))

(defun sc-switch-to-log-windows ()
  (window-configuration-to-register ?p)
  (switch-to-buffer "*scratch*" nil 'force-same-window)
  (delete-other-windows)
  (interactive)
  (switch-to-buffer "*tail-catalina-qascauth*" nil 'force-same-window)
  (split-window-right)
  (split-window-below)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qawebarmy*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*mu4e-view*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qascdata*" nil 'force-same-window)
  (split-window-below)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qascpub*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qaschedmaster*" nil 'force-same-window)
  (balance-windows)
  (other-window 2)
  (window-configuration-to-register ?q))


(defun sc-start-qa-file-copy ()
  (interactive)
  (save-window-excursion
    (message "okay, pub restarted, let's push some assets!")
    (async-shell-command "ssh qa@qascpub . pushStaticAndAssets.sh" "*sc-qa-file-copy*")))

(defun sc-close-qa-catalina ()
  (interactive)
  (kill-matching-buffers-rudely "*tail-catalina-")
  (kill-matching-buffers-rudely "*sc-errors*")
  (kill-matching-buffers-rudely "*sc-restarted*"))


(defun sc-open-qa-mongo-db()
  (interactive)
  (async-shell-command (concat "mongo " ip-and-port-of-qa-mongo) "*qa-mongo*"))

(defun sc-open-dev-mongo-db ()
  (interactive)
  (async-shell-command (concat "mongo " ip-and-port-of-dev-mongo) "*dev-mongo*"))

(defun sc-open-existing-hnew-shell ()
  (interactive)
  (let ((buffer "*ssh-hnew*"))
    (if (or (eq nil (get-buffer-process buffer))
            (eq nil (get-buffer buffer)))
        (save-window-excursion
          (open-ssh-connection "hnew")
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))
    (switch-to-buffer buffer)))

(defun sc--update-build ()
  (search-forward "#")
  ;; (delete-char -1)
  (let ((currentLineText (buffer-substring (line-beginning-position) (point)))
        (newVersion (buffer-substring (point) (line-end-position)))
        (product '(("auth" . "webauth&newtag=builds/sharecare/rc/")
                   ("pub" . "webpub&newtag=builds/sharecare/rc/")
                   ("webarmy" . "webarmy&newtag=builds/sharecare/rc/")
                   ("Data" . "data&newtag=builds/data/rc/")
                   ("Tasks" . "schedulemaster&newtag=builds/schedulemaster/rc/")))
        (update-build-url))
    ;; (delete-region (line-beginning-position) (line-end-position))
    (loop for cell in product do
          (when (string-match "UNCHANGED" newVersion)
            (setq sc-restart-type "half"))
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
                  (sc--box-in-restart-group-p name sc-restart-type)))))
     parsed-xml)))

(defun sc--box-in-restart-group-p (name restart-type)
  (let ((groupings '(("all" . ("scqawebpub2f"
                               "scqawebarmy2f"
                               "scqadata2f"
                               "scqaschedulemaster2f"
                               "scqawebauth2f"))
                     ("half" . ("scqawebpub2f"
                                "scqawebarmy2f"
                                "scqawebauth2f"
                                ))
                     ("pubs" . ("scqawebpub2f"
                                "scqawebarmy2f"))
                     ("pub" . ("scqawebpub2f"))
                     ("army" . ("scqawebarmy2f"))))
        (match nil))
    (member name (cdr (assoc restart-type groupings)))))

(defun sc-restart-pubs-only ()
  (interactive)
  (if (not (string-match "tail.*qa" (buffer-name (current-buffer))))
      (message "Try again from a tail-qa buffer! No accidents :)")
    (setq sc-restart-type "pubs")
    (sc-restart-qa-boxes t)))

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
  (pop-to-buffer "*-jabber-groupchat-qa@conference.sharecare.com-*")
  (goto-char (point-max))
  (insert (concat (format-time-string current-time-format (current-time)) " - Restarting QA"))
  (jabber-chat-buffer-send)
  (pop-to-buffer (get-buffer-create "*scratch*"))
  (goto-char (point-max))
  (yank)
  (re-search-backward "SC2")
  (setq sc-restart-type "all")
  (sc--update-build)
  (sc--update-build)
  (sc--update-build)
  sc-restart-type)


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
            (set-process-filter proc nil)))
      )))

(defun sc-deploy-assets-after-pub (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (process-mark proc))
      (insert string)
      (set-marker (process-mark proc) (point))
      (if (string-match-p "Initializing Log4J" string)
          (progn
            (message "pub server has restarted, deploying assets now!")
            (sc-start-qa-file-copy)
            (set-process-filter proc nil))))))

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
             (not (string= "*sc-hdew-prove-all*" (buffer-name (current-buffer)))))
        (message "Try again from a successful hdew prove buffer!")
      (async-shell-command "ssh hnew . pullAndDeployHoneydew" "*hdew-prod*"))))

(defun sc-open-jira-ticket-at-point ()
  (interactive)
  (let ((ticket (thing-at-point 'sexp)))
    (unless (string-match-p "^[A-z]+-[0-9]+$" ticket)
      (setq ticket (read-from-minibuffer "Not sure if this is a ticket: " ticket)))
    (browse-url (concat "http://arnoldmedia.jira.com/browse/" ticket))))

(defun sc-hdew-update-keywords ()
  (interactive)
  (let ((buf (get-buffer " *update keywords*"))
        (update "curl -k https://server-422.lab1a.openstack.internal/keywords/getKeywordsFile.php")
        (copy "scp honeydew@hnew:/opt/honeydew/features/keywords.txt /opt/HDEW/honeydew/features/keywords.txt"))
    (save-window-excursion
      (async-shell-command (concat update " && " copy) buf buf))))

(provide 'dg-sc-defun)
