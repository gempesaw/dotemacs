(add-to-list 'load-path "~/.emacs.d/")
;; (byte-recompile-directory (expand-file-name "~/.emacs.d/elpa/") 0 t)

(defvar dg-package-list nil
  "My customization files, split into different files!")

(let* ((dg-first-packages '(
                            "dg-load-my-packages"
                            "dg-override-keys"
                            "dg-elisp-macros"
                            ))
       (dg-all-packages (mapcar (lambda (it)
                                  (substring it 11 -3))
                                (file-expand-wildcards "~/.emacs.d/dg-*.el")))
       (dg-last-packages '(
                           "dg-modes"
                           "dg-diminish"))

       (dg-other-packages))
  (mapc (lambda (it)
          (setq dg-other-packages (delete it dg-all-packages)))
        (append dg-first-packages dg-last-packages))
  (setq dg-package-list (append dg-first-packages
                                dg-other-packages
                                dg-last-packages)))

(mapcar (lambda (it)
          (unless (require (intern it))
            (message "____****MISSING: %s****____" it)))
        dg-package-list)

(load "customize.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
;; (load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "my-macros.el" 'noerror)
