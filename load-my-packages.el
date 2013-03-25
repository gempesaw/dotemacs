(require 'package)
(require 'cl)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(package-initialize)

(defvar my-packages
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
    gist
    htmlize
    impatient-mode
    ido-ubiquitous
    ir-black-theme
    jabber
    js2-mode
    magit
    markdown-mode
    multiple-cursors
    php-mode
    regex-tool
    scala-mode2
    simple-httpd
    smex
    switch-window
    tumblesocks
    wgrep
    yasnippet)
  "A list of packages to ensure are installed at launch.")

(defun my-packages-installed-p ()
  (loop for p in my-packages
        when (not (package-installed-p p)) do (return nil)
        finally (return t)))

(save-window-excursion (unless (my-packages-installed-p)
                         ;; check for new packages (package versions)
                         (message "%s" "Emacs Prelude is now refreshing its package database...")
                         (package-refresh-contents)
                         (message "%s" " done.")
                         ;; install the missing packages
                         (dolist (p my-packages)
                           (when (not (package-installed-p p))
                             (package-install p)
                             (require p)))))

(package-initialize)


(dolist (p my-packages) (require p))
