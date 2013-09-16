(add-to-list 'load-path "~/.emacs.d/")

(setq dg-files '(
                 dg-load-my-packages       ;; load all the necessary packages
                 dg-override-keys       ;; needs to be first so other files can use it
                 dg-passwords           ;; needs to be first so other files can use it
                 dg-defun
                 dg-elisp-macros
                 dg-minibuffer
                 dg-js
                 dg-kbd
                 dg-tabs
                 dg-mu4e
                 dg-misc
                 dg-numpad
                 dg-sc-defun
                 dg-selenium
                 dg-jabber
                 ))

(mapcar (lambda (it)
          (message "    ****Loading %s****    " it)
          (require it))
        dg-files)

(load "customize.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "themes.el" 'noerror)

(provide 'init)
