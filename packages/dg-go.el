(use-package go-mode
  :ensure t
  :hook (go-mode . lsp-deferred)
  :config
  (add-hook 'go-ts-mode-hook 'lsp-deferred))
