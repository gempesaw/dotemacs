(require 'ansi-color)

(defun colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
    (when (eq major-mode 'compilation-mode)
      (ansi-color-apply-on-region compilation-filter-start (point-max)))))

(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

(setq compilation-error-regexp-alist
      (delete 'maven compilation-error-regexp-alist))

(progn
  (when (string= "eslint" (caar compilation-error-regexp-alist-alist))
    (setq compilation-error-regexp-alist-alist (cdr compilation-error-regexp-alist-alist)))
  (setq compilation-error-regexp-alist-alist
        (cons '(eslint "\\(/.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\):"
                     1 ;; file
                     2 ;; line
                     3 ;; column
                     )
              compilation-error-regexp-alist-alist)))

(setq compilation-error-regexp-alist
      (cons 'eslint compilation-error-regexp-alist))


(progn
  (when (string= "node" (caar compilation-error-regexp-alist-alist))
    (setq compilation-error-regexp-alist-alist (cdr compilation-error-regexp-alist-alist)))
  (setq compilation-error-regexp-alist-alist
        (cons '(node "at [^ ]+ (\\(.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\)"
                     1 ;; file
                     2 ;; line
                     3 ;; column
                     )
              compilation-error-regexp-alist-alist)))

(setq compilation-error-regexp-alist
      (cons 'node compilation-error-regexp-alist))

(provide 'dg-compilation)
