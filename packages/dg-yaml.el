(use-package yaml-mode
  :requires (lsp)
  :ensure t
  :config
  (add-hook 'yaml-mode-hook 'lsp-deferred))

(use-package highlight-indent-guides
  :ensure t
  :requires (lsp yaml-mode)
  :config
  (add-hook 'yaml-mode-hook 'highlight-indent-guides-mode))
