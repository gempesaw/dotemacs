(use-package highlight-indent-guides
  :requires (lsp)
  :config
  (add-hook 'yaml-mode-hook 'lsp-deferred)
  (add-hook 'yaml-mode-hook 'highlight-indent-guides-mode))
