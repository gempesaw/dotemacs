(use-package elixir-mode
  :ensure t
  :hook (elixir-mode . (lambda ()
                         (lsp-deferred))))
