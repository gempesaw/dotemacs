(use-package aggressive-indent
  :ensure t
  :config
  (global-aggressive-indent-mode 1)
  (add-to-list 'aggressive-indent-excluded-modes 'shell-mode)
  (add-to-list 'aggressive-indent-excluded-modes 'fundamental-mode))
