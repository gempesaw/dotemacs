(use-package switch-window
  :ensure t
  
  :config
  (setq switch-window-shortcut-style 'qwerty
	switch-window-configuration-change-hook-inhibit t
	switch-window-shortcut-appearance 'text)

  :bind (:map my-keys-minor-mode-map
	      ("M-j" . switch-window)
	      ("C-c j" . switch-window-then-delete)
	      ("C-c k" . switch-window-then-kill-buffer))
  )
