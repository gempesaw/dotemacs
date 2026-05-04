;;; -*- lexical-binding: t; -*-
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

(use-package lsp-pyright
  :ensure t
  :custom
  (lsp-pyright-langserver-command "basedpyright")
  (lsp-pyright-multi-root nil)
  :hook (python-ts-mode . (lambda ()
                            (require 'lsp-pyright)
                            (lsp-deferred)))
  :init
  (setenv "NODE_OPTIONS"
          (string-join
           (delete-dups
            (append (split-string (or (getenv "NODE_OPTIONS") "") " " t)
                    '("--max-old-space-size=8192")))
           " ")))

(use-package lsp-ruff-lsp
  :after (lsp python)
  :config

  ;; (setq lsp-ruff-lsp-log-level "debug")
  (setq lsp-ruff-lsp-show-notifications 'always)
  )

(use-package python
  :hook ((python-ts-mode . lsp-deferred)
         (python-ts-mode . (lambda () (aggressive-indent-mode -1))))
  :bind (("M-i" . python-add-import)))

(use-package pet
  :ensure
  :demand
  :config
  (add-hook 'python-base-mode-hook 'pet-mode -10))


;; (progn
;;   (require 'lsp-mode)
;;   (setq lsp-ty-client (make-lsp-client
;;                        :new-connection (lsp-stdio-connection '("ty" "server"))
;;                        :major-modes '(python-ts-mode)
;;                        :server-id 'ty-lsp))
;;   (lsp-register-client lsp-ty-client)
;;   (add-hook 'python-ts-mode-hook #'lsp))
