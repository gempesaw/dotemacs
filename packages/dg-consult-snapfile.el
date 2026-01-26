(use-package websocket :ensure t)

(use-package consult-snapfile
  :load-path "~/opt/consult-snapfile/emacs"
  :after (consult websocket)
  :commands (consult-snapfile))

(provide 'dg-consult-snapfile)
