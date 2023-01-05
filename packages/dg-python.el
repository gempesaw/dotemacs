(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                         (require 'lsp-pyright)
                         (lsp-deferred))))


(use-package python-black
  :ensure t
  :after python
  :hook (python-mode . python-black-on-save-mode))
