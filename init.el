(add-to-list 'load-path "~/.emacs.d/")

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)

;; consolidated settings files
(require 'dg-elisp-macros)
(load "passwords.el" 'noerror)
(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "kbd.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)

(require 'dg-mu4e)

(sc-start-selenium-server)

(provide 'init)
