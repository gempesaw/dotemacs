;;; -*- lexical-binding: t; -*-
(use-package elixir-mode
  :ensure t
  :hook (elixir-mode . (lambda ()
                         (lsp-deferred)))
  :config
  (add-to-list 'exec-path (concat (getenv "HOME") "/.emacs.d/.cache/lsp/elixir-ls/")))
