;; switch windows using home row keys
(setq switch-window-shortcut-style 'qwerty)

;; window switching - win-switch + switch-window = winner
(global-unset-key (kbd "M-j"))
(eval-after-load "switch-window"
  '(progn
     (define-key my-keys-minor-mode-map (kbd "M-j") 'switch-window)
     (define-key my-keys-minor-mode-map (kbd "C-c j") 'delete-other-window)
     (define-key my-keys-minor-mode-map (kbd "C-c k") (lambda () (interactive) (delete-other-window t)))))


(provide 'dg-switch-window)
