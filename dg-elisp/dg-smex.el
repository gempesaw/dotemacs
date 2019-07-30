(global-set-key (kbd "<f17>") 'smex)
(setq smex-key-advice-ignore-menu-bar t)

;; use smex
(global-unset-key (kbd "M-x"))
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "C-c M-x") 'smex-major-mode-commands)
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

(provide 'dg-smex)
