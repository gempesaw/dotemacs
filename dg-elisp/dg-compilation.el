(require 'ansi-color)

(defun colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
    (when (eq major-mode 'compilation-mode)
      (ansi-color-apply-on-region compilation-filter-start (point-max)))))

(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

(setq compilation-error-regexp-alist
      (delete 'maven compilation-error-regexp-alist))

(provide 'dg-compilation)
