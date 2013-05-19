(require 'package)
(require 'cl)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ;; ("melpa" . "http://melpa.milkbox.net/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))
(package-initialize)

(defvar my-packages '() "A list of packages to ensure are installed at launch.")
(defvar my-melpa-packages '() "A list of MELPA packages (not available on marmalade)")

(setq my-melpa-packages
      '(
        impatient-mode
        php-mode
        scala-mode2
        simple-httpd
        smartparens
        switch-window
        ))

(setq my-packages
      '(
        ace-jump-mode
        ack-and-a-half
        browse-kill-ring
        cperl-mode
        circe
        dash
        dired-details
        elisp-slime-nav
        elpy
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
        offlineimap
        regex-tool
        smex
        tumblesocks
        wgrep
        yasnippet))

(defun my-packages-installed-p (list-of-packages)
  (loop for p in list-of-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(defun load-my-packages (list-of-packages source)
  (let ((old-archives package-archives))
    (save-window-excursion
      (unless (my-packages-installed-p list-of-packages)
        (if (eq source 'melpa)
            (setq package-archives '(("melpa" . "http://melpa.milkbox.net/packages/"))))
        (package-refresh-contents)
        (dolist (p list-of-packages)
          (if (not (package-installed-p p))
              (progn
                (package-install p)
                (require p)))))
      (setq package-archives old-archives))
    (dolist (p list-of-packages) (require p))))

(load-my-packages my-packages 'marmalade)
(load-my-packages my-melpa-packages 'melpa)

(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lewang-flx/")
(require 'flx-ido)
