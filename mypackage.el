(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)

(package-initialize)

;; from http://batsov.com/articles/2012/02/19/package-management-in-emacs-the-good-the-bad-and-the-ugly/
(defvar my-melpa-packages
  '(htmlize
    impatient-mode
    popup
    simple-httpd
  "A list of packages to ensure are installed at launch.")

(defun my-melpa-packages-installed-p ()
  (loop for p in my-melpa-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(unless (my-melpa-packages-installed-p)
  ;; check for new packages (package versions)
  (message "%s" "Emacs Prelude is now refreshing its package database...")
  (package-refresh-contents)
  (message "%s" " done.")
  ;; install the missing packages
  (dolist (p my-melpa-packages)
    (when (not (package-installed-p p))
      (package-install p))))

(provide 'my-melpa-packages)
;;; my-melpa-packages.el ends here
