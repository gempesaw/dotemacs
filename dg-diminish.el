(eval-after-load 'eldoc
  '(diminish 'eldoc-mode))

(eval-after-load 'smart-tab
  '(diminish 'smart-tab-mode))

(eval-after-load 'wrap-region
  '(diminish 'wrap-region-mode))

(eval-after-load 'elisp-slime-nav
  '(diminish 'elisp-slime-nav-mode))

(eval-after-load 'paredit
  '(diminish 'paredit-mode "(P)"))

;; (eval-after-load 'subword
;;   '(diminish 'subword-mode))

(eval-after-load 'projectile
  '(diminish 'projectile-mode))

(eval-after-load 'yas-minor-mode
  '(diminish 'yas-minor-mode))

(eval-after-load 'yas-global-mode
  '(diminish 'yas-global-mode))

(provide 'dg-diminish)
