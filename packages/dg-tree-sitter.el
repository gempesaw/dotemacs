(use-package tree-sitter
  :ensure t
  :config)

(use-package treesit-auto
  :ensure t
  :demand t
  :config
  (global-treesit-auto-mode)
  (setq treesit-auto-install t))
