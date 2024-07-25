(use-package transient-posframe
  :ensure t
  :demand t
  :config
  (transient-posframe-mode)
  (setq transient-posframe-poshandler #'posframe-poshandler-frame-center))

(use-package vertico-posframe
  :ensure t
  :demand t
  :config
  (vertico-posframe-mode)
  (setq vertico-posframe-poshandler #'posframe-poshandler-frame-center))

(use-package mini-frame
  :ensure t
  :demand t)
