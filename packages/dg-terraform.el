;;; -*- lexical-binding: t; -*-
(use-package terraform-mode
  :ensure t
  :hook (
         (terraform-mode . lsp-deferred)
         (terraform-mode . terraform-format-on-save-mode))
  :config
  ;; https://emacs-lsp.github.io/lsp-mode/manual-language-docs/lsp-terraform-ls/

  ;; use hashicorp's official lsp server
  (setq lsp-disabled-clients '(tfls))

  (setq lsp-terraform-ls-enable-show-reference t)

  (setq lsp-semantic-tokens-enable nil)
  (setq lsp-semantic-tokens-honor-refresh-requests nil)

  (setq lsp-enable-links t)
  (setq lsp-terraform-ls-prefill-required-fields t)

  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.terraform\\'")
  )

(defun dg-jump-to-terraform-source ()
  (interactive)
  (let ((source-line (thing-at-point 'line)))
    (cond
     ((s-contains-p "github.com" source-line)
      (let* ((repo (nth 2 (reverse (s-split "github.com[/:]\\|\"\\|\\?" source-line))))
             (tag (nth 1 (reverse (s-split "=\\|\"" source-line))))
             (private-url (if (s-contains-p "//" repo)
                              (->> repo
                                   (s-replace "//" (format "/blob/%s/" tag))
                                   (format "https://github.com/%s"))
                            (format "https://github.com/%s/blob/%s" repo tag)
                            ))
             (local-path (->> repo
                              (s-replace "PagerDuty" (f-expand "~/opt")))))
        (if (f-dir? local-path)
            (let ((files (->> local-path
                              (f-files)
                              (--filter (s-matches-p "main\\|output\\|variable" it)))))
              (xref-push-marker-stack)
              (find-file (completing-read "jump directly to file: " files nil nil)))
          (let ((target (completing-read "open file in browser" '(main outputs variables releases) nil nil nil)))
            (if (s-equals-p target 'releases)
                (browse-url (format "https://github.com/%s/releases" repo))
              (browse-url (format "%s/%s.tf" private-url target))))))
      t)
     ((s-contains-p "../" source-line)
      (let ((path (f-join (cwd) (nth 1 (s-split "\"" source-line)))))
        (xref-push-marker-stack)
        (find-file (completing-read "jump directly to file: " (f-files path) nil nil)))
      t)
     ((s-contains-p "../" source-line)
      (let ((path (f-join (cwd) (nth 1 (s-split "\"" source-line)))))
        (xref-push-marker-stack)
        (find-file (completing-read "jump directly to file: " (f-files path) nil nil)))
      t)
     (t t))
    )
  nil
  )
