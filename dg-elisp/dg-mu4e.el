(setq mu4e-path "/usr/local/Cellar/mu/HEAD-21b637f/share/emacs/site-lisp/mu/mu4e")
(when (and (eq system-type 'darwin)
           (file-exists-p mu4e-path))
  (add-to-list 'load-path mu4e-path)
  (require 'mu4e)

  (set-face-attribute 'variable-pitch nil
                      :family "Monaco"
                      :height 120
                      :weight 'normal)

  (defun mu4e-shr2text ()
    "Html to text using the shr engine; this can be used in
`mu4e-html2text-command' in a new enough emacs. Based on code by
Titus von der Malsburg."
    (interactive)
    (let ((dom (libxml-parse-html-region (point-min) (point-max)))
          ;; When HTML emails contain references to remote images,
          ;; retrieving these images leaks information. For example,
          ;; the sender can see when I openend the email and from which
          ;; computer (IP address). For this reason, it is preferrable
          ;; to not retrieve images.
          ;; See this discussion on mu-discuss:
          ;; https://groups.google.com/forum/#!topic/mu-discuss/gr1cwNNZnXo
          (shr-width 80)
          (max-specpdl-size 10000))
      (erase-buffer)
      (shr-insert-document dom)
      (goto-char (point-min))))


  (setq mu4e-html2text-command 'mu4e-shr2text
        shr-color-visible-distance-min 10
        shr-color-visible-luminance-min 100)

  (add-hook 'mu4e-view-mode-hook 'turn-on-visual-line-mode)

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


  (setq mu4e-split-view 'horizontal
        mu4e-headers-leave-behavior 'apply

        mu4e-get-mail-command "true"
        mu4e-update-interval 60
        mu4e-index-cleanup nil
        mu4e-index-lazy-check nil
        mu4e-index-update-in-background t

        mu4e-view-prefer-html nil
        mu4e-headers-results-limit 50
        mu4e-use-fancy-chars t
        mu4e-view-show-images t
        mu4e-headers-include-related nil ;; don't show related messages in bookmarks
        mu4e-headers-skip-duplicates t
        mu4e-mu-binary "/usr/local/bin/mu"
        mu4e-bookmarks '(("from:(JIRA) and flag:unread" "Unread JIRA" ?j)
                         ("from:root and subject:Honeydew and flag:unread and date:14d..now" "Honeydew" ?h)
                         ("(from:vsatam@sharecare.com OR to:vsatam@sharecare.com) and subject:DW" "Vik" ?v)
                         ("subject:SC2 AND subject:Build AND subject:QA AND date:today..now AND NOT from:dgempesaw@sharecare.com AND NOT replied AND NOT from:ebarrsmith@sharecare.com AND NOT from:cbanks@sharecare.com AND NOT from:jreynolds@sharecare.com" "QA Builds" ?q)
                         ("flag:unread AND NOT flag:trashed AND NOT subject:JIRA AND NOT from:uptime" "Unread messages" ?u)
                         ("date:today..now AND NOT subject:JIRA AND NOT subject:confluence" "Today's messages" ?r)
                         ("(subject:mentioned you (JIRA) OR assigned*Daniel Gempesaw) AND from:JIRA" "Tagged in JIRA" ?J)
                         ("maildir:/INBOX AND date:1m..now AND NOT from:squash@sharecare.com AND NOT from:root@sharecare.com AND NOT (from:root@honeydew.be.jamconsultg.com AND NOT subject:ios) AND NOT (from:dgempesaw AND (to:dgempesaw OR cc:dgempesaw)) AND NOT from:adminui@sharecare.com AND NOT from:noreply@sf-notifications.com AND NOT from:noreply@bactes.com AND NOT from:(JIRA) AND NOT from:nagios@be.jamconsultg.com AND NOT (subject:Build AND subject:Feature) AND NOT to:devteam@bactes.com AND NOT (from:jenkins@sharecare.com AND subject:Sonar) AND NOT from:nagios AND NOT from:noreply@newrelic.com AND NOT from:honeydew@sharecare.com AND NOT (subject:\"Build\" AND subject:\"request\") AND NOT (subject:\"Jenkins\" AND from:jenkins@sharecare.com) AND NOT (from:jenkins@sharecare.com AND to:sc2-build-notifications@sharecare.com)" "Inbox" ?i)
                         ("maildir:/INBOX AND subject:Build and flag:unread" "Build Requests" ?b)
                         ("from:dgempesaw AND (to:cbanks OR cc:cbanks) AND update" "clint" ?c)
                         ("(maildir:/INBOX or maildir:/archive) AND NOT from:(JIRA) AND NOT from:nagios AND NOT subject:honeydew AND NOT from:adminui" "All Inbox" ?I)
                         ("from:dgempesaw@sharecare.com" "Sent" ?t)
                         ("date:7d..now AND NOT subject:lookup" "Last 7 days" ?l)
                         ("Meeting AND NOT from:dgempesaw@sharecare.com" "Meetings" ?m)
                         ("maildir:/DRAFTS" "Drafts" ?d)))

  (setq user-mail-address "dgempesaw@sharecare.com"
        user-full-name  "Daniel Gempesaw")

  ;; with Emacs 23.1, you have to set this explicitly (in MS Windows)
  ;; otherwise it tries to send through OS associated mail client
  (setq message-send-mail-function 'message-send-mail-with-sendmail
        message-send-mail-function 'smtpmail-send-it
        message-signature "Daniel Gempesaw | Software Testing Architect
M 302.754.1231 - dgempesaw@sharecare.com

Sharecare, Inc.

My RealAge is 6.3 years younger. What's yours? Take the test now!
https://www.sharecare.com/realage-test
"
        mu4e-compose-signature message-signature
        mu4e-compose-format-flowed t
        fill-flowed-encode-column 66)

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
       (define-key mu4e-headers-mode-map (kbd "q") (lambda () (interactive) (jump-to-register 6245)))
       (define-key mu4e-headers-mode-map (kbd "z") 'mu4e~headers-quit-buffer)
       (define-key mu4e-view-mode-map (kbd "m") 'mu4e-headers-mark-for-something)
       (define-key mu4e-view-mode-map (kbd "V") 'mu4e-msgv-action-view-in-browser)
       (define-key mu4e-view-mode-map (kbd "J") 'mu4e-message-open-jira-ticket)))

  ;; give me ISO(ish) format date-time stamps in the header list
  (setq mu4e-headers-date-format "%Y-%m-%d %l:%M %P")
  (setq mu4e-headers-fields
        '( (:date          .  20)
           (:flags         .   6)
           (:from          .  22)
           (:subject       .  nil)))

  ;; show full addresses in view message (instead of just names)
  ;; toggle per name with M-RET
  (setq mu4e-view-show-addresses 't)
  (setq mu4e-split-view 'vertical)

  ;; don't keep message buffers around
  (setq message-kill-buffer-on-exit t)

  (setq ;; setting the cite-style doesn't work???? so we set everything manually
   message-cite-style message-cite-style-outlook
   message-cite-function  'message-cite-original
   message-citation-line-function  'message-insert-formatted-citation-line
   message-cite-reply-position 'above
   message-yank-prefix  ""
   message-yank-cited-prefix  ""
   message-yank-empty-prefix  ""
   message-citation-line-format  "\n\n-----------------------\nOn %a, %b %d %Y, %N wrote:\n")
  )

(unless (executable-find "html2text")
  (message "Missing `html2text`. Maybe try `brew install html2text` ?"))

(defadvice browse-url (around use-existant-default-directory activate)
  (let ((default-directory "/"))
    ad-do-it))

(provide 'dg-mu4e)
