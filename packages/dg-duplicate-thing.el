(use-package duplicate-thing
  :ensure t
  :bind (:map my-keys-minor-mode-map
              ("C-c C-d" . duplicate-thing))
  :config
  ;; doesn't work
  (define-key elisp-slime-nav-mode-map (kbd "C-c C-d C-d") nil)
  (define-key elisp-slime-nav-mode-map (kbd "C-c C-d d") nil)
  )
