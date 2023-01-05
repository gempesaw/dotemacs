(use-package terraform-mode
  :ensure t
  :config
  (add-hook 'terraform-mode-hook 'terraform-format-on-save-mode))

(use-package lsp-mode
  :ensure t
  :hook ((terraform-mode . lsp-deferred))
  :config
  (setq lsp-disabled-clients '(tfls))
  ;; (setq lsp-terraform-ls-enable-show-reference t)

  (setq lsp-semantic-tokens-enable nil)
  (setq lsp-semantic-tokens-honor-refresh-requests nil)
  (setq lsp-enable-links t))

(use-package company-terraform
  :ensure t
  :requires (cape)
  :config
  (global-company-mode -1)
  (company-mode -1)

  ;; (add-hook 'terraform-mode-hook (lambda ()
  ;;                                  (add-to-list 'completion-at-point-functions (cape-company-to-capf #'company-terraform))))
  )
