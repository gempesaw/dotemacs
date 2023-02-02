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
