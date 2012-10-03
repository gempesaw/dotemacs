(add-to-list 'load-path "~/.emacs.d/")

(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "kbd.el" 'noerror)
(load "hooks.el" 'noerror)
(load "macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)
(load "selenium-start.el" 'noerror)

;; load all the necessary packages
(load "elget.el" 'noerror)
;; and then tweak their settings them
(load "modes.el" 'noerror)
