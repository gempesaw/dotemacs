(setq dg-python-autoflake-path (executable-find "autoflake"))
(defun dg-python-autoflake ()
  (interactive)
  (when (or (eq major-mode 'python-mode)
            (eq major-mode 'python-ts-mode))
    (shell-command (format "%s --remove-all-unused-imports -i %s"
                           dg-python-autoflake-path
                           (shell-quote-argument (buffer-file-name))))
    (revert-buffer t t t)))

;;; pip install isort autoflake
(use-package lsp-pyright
  :ensure t
  :demand t
  :hook (
         (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp-deferred)))
         (python-ts-mode . (lambda ()
                             (require 'lsp-pyright)
                             (lsp-deferred)))))

(use-package python-black
  :ensure t
  :after (python)
  :hook (
         (python-mode . python-black-on-save-mode)
         (python-ts-mode . python-black-on-save-mode)
         ))

(use-package py-isort
  :ensure t
  :after (python)
  :config
  (setq py-isort-options '("--profile" "black"))

  (add-hook 'python-ts-mode-hook 'dg-py-isort-enable 90)
  (defun dg-py-isort-enable ()
    (interactive)
    (add-to-list 'before-save-hook 'py-isort-buffer)))


(remove-hook 'before-save-hook 'py-isort-buffer)
