(use-package dumb-jump
  :ensure t
  :demand t
  :bind (("C-." . dumb-jump-go))
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  (setq xref-show-definitions-function #'xref-show-definitions-buffer))
