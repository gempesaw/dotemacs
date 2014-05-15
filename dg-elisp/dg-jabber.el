;; jabby wabby - http://stackoverflow.com/a/5731090/1156644

;; brew install gnutls
(if (executable-find "gnutls-cli")
    (progn
      (defvar sharecare-jabber-password nil "this is defined in passwords.el")
      (setq jabber-account-list `(("dgempesaw@sharecare.com"
                                   (:connection-type . starttls)
                                   (:password . ,(car
                                                  (reverse
                                                   (split-string
                                                    (car
                                                     (get-file-as-string "~/.authinfo")) " ")))))))

      (jabber-mode-line-mode)

      (setq jabber-alert-presence-hooks nil
            jabber-avatar-verbose nil
            jabber-vcard-avatars-retrieve nil
            jabber-chat-buffer-format "*-jabber-%n-*"
            jabber-history-enabled nil
            jabber-mode-line-mode t
            jabber-roster-buffer "*-jabber-*"
            jabber-roster-line-format " %c %-25n %u %-8s (%r)"
            jabber-show-offline-contacts nil
            jabber-auto-reconnect nil
            jabber-muc-autojoin '("qa@conference.sharecare.com" "doctorwhoteamchat@conference.sharecare.com")
            jabber-mode-line-string (list " " 'jabber-mode-line-presence " ")
            starttls-extra-arguments '("--insecure")
            starttls-use-gnutls t)

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
                             ((string= from "dandonov_cw") "Dian")
                             ((string= from "jcox") "Jeff")
                             ((string= from "jthatil") "Justin")
                             ((string= from "vsatam") "Vikrant")
                             (t from)))
            (start-process "jabber-hello" " *jabber-say-buffer*" "say" "-v" voice " \"" from " says, '" text "'\""))))

      (setq jabber-alert-message-hooks '(jabber-message-echo jabber-message-scroll jabber-alert-message-say))

      (define-key jabber-global-keymap "\C-u" 'jabber-muc-join)
      (define-key ctl-x-map "\C-j" jabber-global-keymap)

      (global-unset-key (kbd "s-q"))
      (global-set-key
       (kbd "s-q")
       (lambda () (interactive)
         (toggle-app-and-home
          "jabber-groupchat"
          (lambda ()
            (delete-other-windows)
            (switch-to-buffer "*-jabber-groupchat-qa@conference.sharecare.com-*")
            (split-window-horizontally)
            (other-window 1)
            (switch-to-buffer "*-jabber-groupchat-doctorwhoteamchat@conference.sharecare.com-*")
            ))
         )))
  (message "Looks like you're missing `gnutls-cli`. Try `brew install gnutls`"))

(provide 'dg-jabber)
