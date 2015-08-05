(defvar circe-freenode-password nil
  "pass for my freenode acc, it's not in repo obv")

(defvar circe-bitlbee-password nil
  "pass for local bitlbee server, not in repo")

(setq circe-network-options
      `(("Freenode"
         :nick "dgempesaw"
         :channels (;; "#emacs"
                    "#selenium"
                    "#chrome-devtools")
         :nickserv-password ,circe-freenode-password
         )
        ("Perl"
         :host "irc.perl.org"
         :port 6667
         :channels ("#perl"))))

(defun bitlbee ()
  (interactive)
  (let ((bitlbee-name "Bitlbee")
        (bitlbee-buffer "localhost:6667"))
    (unless (and (get-buffer bitlbee-buffer)
                 (with-current-buffer bitlbee-buffer
                   circe-server-registered-p))
      (let ((circe-network-options '((bitlbee-name :nowait-on-connect nil))))
        (add-to-list 'circe-server-connected-hook 'bitlbee-login-to-sip-server)
        (circe bitlbee-name)))
    (with-current-buffer (get-buffer bitlbee-buffer)
            (bitlbee-login-to-sip-server))))

(defun bitlbee-login-to-sip-server ()
  (with-current-buffer "localhost:6667"
    (with-circe-server-buffer
      (circe-server-send
       (format "PRIVMSG &bitlbee :identify %s" circe-bitlbee-password)
       t)))
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
