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
  (jump-to-register 6245)
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
  (switch-to-buffer "*tail-catalina-qaschedmaster*" nil 'force-same-window)
  (other-window 1)
  (split-window-below)
  (switch-to-buffer "*tail-catalina-qascdata*" nil 'force-same-window)
  (other-window 1)
  (switch-to-buffer "*tail-catalina-qascpub*" nil 'force-same-window)
  (window-configuration-to-register ?q)
  (split-window-below)
  (other-window 1)
  (switch-to-buffer "*mu4e-view*" nil 'force-same-window)
  (balance-windows)
  (other-window -1))


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

(defcustom sc-resolved-qa-boxes ""
  "The result of xml-parse-region, filtered down to boxes with ACTIVE state")

(defun sc-resolve-qa-boxes ()
  (let* ((buf (url-retrieve-synchronously "https://admin.be.jamconsultg.com/kohana/adminui/showrunningsystems?site=sharecare"))
        (parsed-xml))
    (set-buffer buf)
    (goto-char 1)
    (replace-string "\n" "")
    (goto-char 1)
    (setq parsed-xml (cdddar (xml-parse-region
                              (re-search-forward "/xml")
                              (point-max) buf)))
    (kill-buffer buf)
    parsed-xml))

(defun sc-refresh-qa-box-information ()
  (interactive)
  (setq sc-qa-boxes-parsed-xml (sc-resolve-qa-boxes)))

(defun sc-filter-resolved-xml ()
  (if (eq nil sc-qa-boxes-parsed-xml)
      (sc-refresh-qa-box-information))
  (let ((xml sc-qa-boxes-parsed-xml))
    (-filter
     (lambda (item)
       (let ((state (caddr (nth 5 item)))
             (name (caddr (nth 3 item)))
             (case-fold-search nil))
         (and (string-match-p "ACTIVE" state)
              (string-match-p "qa" name)
              (sc--box-in-restart-group-p name sc-restart-type))))
     xml)))

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
                     ("data" . ("scqadata2f"))
                     ("pubs" . ("scqawebpub2f"
                                "scqawebarmy2f"))
                     ("pub" . ("scqawebpub2f"))
                     ("schedmaster" . ("scqaschedulemaster2f"))
                     ("army" . ("scqawebarmy2f"))))
        (match nil))
    (member name (cdr (assoc restart-type groupings)))))

(defun sc-restart-schedmaster ()
  (interactive)
    (setq sc-restart-type "schedmaster")
    (sc-restart-qa-boxes t))

(defun sc-restart-data ()
  (interactive)
    (setq sc-restart-type "data")
    (sc-restart-qa-boxes t))

(defun sc-restart-pubs-only ()
  (interactive)
    (setq sc-restart-type "pubs")
    (sc-restart-qa-boxes t))

(defun sc-restart-army ()
  (interactive)
    (setq sc-restart-type "army")
    (sc-restart-qa-boxes t))

(defun sc-restart-pub ()
  (interactive)
    (setq sc-restart-type "pub")
    (sc-restart-qa-boxes t))

(defun sc-restart-qa-boxes (&optional all)
  (interactive)
  (let ((restart-url-prefix "https://admin.be.jamconsultg.com/adminui/application/control?action=restart&appname=tomcat&site=sc&ids="))
    (-map (lambda (item)
            (let* ((id (cdaadr item))
                   (name (caddr (nth 3 item)))
                   (url (concat restart-url-prefix id)))
              (message (format "restarting %s at: %s" name url))
              (if (string-match "tail.*qa" (buffer-name (current-buffer)))
                  (url-retrieve url (lambda (status) (kill-buffer (current-buffer))))
                (message "Try again from a tail-qa buffer! No accidents :)"))))
          (-filter (lambda (item)
                     (let ((name (caddr (nth 3 item))))
                       (if (eq nil all)
                           (string-match "auth" name)
                         (not (string-match "auth" name)))))
                   (sc-filter-resolved-xml)))))



(defun sc-update-all-builds (&optional pfx)
  (interactive "p")
  (sc-copy-build-numbers)
  (when (eq pfx 1)
    (pop-to-buffer "*-jabber-groupchat-qa@conference.sharecare.com-*")
    (goto-char (point-max))
    (insert (concat (format-time-string current-time-format (current-time)) " - Restarting QA"))
    (jabber-chat-buffer-send))
  (pop-to-buffer (get-buffer-create "*scratch*"))
  (goto-char (point-max))
  (yank)
  (re-search-backward "SC2")
  (setq sc-restart-type "all")
  (sc--update-build)
  (sc--update-build)
  (sc--update-build)
  (message "We will be restarting: %s" sc-restart-type))

(defun sc-auto-restart-pub-after-auth (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (goto-char (process-mark proc))
      (insert string)
      (set-marker (process-mark proc) (point))
      (if (string-match-p "MAGNOLIA LICENSE" string)
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
      (if (string-match-p "MAGNOLIA LICENSE" string)
          (progn
            (message "pub server has restarted, deploying assets now!")
            (sc-start-qa-file-copy)
            (set-process-filter proc nil))))))

(defun sc-open-jira-ticket-at-point ()
  (interactive)
  (let ((ticket (thing-at-point 'sexp)))
    (unless (string-match-p "^[A-z]+-[0-9]+$" ticket)
      (setq ticket (read-from-minibuffer "Not sure if this is a ticket: " ticket)))
    (browse-url (concat "http://arnoldmedia.jira.com/browse/" ticket))))

(defun sc-find-server-startup ()
  (interactive)
  (goto-char (point-max))
  (search-backward "INFO: Server startup in " 0 t)
  (other-window 1))

;;; key settings

;; start hnew shell or switch to it if it's active
(global-set-key (kbd "C-c ,") 'sc-open-existing-hnew-shell)
(global-set-key (kbd "s-1") 'sc-update-all-builds)
(global-set-key (kbd "s-2") 'sc-open-catalina-logs)
(global-set-key (kbd "s-3") (lambda () (interactive)
                              (sc-restart-qa-boxes)
                              (other-window 1)))
(global-set-key (kbd "s-4") 'sc-close-qa-catalina)

(global-unset-key (kbd "s-s"))
(global-set-key (kbd "s-s") 'sc-find-server-startup)

(defun sc-bactes-scrum-meeting ()
  (interactive)
  (browse-url "http://fuze.me/21273875"))

(defun sc-qa-scrum-meeting ()
  (interactive)
  (browse-url "http://fuze.me/21449287"))

(defun sc-open-vpn-connection ()
  (interactive)
  (async-shell-command "perl ~/vpn.pl" "*vpn-script*"))

(defun sc-jabber-join-qa-conference ()
  (interactive)
  (window-configuration-to-register 999)
  (kmacro-call-macro nil nil nil 'sc-jabber-join-qa-conference-macro)
  (jump-to-register 999))

(defun tail-log-on-termdew ()
  (interactive)
  (with-temp-buffer
    (let ((file (read-from-minibuffer "File? ")))
      (cd "/ssh:termdew:/home/honeydew")
      (async-shell-command (format "tail -f %s" file) (concat "*tail-" file) (concat "*tail-" file) ))))

(fset 'sc-jabber-join-qa-conference-macro
      [?\C-x ?\C-j ?\C-r ?\C-s ?s ?h ?a ?r ?e ?c ?a ?r ?e ?\C-m ?\C-a ?j ?q ?a ?@ ?c ?o ?n ?f ?r ?e backspace backspace ?e ?r ?e ?n ?c ?e ?. ?s ?h ?a ?r ?e ?c ?a ?r ?e ?. ?c ?o ?m return ?d ?g ?e ?m ?p ?e ?s ?a ?w return ?\s-q])

(provide 'dg-sc)
