(add-to-list 'load-path "~/.emacs.d/")
;; (byte-recompile-directory (expand-file-name "~/.emacs.d/elpa/") 0 t)

(setq dg-files '(
                 dg-load-my-packages    ;; load all the necessary packages
                 dg-override-keys       ;; needs to be first so other files can use it
                 dg-passwords           ;; needs to be first so other files can use it
                 dg-defun
                 dg-elisp-macros
                 dg-fullscreen
                 dg-jabber
                 dg-js
                 dg-kbd
                 dg-minibuffer
                 dg-misc
                 dg-mu4e
                 dg-numpad
                 dg-sc
                 dg-selenium
                 dg-tabs
                 dg-tramp
                 ))

(mapcar (lambda (it)
          (if (file-exists-p (concat "~/.emacs.d/" (symbol-name it) ".el"))
              (progn (message "    ****Loading %s****    " it)
                     (require it))
            (message "____****MISSING: %s****____" it)))
        dg-files)

(load "customize.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)

(provide 'init)
