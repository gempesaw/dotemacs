(add-to-list 'load-path "~/.emacs.d/")

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)

;; now load my things
(setq dg-files '(
                 dg-defun
                 dg-elisp-macros
                 dg-kbd
                 dg-tabs
                 dg-mu4e
                 dg-misc
                 dg-numpad
                 dg-override-keys
                 dg-sc-defun
                 dg-selenium
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

(provide 'init)
