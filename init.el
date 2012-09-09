(add-to-list 'load-path "~/.emacs.d/")
(load "customize.el")

;; load the child files
(load "alias.el" 'noerror)
(load "defun.el" 'noerror)
(load "elget.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "kbd.el" 'noerror)
(load "hooks.el" 'noerror)
(load "modes.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)
(load "selenium-start.el" 'noerror)
