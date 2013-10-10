(add-to-list 'load-path "~/.emacs.d/")
;; (byte-recompile-directory (expand-file-name "~/.emacs.d/elpa/") 0 t)

(setq dg-files
      (delq nil (delete-dups              ;; remove duplicates
                 (append
                  '(
                    "dg-load-my-packages" ;; load melpa/marmalade packages
                    "dg-override-keys"    ;; needs to be first so other files can use it
                    "dg-passwords"        ;; needs to be first so other files can use it
                    )
                  (mapcar
                   (lambda (it)           ;; and append any dg-* files in this folder
                     (substring it 0 -3))
                   (file-expand-wildcards "dg-*.el"))))))

(mapcar (lambda (it)
          (if (file-exists-p (concat "~/.emacs.d/" it ".el"))
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
