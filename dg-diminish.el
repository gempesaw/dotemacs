(mapc (lambda (it) (diminish it))
      '(eldoc-mode
        elisp-slime-nav-mode
        paredit-mode
        projectile-mode
        smart-tab-mode
        subword-mode
        wrap-region-mode
        yas-minor-mode
        my-keys-minor-mode))

(provide 'dg-diminish)
