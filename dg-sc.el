(defun sc-open-catalina-logs ()
  (interactive)
  (unless (get-buffer-process "*tail-catalina-qascauth*")
    (let ((qa-boxes '("qaschedmaster"
                      "qascauth"
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
    (async-shell-command "ssh build@qascpub sh ./pushStaticAndAssets.sh" "*sc-qa-file-copy*")))

(defun sc-close-qa-catalina ()
  (interactive)
  (kill-matching-buffers-rudely "*tail-catalina-")
  (kill-matching-buffers-rudely "*sc-errors*")
  (kill-matching-buffers-rudely "*sc-restarted*")
  (jump-to-register ?p))

(defun sc-open-existing-hnew-shell ()
  (interactive)
  (let ((buffer "*ssh-hnew*"))
    (if (or (eq nil (get-buffer-process buffer))
            (eq nil (get-buffer buffer)))
        (save-window-excursion
          (open-ssh-connection "hnew")
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))
    (switch-to-buffer buffer)))

(defun sc-check-current-build (buf)
  (switch-to-buffer (current-buffer)))

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
  (if (not (boundp 'sc-dw-boxes))
      (sc-refresh-qa-box-information))
  (let ((xml sc-dw-boxes))
    (-filter
     (lambda (item)
       (let ((state (caddr (nth 5 item)))
             (name (caddr (nth 3 item)))
             (case-fold-search nil))
         (sc--box-in-restart-group-p name sc-restart-type)))
     xml)))

(setq sc-dw-boxes
      (-filter
       (lambda (item)
         (and (string-match-p "ACTIVE" (caddr (nth 5 item)))
            (string-match-p "scdw" (caddr (nth 3 item)))))
       sc-qa-boxes-parsed-xml))

(defun sc--box-in-restart-group-p (name restart-type)
  (let ((groupings '(("all" . ("scdwwebpub2f"
                               "scdwdata2f"
                               "scdwschedulemaster2f"
                               "scdwwebauth2f"))
                     ("half" . ("scdwwebpub2f"
                                "scdwwebauth2f"
                                ))
                     ("data" . ("scdwdata2f"))
                     ("pubs" . ("scdwwebpub2f"))
                     ("pub" . ("scdwwebpub2f"))
                     ("schedmaster" . ("scdwschedulemaster2f"))
                     ("army" . ("scdwwebarmy2f"))))
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
  (let ((restart-base "https://admin.be.jamconsultg.com/adminui/builds/update?site=sc&env=dw&product=%s&bucket=dw-%s-build&build=builds/sharecare/rc/%s")
        (boxes '("webauth" "webpub" "data" "schedulemaster")) )
    (save-excursion
      (search-forward "Build #")
      (setq sc-deploy-number (buffer-substring (point) (point-at-eol))
            sc-restart-type "all"
            sc-deploy-count 0
            sc-deploy-environment "DW"
            sc-deploy-time (s-chop-prefix "0" (format-time-string "%I:%M%p"))))
    (mapcar (lambda (it) (url-retrieve (format restart-base it it sc-deploy-number) 'sc-check-current-build)) boxes)
    (message "We will be restarting: %s" sc-restart-type))
  ;; (when (eq pfx 1)
  ;;   (pop-to-buffer "*-jabber-groupchat-qa@conference.sharecare.com-*")
  ;;   (goto-char (point-max))
  ;;   (insert (concat (format-time-string current-time-format (current-time)) " - Restarting QA"))
  ;;   (jabber-chat-buffer-send))
  )

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
    (string-match "\\([A-Z]+-[0-9]+$\\)" ticket)
    (browse-url
     (concat "http://arnoldmedia.jira.com/browse/"
             (match-string 0 ticket)))))

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
(global-set-key (kbd "s-5") 'sc-check-qa-build)
(global-unset-key (kbd "s-z"))
(global-set-key (kbd "s-z") 'sc-army-login)
(global-unset-key (kbd "s-s"))
(global-set-key (kbd "s-s") 'sc-find-server-startup)

(defun sc-army-login ()
  (interactive)
  (let ((env (ido-completing-read "Env:" '("https://armyfit.dev.sharecare.com"
                                           "https://ultimateme.dev.sharecare.com"
                                           "https://ultimateme.stage.sharecare.com"
                                           "https://armyfit.stage.sharecare.com"
                                           "https://test.armyfit.army.mil"
                                           "https://armyfit.army.mil"
                                           "https://ultimateme.army.mil"
                                           )))
        (user (ido-completing-read "User:" '("jesse.watters"
                                             "erin.graziano"
                                             "allison.pepper"
                                             "amy.emerson"
                                             "test.maigret"
                                             "jennifer.walsh"))))
    (save-window-excursion
      (async-shell-command
       (format "perl -w /Users/dgempesaw/tmp/login.pl '%s' '%s'" env user) " hide" " hide"))))

(defun sc-qa-scrum-meeting ()
  (interactive)
  (browse-url "http://fuze.me/21449287")
  (message "86753"))

(defun sc-dr-who-scrum ()
  (interactive)
  (browse-url "http://fuze.me/22507555")
  (message "557839#"))

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

(defun sc-check-qa-build ()
  (interactive)
  (mapc 'browse-url '("https://www.dw.sharecare.com"
                      "https://author.dw.sharecare.com")))

(provide 'dg-sc)
