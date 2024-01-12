(use-package vterm
  :ensure t
  :config
  (setq vterm-kill-buffer-on-exit t)
  (define-key vterm-mode-map (kbd "TAB") #'vterm-send-tab  )
  )


(use-package term
  :config
  (global-unset-key (kbd "C-c M-/"))
  (global-set-key (kbd "C-c M-/") 'term)
  (define-key term-mode-map (kbd "C-;") 'term-char-mode)
  (define-key term-raw-map (kbd "C-;") 'term-line-mode))
