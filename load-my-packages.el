(require 'package)
(require 'cl)
(require 'tramp)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(package-initialize)

(defvar my-packages '() "A list of packages to ensure are installed at launch.")

(setq my-packages '(
                    ace-jump-mode
                    ack-and-a-half
                    assemblage-theme
                    browse-kill-ring
                    cl-lib
                    cperl-mode
                    circe
                    dash
                    dired-details
                    flx-ido
                    elisp-slime-nav
                    exec-path-from-shell
                    expand-region
                    gist
                    htmlize
                    ido-ubiquitous
                    impatient-mode
                    jabber
                    js2-mode
                    key-chord
                    magit
                    markdown-mode
                    multiple-cursors
                    offlineimap
                    paredit
                    php-mode
                    regex-tool
                    s
                    simple-httpd
                    skewer-mode
                    smart-tab
                    smex
                    switch-window
                    tumblesocks
                    wgrep
                    wrap-region
                    yasnippet
                    ))

(defun my-packages-installed-p (list-of-packages)
  (loop for p in list-of-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(defun load-my-packages (list-of-packages)
  (let ((old-archives package-archives))
    (save-window-excursion
      (unless (my-packages-installed-p list-of-packages)
        (package-refresh-contents)
        (dolist (p list-of-packages)
          (if (not (package-installed-p p))
              (progn
                (package-install p)
                (require p)))))
      (setq package-archives old-archives))
    (dolist (p list-of-packages) (require p))))

(load-my-packages my-packages)

(package-initialize)

;; manually load some packages
(load "smart-compile.el" 'noerror)
