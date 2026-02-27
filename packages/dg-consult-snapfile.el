;; -*- lexical-binding: t; -*-
(use-package websocket :ensure t)

(use-package consult-snapfile
  :load-path "~/opt/consult-snapfile/emacs"
  :after (consult websocket)
  :commands (consult-snapfile)
  :demand t
  :custom
  (consult-snapfile-max-results 2000)
  :config (require 'consult-snapfile))

(provide 'dg-consult-snapfile)
