(use-package make-mode
  :init
  (add-hook 'makefile-mode-hook #'dg-use-tabs-for-whitespace)
  :demand t)
