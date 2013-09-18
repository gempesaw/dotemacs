(when (eq system-type 'darwin)
  (add-to-list 'load-path "/usr/local/Cellar/mu/HEAD/share/emacs/site-lisp/mu4e")
  (require 'mu4e)

  ;; display some minibuffer signal when we have QA mail on OS X
  (setq display-time-mail-function 'qa-build-email-pending-p
        display-time-use-mail-icon t
        display-time-mail-face '((t (:background "red"))))

  (defvar current-time-format "%a %H:%M:%S"
    "Format of date to insert with `insert-current-time'
    func. Note the weekly scope of the command's precision.")

  (setq mu4e-get-mail-command "true"
        mu4e-headers-leave-behavior 'apply
        mu4e-update-interval 180
        mu4e-view-prefer-html nil
        mu4e-headers-results-limit 50
        mu4e-use-fancy-chars nil
        mu4e-view-show-images t
        mu4e-mu-binary "/usr/local/bin/mu"
        mu4e-html2text-command "html2text -nobs -width 72 -utf8 | sed 's/&quot;/\"/g'"
        mu4e-bookmarks '(("'maildir:/INBOX.JIRA' and date:1d..now and NOT subject:STAR" "Today's JIRA" ?1)
                         ("'maildir:/INBOX.JIRA' and flag:unread" "Unread JIRA" ?j)
                         ("'maildir:/INBOX.JIRA'" "All JIRA" ?h)
                         ("subject:SC2 AND subject:Build AND subject:QA AND date:today..now AND NOT from:dgempesaw@sharecare.com AND NOT replied" "QA Builds" ?q)
                         ("flag:unread AND NOT flag:trashed AND NOT subject:JIRA AND NOT from:uptime" "Unread messages" ?u)
                         ("date:today..now AND NOT subject:JIRA AND NOT subject:confluence" "Today's messages" ?r)
                         ("subject:mentioned you (JIRA) OR assigned*Daniel Gempesaw" "Tagged in JIRA" ?J)
                         ("maildir:/INBOX AND date:1d..now AND NOT subject:fitness AND NOT from:root AND NOT from:squash" "Inbox" ?i)
                         ("maildir:/INBOX" "All Inbox" ?I)
                         ;; mu find SC2 QA Build Request from:vsatam@sharecare.com unread
                         ("from:dgempesaw@sharecare.com" "Sent" ?t)
                         ("date:7d..now" "Last 7 days" ?l)
                         ("Meeting AND NOT from:dgempesaw@sharecare.com" "Meetings" ?m)))

  (setq user-mail-address "dgempesaw@sharecare.com"
        user-full-name  "Daniel Gempesaw")

  ;; with Emacs 23.1, you have to set this explicitly (in MS Windows)
  ;; otherwise it tries to send through OS associated mail client
  (setq message-send-mail-function 'message-send-mail-with-sendmail
        message-send-mail-function 'smtpmail-send-it
        smtpmail-stream-type 'starttls
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
                 " -utf8 | sed 's/&quot;/\"/g'"))
   (mu4e-view-refresh)))

  (defun qa-build-email-pending-p ()
    (let ((qa-email-file "~/.qa-build-ready"))
      (> (string-to-number (s-trim (car (get-file-as-string qa-email-file)))) 0)))


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
                                          (mu4e-update-mail-and-index t)
                                          (switch-to-buffer buf))
                                        (delete-other-windows))
                                    (jump-to-register 6245)))))


  (eval-after-load "mu4e"
    '(progn
       (define-key mu4e-headers-mode-map (kbd "@") 'mu4e-headers-mark-all-as-read)
       (define-key mu4e-headers-mode-map (kbd "J") 'mu4e-headers-open-jira-ticket)
       (define-key mu4e-headers-mode-map (kbd "m") 'mu4e-headers-mark-for-something)
       (define-key mu4e-headers-mode-map (kbd "T") 'mu4e-toggle-html2text-width)
       (define-key mu4e-view-mode-map (kbd "T") 'mu4e-toggle-html2text-width)
       (define-key mu4e-view-mode-map (kbd "J") 'mu4e-message-open-jira-ticket))))

(provide 'dg-mu4e)
