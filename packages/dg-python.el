;; (use-package python-black
;;   :ensure t
;;   :after (python)
;;   :hook (
;;          (python-mode . python-black-on-save-mode)
;;          (python-ts-mode . python-black-on-save-mode)
;;          ))

;; (use-package py-isort
;;   :ensure t
;;   :after (python)
;;   :config
;;   (setq py-isort-options '("--profile" "black"))

;;   (add-hook 'python-ts-mode-hook 'dg-py-isort-enable 90)
;;   (defun dg-py-isort-enable ()
;;     (interactive)
;;     (add-to-list 'before-save-hook 'py-isort-buffer)))


;; (remove-hook 'before-save-hook 'py-isort-buffer)

(use-package lsp-ruff-lsp
  :after (lsp python)
  :config

  ;; (setq lsp-ruff-lsp-log-level "debug")
  (setq lsp-ruff-lsp-show-notifications 'always)
  )

(use-package python
  :hook ((python-ts-mode . lsp-deferred)
         (python-ts-mode . (lambda () (aggressive-indent-mode -1)))))
