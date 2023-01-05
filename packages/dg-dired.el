(use-package dired-subtree
  :ensure t
  :bind
  (:map dired-mode-map
        ("i" . dired-subtree-insert)
        ("k" . dired-subtree-remove)))

(use-package find-dired
  :ensure t
  :config
  (setq find-ls-option '("-print0 | xargs -0 ls -ld" . "-ld")))

(use-package dired-aux
  :config
  (add-to-list 'dired-compress-file-suffixes '("\\.zip\\'" ".zip" "unzip")))

(use-package dired
  :bind
  (:map dired-mode-map
        ("<backspace>" . dired-up-directory)
        ("b" . dg-dired-browse-file-at-point))
  :config
  (add-hook 'dired-mode-hook (lambda () (dired-hide-details-mode t)))

  (setq dired-hide-details-hide-symlink-targets nil
        dired-recursive-copies 'always
        dired-recursive-deletes 'top)

  (defun dg-dired-browse-file-at-point ()
    (interactive)
    (let ((path (dired-copy-filename-as-kill 0)))
      (unless (string-match "html$" path)
        (setq path (concat path "/index.html")))
      (browse-url path))))

(use-package wdired
  :bind (:map dired-mode-map
              ("C-c C-p" . wdired-change-to-wdired-mode)))
