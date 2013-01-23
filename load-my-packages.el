(require 'package)
(require 'cl)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)
(package-initialize)

(defvar my-packages
  '(
    ace-jump-mode
    ack
    autopair
    browse-kill-ring
    cperl-mode
    dash
    dired-details
    diminish
    elisp-slime-nav

    exec-path-from-shell
    expand-region
    htmlize
    impatient-mode
    ido-ubiquitous
    ir-black-theme
    js2-mode
    magit
    markdown-mode
    multiple-cursors
    powerline
    regex-tool
    simple-httpd
    smex
    switch-window
    w3m
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
      (package-install p)))))

(package-initialize)
