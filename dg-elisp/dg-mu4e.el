(when (and (eq system-type 'darwin)
           (file-exists-p "/Users/dgempesaw/opt/mu/mu4e/"))
  (add-to-list 'load-path "/Users/dgempesaw/opt/mu/mu4e/")
  (require 'mu4e)

  ;; display some minibuffer signal when we have QA mail on OS X
  (setq display-time-mail-function nil
        display-time-use-mail-icon t
        display-time-mail-face '((t (:background "red"))))

  (defun qa-build-email-pending-p ()
    (let ((qa-email-file "~/.qa-build-ready"))
      (> (string-to-number (s-trim (car (get-file-as-string qa-email-file)))) 0)))

  (defvar current-time-format "%a %H:%M:%S"
    "Format of date to insert with `insert-current-time'
    func. Note the weekly scope of the command's precision.")

  (setq mu4e-get-mail-command "true"
        mu4e-split-view 'vertical
        mu4e-headers-leave-behavior 'apply
        mu4e-update-interval 180
        mu4e-view-prefer-html nil
        mu4e-headers-results-limit 50
        mu4e-use-fancy-chars nil
        mu4e-view-show-images t
        mu4e-mu-binary "/usr/local/bin/mu"
        mu4e-html2text-command "html2text -nobs -width 72 -utf8 | sed 's/&quot;/\"/g'"
        mu4e-bookmarks '(("from:(JIRA) and flag:unread" "Unread JIRA" ?j)
                         ("from:root and subject:Honeydew" "Honeydew" ?h)
                         ("(from:vsatam@sharecare.com OR to:vsatam@sharecare.com) and subject:DW" "Vik" ?v)
                         ("subject:SC2 AND subject:Build AND subject:QA AND date:today..now AND NOT from:dgempesaw@sharecare.com AND NOT replied AND NOT from:ebarrsmith@sharecare.com AND NOT from:cbanks@sharecare.com AND NOT from:jreynolds@sharecare.com" "QA Builds" ?q)
                         ("flag:unread AND NOT flag:trashed AND NOT subject:JIRA AND NOT from:uptime" "Unread messages" ?u)
                         ("date:today..now AND NOT subject:JIRA AND NOT subject:confluence" "Today's messages" ?r)
                         ("subject:mentioned you (JIRA) OR assigned*Daniel Gempesaw" "Tagged in JIRA" ?J)
                         ("maildir:/INBOX AND NOT subject:Cron AND date:3d..now AND NOT subject:fitness AND NOT from:squash AND NOT (from:dgempesaw AND (to:dgempesaw OR cc:dgempesaw)) AND NOT from:adminui@sharecare.com AND NOT from:ShareFile AND NOT from:noreply@bactes.com AND NOT from:(JIRA) AND NOT from:nagios AND NOT subject:honeydew " "Inbox" ?i)
                         ("from:dgempesaw AND (to:cbanks OR cc:cbanks) AND update" "clint" ?c)
                         ("(maildir:/INBOX or maildir:/archive) AND NOT from:(JIRA) AND NOT from:nagios AND NOT subject:honeydew AND NOT from:adminui" "All Inbox" ?I)
                         ("from:dgempesaw@sharecare.com" "Sent" ?t)
                         ("date:7d..now" "Last 7 days" ?l)
                         ("Meeting AND NOT from:dgempesaw@sharecare.com" "Meetings" ?m)))

  (setq user-mail-address "dgempesaw@sharecare.com"
        user-full-name  "Daniel Gempesaw")

  ;; with Emacs 23.1, you have to set this explicitly (in MS Windows)
  ;; otherwise it tries to send through OS associated mail client
  (setq message-send-mail-function 'message-send-mail-with-sendmail
        message-send-mail-function 'smtpmail-send-it
        message-signature "--
Daniel Gempesaw | Software Testing Architect
M 302.754.1231

Sharecare, Inc.
Sharecare.com | DoctorOz.com | DailyStrength.org | the little blue book | BACTES

www.sharecare.com/realagetest")

  (setq smtpmail-stream-type 'starttls
        smtpmail-default-smtp-server "pod51019.outlook.com"
        smtpmail-smtp-server "pod51019.outlook.com"
        smtpmail-smtp-user "dgempesaw@sharecare.com"
        smtpmail-smtp-service 587)

  (defun mu4e-message (frm &rest args)
    "Like `message', but prefixed with mu4e.
If we're waiting for user-input, don't show anyhting."
    (unless (or (active-minibuffer-window)
                (not (string-match-p "^\(Indexing\|Retrieving\)" frm)))
      (message "%s" (apply 'mu4e-format frm args))
      nil))

  (defun mu4e-toggle-html2text-width ()
    (interactive)
    (message
     (setq mu4e-html2text-command
           (concat "html2text -nobs -width "
                   (if (string-match "1000" mu4e-html2text-command)
                       "72"
                     "1000")
                   " -utf8 | sed 's/&quot;/\"/g'"
                   " | sed 's/if !supportLists]>/\\\n/g'"
                   " | sed 's/endif]>//g'"))
     (mu4e-view-refresh)))

  ;; http://www.emacswiki.org/emacs/mu4e - message view action
  (defun mu4e-msgv-action-view-in-browser ()
    "View the body of the message in a web browser."
    (interactive)
    (let ((html (mu4e-msg-field (mu4e-message-at-point t) :body-html))
          (tmpfile (format "%s/%d.html" temporary-file-directory (random))))
      (unless html (error "No html part for this message"))
      (with-temp-file tmpfile
        (insert
         "<html>"
         "<head><meta http-equiv=\"content-type\""
         "content=\"text/html;charset=UTF-8\">"
         html))
      (browse-url (concat "file://" tmpfile))))
  (add-to-list 'mu4e-view-actions
               '("View in browser" . mu4e-msgv-action-view-in-browser) t)

  (global-unset-key (kbd "s-m"))
  (global-set-key (kbd "s-m") (lambda ()
                                (interactive)
                                (let ((buf "*mu4e-headers*"))
                                  (if (not (string-match "mu4e" (buffer-name)))
                                      (progn
                                        (window-configuration-to-register 6245)
                                        (with-current-buffer (get-buffer-create buf)
                                          (unless (string-match "Search" (buffer-string))
                                            (execute-kbd-macro 'mu4e-open-inbox))
                                          (switch-to-buffer buf))
                                        (delete-other-windows))
                                    (jump-to-register 6245)))))


  (eval-after-load "mu4e"
    '(progn
       (define-key mu4e-headers-mode-map (kbd "@") 'mu4e-headers-mark-all-as-read)
       (define-key mu4e-headers-mode-map (kbd "J") 'mu4e-headers-open-jira-ticket)
       (define-key mu4e-headers-mode-map (kbd "m") 'mu4e-headers-mark-for-something)
       (define-key mu4e-headers-mode-map (kbd "T") 'mu4e-toggle-html2text-width)
       (define-key mu4e-headers-mode-map (kbd "q") (lambda () (interactive) (jump-to-register 6245)))
       (define-key mu4e-view-mode-map (kbd "T") 'mu4e-toggle-html2text-width)
       (define-key mu4e-view-mode-map (kbd "m") 'mu4e-headers-mark-for-something)
       (define-key mu4e-view-mode-map (kbd "V") 'mu4e-msgv-action-view-in-browser)
       (define-key mu4e-view-mode-map (kbd "J") 'mu4e-message-open-jira-ticket))))

(unless (executable-find "html2text")
  (message "Missing `html2text`. Maybe try `brew install html2text` ?"))

(provide 'dg-mu4e)
