(setq jabber-password (if (boundp 'jabber-password) jabber-password ""))

;; jabby wabby - http://stackoverflow.com/a/5731090/1156644
(setq jabber-account-list `(("dgempesaw@sharecare.com"
                             (:connection-type . starttls)
                             (:password . ,jabber-password))))

(setq jabber-alert-presence-hooks nil
      jabber-avatar-verbose nil
      jabber-vcard-avatars-retrieve nil
      jabber-chat-buffer-format "*-jabber-%n-*"
      jabber-history-enabled nil
      jabber-mode-line-mode t
      jabber-roster-buffer "*-jabber-*"
      jabber-roster-line-format " %c %-25n %u %-8s (%r)"
      jabber-show-offline-contacts nil
      jabber-auto-reconnect t
      jabber-muc-autojoin '("qa@conference.sharecare.com")
      jabber-mode-line-string (list " " 'jabber-mode-line-presence)
      starttls-extra-arguments '("--insecure")
      starttls-use-gnutls t)

(jabber-mode-line-mode)

(defun jabber-alert-message-say (from buffer text proposed-alert)
  (interactive)
  (unless (eq (window-buffer (selected-window)) buffer)
    (let ((voice (if (eq 1 (random 2)) "Victoria" "Vicki"))
          (text (car (s-split "\n" text)))
          (from (car (s-split "@" (s-chop-prefix "qa@conference.sharecare.com/" from)))))
      (setq from (cond ((string= from "ebarrsmith") "Erin")
                       ((string= from "cmitchell") "Carl")
                       ((string= from "olebedev") "Olivia")
                       ((string= from "cthompson") "Carmen")
                       ((string= from "jhall") "Janet")
                       ((string= from "jcox") "Jeff")
                       ((string= from "vsatam") "Vikrant")
                       (t from)))
      (start-process "jabber-hello" " *jabber-say-buffer*" "say" "-v" voice " \"" from " says, '" text "'\""))))

(setq jabber-alert-message-hooks '(jabber-message-echo jabber-message-scroll jabber-alert-message-say))

(provide 'dg-jabber)
