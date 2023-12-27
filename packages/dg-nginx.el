;;; pip install -U nginx-language-server

(use-package nginx-mode
  :ensure t
  :hook (nginx-mode . lsp-deferred)
  :config
  (add-to-list 'auto-mode-alist '("conf"  . nginx-mode))
  )
