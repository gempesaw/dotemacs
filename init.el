(add-to-list 'load-path "~/.emacs.d/")

;; consolidated settings files
(load "passwords.el" 'noerror)
(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "hooks.el" 'noerror)
(load "kbd.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)
(load "selenium-start.el" 'noerror)

;; manually load some packages
(load "smart-compile.el" 'noerror)
(load "/opt/fetchmacs/fetchmacs-creds.el" 'noerror)
(load "/opt/fetchmacs/fetchmacs.el" 'noerror)

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)
;; and then tweak their settings
(load "modes.el" 'noerror)
