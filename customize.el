;; No splash screen please ... jeez
(setq inhibit-startup-message t)

;; disable mouse scrolling
(setq mouse-wheel-scroll-amount '(1))
(setq mouse-wheel-progressive-speed nil)

;; I never use downcase-region
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; Small fringes
(set-fringe-mode '(1 . 1))

;; Explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; Make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Various superfluous white-space. Just say no.
(add-hook 'before-save-hook 'cleanup-buffer-safe)

;; Trash can support
(setq delete-by-moving-to-trash t)

;; faster keystroke echoes
(setq echo-keystrokes 0.1)

;; get gpg into the path
(add-to-list 'exec-path "/usr/bin")
(add-to-list 'exec-path "/usr/local/bin")
(setq epg-gpg-program "/usr/local/bin/gpg")

;; uniquify options
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-strip-common-suffix 'nil)

(setq custom-file "~/.emacs.d/emacs-custom.el")

(eval-after-load "saveplace"
  '(progn
     ;; saveplace remembers your location in a file when saving files
     (setq save-place-file (concat user-emacs-directory "saveplace"))
     ;; activate it for all buffers
     (setq-default save-place t)))

;; automatically save buffers when finishing a wgrep session
(setq wgrep-auto-save-buffer t)

;; use the cool js2-mode from yegge and mooz
(autoload 'js2-mode "js2-mode" nil t)

;; explicitly state bookmarks
(setq bookmarks-default-file "~/.emacs.d/bookmarks")

;; tumblesocks
(setq tumblesocks-blog "eval-defun.tumblr.com")
(setq tumblesocks-post-default-state "queue")
(if (require 'sasl nil t)
    (setq oauth-nonce-function #'sasl-unique-id)
  (setq oauth-nonce-function #'oauth-internal-make-nonce))

;; Also auto refresh dired, but be quiet about it
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)

(put 'narrow-to-region 'disabled nil)

;;; split to side-by-side if it'll leave the remaining windows at least 125 wide
(setq split-height-threshold nil
      split-width-threshold 125)

(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(delete '("\\.js\\'" . js-mode) auto-mode-alist)
(delete '("\\.t$'" . cperl-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.t$" . cperl-mode))
(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
(setq auto-mode-alist (cons '("\\.tag$" . html-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.out$" . auto-revert-tail-mode) auto-mode-alist))

;; dired - reuse current buffer by pressing 'a'
(put 'dired-find-alternate-file 'disabled nil)

;; term face settings
(setq term-default-bg-color nil)

(setq ensime-sbt-compile-on-save nil)

(setq iedit-toggle-key-default nil)

(set-face-attribute 'default nil :family "Monaco" :height 120 :weight 'normal)
