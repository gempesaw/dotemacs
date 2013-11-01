(mapc (lambda (it)
        (eval-after-load (s-chop-suffix "-mode" (symbol-name it))
          '(diminish it)))
      '(eldoc-mode
        elisp-slime-nav-mode
        paredit-mode
        projectile-mode
        smart-tab-mode
        wrap-region-mode
        subword-mode))

(diminish 'yas-minor-mode)
(diminish 'my-keys-minor-mode)

(provide 'dg-diminish)
