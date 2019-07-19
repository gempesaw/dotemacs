(require 'package)
(require 'cl)
(require 'tramp)
(desktop-clear)
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")
                         ("melpa-stable" . "http://stable.melpa.org/packages/")
                         ("elpy" . "http://jorgenschaefer.github.io/packages/")))

(defvar my-packages '() "A list of packages to ensure are installed at launch.")

(setq my-packages '(
                    ag
                    avy
                    browse-kill-ring
                    company
                    company-tern
                    dash
                    diminish
                    dired-subtree
                    dumb-jump
                    elisp-slime-nav
                    ensime
                    exec-path-from-shell
                    expand-region
                    f
                    fancy-narrow
                    flycheck
                    ggtags
                    gist
                    git-timemachine
                    gradle-mode
                    groovy-mode
                    grunt
                    htmlize
                    httprepl
                    ido-completing-read+ ;; needed for new magit
                    js2-mode
                    js2-refactor
                    key-chord
                    magit
                    magit-gitflow
                    markdown-mode
                    multiple-cursors
                    paredit
                    projectile
                    rainbow-mode
                    rainbow-delimiters
                    rjsx-mode
                    s
                    scss-mode
                    simple-httpd
                    smart-tab
                    smex
                    switch-window
                    tern
                    tumblesocks
                    tramp
                    typescript-mode
                    wgrep
                    which-key
                    wrap-region
                    yasnippet
                    yaml-mode
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

(defun write-personalization-templates (it)
  (let* ((package (symbol-name it))
         (dg-file (format "%s/.emacs.d/dg-%s.el" (getenv "HOME") package)))
    (unless (file-exists-p dg-file)
      (with-temp-file dg-file
        (insert (format "(provide 'dg-%s)" package))))))

;; (mapcar 'write-personalization-templates my-packages)

(load-my-packages my-packages)

(load "~/.emacs.d/fairyfloss-theme.el")
;; manually load some packages
(require 'smart-compile)

(provide 'dg-load-my-packages)
