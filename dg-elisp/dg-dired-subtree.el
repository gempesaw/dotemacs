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

(progn
  (set-face-attribute 'dired-subtree-depth-1-face nil :background "#DAD1CF")
  (set-face-attribute 'dired-subtree-depth-2-face nil :background "#DAD1CF")
  (set-face-attribute 'dired-subtree-depth-3-face nil :background "#DAD1CF")
  (set-face-attribute 'dired-subtree-depth-4-face nil :background "#DAD1CF")
  (set-face-attribute 'dired-subtree-depth-5-face nil :background "#DAD1CF")
  (set-face-attribute 'dired-subtree-depth-6-face nil :background "#DAD1CF"))

(provide 'dg-dired-subtree)
