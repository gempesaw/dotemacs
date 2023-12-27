(use-package yaml-mode
  :ensure t
  :demand t
  :init
  (add-hook 'yaml-mode-hook 'lsp-deferred))

(use-package highlight-indent-guides
  :ensure t
  :demand
  :requires (yaml-mode)
  :init
  (add-hook 'yaml-mode-hook 'highlight-indent-guides-mode)
  :config
  (setq highlight-indent-guides-method 'fill)
  (setq highlight-indent-guides-auto-odd-face-perc 25)
  (setq highlight-indent-guides-auto-even-face-perc 15)
  )

(use-package yaml-pro
  :ensure t
  :demand t
  :bind (:map yaml-pro-ts-mode-map
              ("C-M-n" . yaml-pro-ts-next-subtree)
              ("C-M-p" . yaml-pro-ts-prev-subtree))
  :init
  (add-hook 'yaml-mode-hook 'yaml-pro-ts-mode))
