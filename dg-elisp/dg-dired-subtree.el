(require 'dired-subtree)

(define-key dired-mode-map (kbd "i")
  (lambda ()
    (interactive)
    (dired-subtree-insert)
    (revert-buffer)))

(define-key dired-mode-map (kbd "k")
  (lambda ()
    (interactive)
    (dired-subtree-remove)
    (revert-buffer)))

(provide 'dg-dired-subtree)
