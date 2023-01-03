(use-package terraform-mode
  :ensure t
  :config
  (add-hook 'terraform-mode-hook 'terraform-format-on-save-mode))

