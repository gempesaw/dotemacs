(use-package ansi-color
  :ensure t
  :config

  (defun colorize-compilation-buffer ()
    (let ((inhibit-read-only t))
      (when (eq major-mode 'compilation-mode)
        (ansi-color-apply-on-region compilation-filter-start (point-max)))))

  (add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

  (setq compilation-error-regexp-alist
        (delete 'maven compilation-error-regexp-alist))

  (progn
    (when (string= "tflint" (caar compilation-error-regexp-alist-alist))
      (setq compilation-error-regexp-alist-alist (cdr compilation-error-regexp-alist-alist)))
    (setq compilation-error-regexp-alist-alist
          (cons '(tflint "on \\(.*\\) line \\([[:digit:]]+\\):"
                         1 ;; file
                         2 ;; line
                         )
                compilation-error-regexp-alist-alist)))

  (setq compilation-error-regexp-alist
        (cons 'tflint compilation-error-regexp-alist)))
