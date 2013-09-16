(add-to-list 'load-path "~/.emacs.d/")

(setq dg-files '(
                 dg-load-my-packages    ;; load all the necessary packages
                 dg-override-keys       ;; needs to be first so other files can use it
                 dg-passwords           ;; needs to be first so other files can use it
                 dg-defun
                 dg-elisp-macros
                 dg-jabber
                 dg-js
                 dg-kbd
                 dg-minibuffer
                 dg-misc
                 dg-mu4e
                 dg-numpad
                 dg-sc-defun
                 dg-selenium
                 dg-tabs
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
