
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;(package-initialize)

(load "~/.emacs.d/emacs-custom.el" 'noerror)

(add-to-list 'load-path "~/.emacs.d/dg-elisp/")
(add-to-list 'load-path "~/.emacs.d/js-align/")
(add-to-list 'load-path "~/.emacs.d/swagger-jsdoc-edit/")
;; (byte-recompile-directory (expand-file-name "~/.emacs.d/elpa/") 0 t)

(defvar dg-package-list nil
  "My customization files, split into different files!")

(let* ((dg-first-packages '(
                            "dg-load-my-packages"
                            "dg-override-keys"
                            "dg-elisp-macros"
                            ))
       (dg-all-packages (mapcar (lambda (it)
                                  (substring it 20 -3))
                                (file-expand-wildcards "~/.emacs.d/dg-elisp/dg-*.el")))
       (dg-last-packages '(
                           "dg-modes"
                           "dg-diminish"))

       (dg-other-packages '("js-align"
                            "swagger-jsdoc-edit")))
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

(load "~/.emacs.d/customize.el" 'noerror)
(load "~/.emacs.d/defadvice.el" 'noerror)
;; (load "~/.emacs.d/feature-mode.el")
(load "~/.emacs.d/hooks.el" 'noerror)
(load "~/.emacs.d/my-macros.el" 'noerror)
