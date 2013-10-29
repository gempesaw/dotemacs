(mapc (lambda (it)
        (eval-after-load (car it)
          '(diminish (cadr it))))
      '(("eldoc" eldoc-mode
         "elisp-slime-nav" elisp-slime-nav-mode
         "paredit" paredit-mode
         "projectile" projectile-mode
         "smart-tab" smart-tab-mode
         "subword" subword-mode
         "wrap-region" wrap-region-mode
         "yas-minor" yas-minor-mode
         "my-keys-minor" my-keys-minor-mode
         )))

(provide 'dg-diminish)
