(defvar circe-freenode-password nil
  "pass for my freenode acc, it's not in repo obv")

(defvar circe-bitlbee-password nil
  "pass for local bitlbee server, not in repo")

(setq circe-network-options
      `(("Freenode"
         :nick "dgempesaw"
         :channels ("#emacs" "#selenium")
         :nickserv-password ,circe-freenode-password
         )))

(defun bitlbee ()
  (interactive)
  (save-window-excursion
    (let ((circe-network-options '(("Bitlbee" :nowait-on-connect nil))))
      (circe "Bitlbee")
      (set-buffer "localhost:6667")
      (bitlbee-login-to-sip-server))))

(defun bitlbee-login-to-sip-server ()
  (with-circe-server-buffer
    (circe-server-send
     (format "PRIVMSG &bitlbee :identify %s" circe-bitlbee-password)
     t))
  (run-at-time "10 sec" nil (lambda ()
                              (set-buffer "localhost:6667")
                              (with-circe-server-buffer
                                (circe-server-send "PRIVMSG &bitlbee blist" t))
                              (bury-buffer "localhost:6667"))))

(setq circe-reduce-lurker-spam t)

(defvar my-circe-bot-list '("fsbot" "rudybot"))
(defun my-circe-message-option-bot (nick &rest ignored)
  (when (member nick my-circe-bot-list)
    '((text-properties . (face circe-fool-face
                               lui-do-not-track t)))))
(add-hook 'circe-message-option-functions 'my-circe-message-option-bot)

(provide 'dg-circe)
