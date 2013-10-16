(add-to-list 'load-path "~/.emacs.d/")
;; (byte-recompile-directory (expand-file-name "~/.emacs.d/elpa/") 0 t)

(setq dg-files '(
                 "dg-load-my-packages" ;; load melpa/marmalade packages
                 "dg-override-keys"    ;; needs to be first so other files can use it
                 ))

(cd "~/")
(setq dg-files
      (delq nil
            (delete-dups (append dg-files
                                 (mapcar (lambda (it) (substring it 9 -3))
                                         (file-expand-wildcards ".emacs.d/dg-*.el"))))))

(mapcar (lambda (it)
          (message (if (require (intern it))
                       "    ****Loading %s****    "
                     "____****MISSING: %s****____")
                   it))
        dg-files)

(load "customize.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)
