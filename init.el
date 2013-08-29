(add-to-list 'load-path "~/.emacs.d/")

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)

;; now load my things
(setq dg-files '(
                 dg-elisp-macros
                 dg-tabs
                 dg-mu4e
                 dg-misc
                 dg-sc-defun
                 ))

(mapcar (lambda (it)
          (require it))
        dg-files)

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
(load "themes.el" 'noerror)

(sc-start-selenium-server)

(provide 'init)
