(use-package terraform-mode
  :ensure t
  :config
  (add-hook 'terraform-mode-hook 'terraform-format-on-save-mode))

(use-package lsp-mode
  :ensure t
  ;; :hook ((terraform-mode . lsp-deferred))
  :config
  (setq lsp-disabled-clients '(tfls))
  (setq lsp-terraform-ls-enable-show-reference nil)

  (setq lsp-semantic-tokens-enable nil)
  (setq lsp-semantic-tokens-honor-refresh-requests nil)
  (setq lsp-enable-links t)
  (add-hook 'terraform-mode-hook (lambda () (global-company-mode -1)))
  (remove-hook 'terraform-mode-hook 'lsp-deferred)
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.terraform\\'"))

(defun dg-disable-company-mode ()
  (interactive)
  (global-company-mode -1)
  (company-mode -1)
  )

(use-package company-terraform
  :ensure t
  :requires (cape)
  :hook (prog-mode . dg-disable-company-mode)
  :config
  (global-company-mode -1)
  (company-mode -1)

  ;; (add-hook 'terraform-mode-hook (lambda ()
  ;;                                  (add-to-list 'completion-at-point-functions (cape-company-to-capf #'company-terraform))))
  )

(defun dg-jump-to-terraform-source ()
  (interactive)
  (let ((source-line (thing-at-point 'line)))
    (when (s-contains-p "github.com" source-line)
      (let* ((repo (nth 2 (reverse (s-split "github.com[/:]\\|\"\\|\\?" source-line))))
             (tag (nth 1 (reverse (s-split "=\\|\"" source-line))))
             (private-url (->> repo
                               (s-replace "//" (format "/tree/%s/" tag))
                               (format "https://github.com/%s")))
             (local-path (->> repo
                              (s-replace "PagerDuty" (f-expand "~/opt")))))
        (if (f-dir? local-path)
            (let ((files (->> local-path
                              (f-files)
                              (--filter (s-matches-p "main\\|output\\|variable" it)))))
              (xref-push-marker-stack)
              (find-file (completing-read "jump directly to file: " files nil nil)))
          (let ((target (completing-read "open file in browser" '(main outputs variables) nil nil nil)))
            (browse-url (format "%s/blob/main/%s.tf" private-url target))))))))
