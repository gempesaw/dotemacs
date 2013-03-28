(require 'package)
(require 'cl)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))
(package-initialize)

(defvar my-packages '() "A list of packages to ensure are installed at launch.")
(defvar my-melpa-packages '() "A list of MELPA packages (not available on marmalade)")

(setq my-melpa-packages
      '(
        impatient-mode
        ir-black-theme
        scala-mode2
        simple-httpd
        ))

(setq my-packages
      '(
        ace-jump-mode
        ack-and-a-half
        autopair
        browse-kill-ring
        cperl-mode
        circe
        dash
        dired-details
        elisp-slime-nav
        exec-path-from-shell
        expand-region
        fetchmacs
        gist
        htmlize
        ido-ubiquitous
        jabber
        js2-mode
        magit
        markdown-mode
        multiple-cursors
        php-mode
        regex-tool
        smex
        switch-window
        tumblesocks
        wgrep
        yasnippet))

(defun my-packages-installed-p (list-of-packages)
  (loop for p in list-of-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(defun load-my-packages (list-of-packages source)
  (let ((temporary-package-archives package-archives))
    (save-window-excursion
      (unless (my-packages-installed-p list-of-packages)
        ;; check for new packages (package versions)
        (message "%s" "Refreshing package database...")
        (package-refresh-contents)
        (message "%s" " done.")

        (if (eq source 'melpa)
            (setq temporary-package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                                     ("melpa" . "http://melpa.milkbox.net/packages/")))
          ;; install the missing packages
          (dolist (p list-of-packages)
            (when (not (package-installed-p p))
              (package-install p)
              (require p))))))))

(load-my-packages my-packages 'marmalade)
(load-my-packages my-melpa-packages 'melpa)

(package-initialize)


(dolist (p my-packages) (require p))
