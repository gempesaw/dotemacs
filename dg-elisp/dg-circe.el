(defvar freenode-password nil
  "pass for my freenode acc, it's not in repo obv")
(setq circe-network-options
      `(("Freenode"
         :nick "dgempesaw"
         :channels ("#emacs" "#selenium")
         :nickserv-password ,freenode-password
         )))

(setq circe-reduce-lurker-spam t)

(defvar my-circe-bot-list '("fsbot" "rudybot"))
(defun my-circe-message-option-bot (nick &rest ignored)
  (when (member nick my-circe-bot-list)
    '((text-properties . (face circe-fool-face
                          lui-do-not-track t)))))
(add-hook 'circe-message-option-functions 'my-circe-message-option-bot)

(provide 'dg-circe)
