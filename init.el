(add-to-list 'load-path "~/.emacs.d/")

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)

;; now load my things
(setq dg-files '(
                 dg-override-keys
                 dg-elisp-macros
                 dg-kbd
                 dg-tabs
                 dg-mu4e
                 dg-misc
                 dg-defun
                 dg-sc-defun
                 ))

(mapcar (lambda (it)
          (require it))
        dg-files)

(load "passwords.el" 'noerror)
(load "customize.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "themes.el" 'noerror)

(start-selenium-server)

(provide 'init)
