(defvar freenode-password nil
  "pass for my freenode acc, it's not in repo obv")
(setq circe-network-options
      `(("Freenode"
         :nick "dgempesaw"
         :channels ("#emacs" "#selenium")
         :nickserv-password ,freenode-password
         )))

(provide 'dg-circe)
