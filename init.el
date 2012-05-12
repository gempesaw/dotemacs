;; el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get") (unless (require 'el-get nil t) (with-current-buffer (url-retrieve-synchronously "https://raw.github.com/dimitri/el-get/master/el-get-install.el") (end-of-buffer) (eval-print-last-sexp))) (el-get 'sync)

;; disable menu and toolbar
(menu-bar-mode 0)
(tool-bar-mode 0)

;; disable mouse scrolling
(setq mouse-wheel-scroll-amount '(1))
(setq mouse-wheel-progressive-speed nil)

;; enable desktop saving for buffer restore
(desktop-save-mode 1)

;; make OS X command button meta
(setq mac-option-key-is-meta nil)
(setq mac-command-key-is-meta t)
(setq mac-command-modifier 'meta)
(setq mac-option-modifier nil)

;; set up previous window as C-x p (like C-x o)
(defun back-window () (interactive) (other-window -1))
(global-set-key (kbd "C-x p") 'back-window)

;; toggle full screen key chord
(global-set-key (kbd "M-RET") 'ns-toggle-fullscreen)

;; rename buffer key chord
(global-set-key (kbd "C-c r") 'rename-buffer)

;; magit status key chord
(global-set-key (kbd "M-g M-s") 'magit-status)

;; start in full screen
(ns-toggle-fullscreen)

;; shortcut for revert buffer
(global-set-key (kbd "C-x r") 'revert-buffer)

;; winner mode
(when (fboundp 'winner-mode)
  (winner-mode 1))

;; macro and shortcut to set up in 3 wide, last split window organization
(fset 'startupConfig
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([24 51 24 51 24 112 24 50 24 111 24 50 24 48 24 43 134217848 115 104 101 108 108 return 24 111 24 98 104 111 110 101 121 100 101 119 46 112 108 return 24 112 24 112 24 98 72 111 110 101 121 68 101 119 46 112 109 return 24 112 24 98 100 101 102 97 117 108 116 46 112 109 return] 0 "%d")) arg)))
(global-set-key (kbd "C-x c f g") 'startupConfig)

;; tramp settings
(setq tramp-default-method "ssh")
(setq tramp-auto-save-directory "~/tmp/tramp/")
(setq tramp-chunksize 2000)

;; get gpg into the path
(add-to-list 'exec-path "/usr/bin")
(add-to-list 'exec-path "/usr/local/bin")
(setq epg-gpg-program "/usr/local/bin/gpg")

;; I never use downcase-region
(put 'downcase-region 'disabled nil)

;; erc setup
(require 'erc-match)
(setq erc-keywords '("resolve" "dgempesaw"))

;; Easier buffer killing
(global-unset-key (kbd "M-k"))
(global-set-key (kbd "M-k") 'kill-this-buffer)

;; Easier window closing
(global-unset-key (kbd "M-0"))
(global-set-key (kbd "M-0") 'delete-window)

;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)
(setq cperl-invalid-face (quote off))
(setq cperl-electric-keywords t)
(setq cperl-indent-level 4)
(setq cperl-continued-statement-offset 0)
(setq cperl-extra-newline-before-brace t)

(add-hook 'cperl-mode-hook
  (lambda()
    (local-set-key (kbd "C-c C-k") 'hs-show-block)
    (local-set-key (kbd "C-c C-j") 'hs-hide-block)
    (local-set-key (kbd "C-c C-p") 'hs-hide-all)
    (local-set-key (kbd "C-c C-n") 'hs-show-all)
    (hs-minor-mode t)))


(add-hook 'cperl-mode-hook
    (lambda () (subword-mode 1)))

;; Don't show the startup screen
(setq inhibit-startup-message t)

;; "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; Display line and column numbers
(setq line-number-mode    t)
(setq column-number-mode  t)

;; Modeline info
(display-time-mode 1)
(display-battery-mode 1)

;; Small fringes
(set-fringe-mode '(1 . 1))

;; Emacs gurus don't need no stinking scroll bars
(when (fboundp 'toggle-scroll-bar)
  (toggle-scroll-bar -1))

;; Explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; Prevent the annoying beep on errors
;; (setq visible-bell t)

;; Make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Gotta see matching parens
(show-paren-mode t)

;; Trailing whitespace is unnecessary
(add-hook 'before-save-hook (lambda () (whitespace-cleanup)))

;; Trash can support
(setq delete-by-moving-to-trash t)

;; `brew install aspell --lang=en` (instead of ispell)
(setq-default ispell-program-name "aspell")
(setq ispell-list-command "list")
(setq ispell-extra-args '("--sug-mode=ultra"))


;; smart tab
;;; Tab management

;; Spaces instead of tabs
(setq-default indent-tabs-mode nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hippie expand.  Groovy vans with tie-dyes.

(setq hippie-expand-try-functions-list
      '(yas/hippie-try-expand
  try-expand-dabbrev
  try-expand-dabbrev-all-buffers
  try-expand-dabbrev-from-kill
  try-complete-file-name
  try-complete-lisp-symbol))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Smart Tab
;; Borrowed from snippets at
;; http://www.emacswiki.org/emacs/TabCompletion
;; TODO: Take a look at https://github.com/genehack/smart-tab

(defvar smart-tab-using-hippie-expand t
  "turn this on if you want to use hippie-expand completion.")

(defun smart-tab (prefix)
  "Needs `transient-mark-mode' to be on. This smart tab is
  minibuffer compliant: it acts as usual in the minibuffer.

  In all other buffers: if PREFIX is \\[universal-argument], calls
  `smart-indent'. Else if point is at the end of a symbol,
  expands it. Else calls `smart-indent'."
  (interactive "P")
  (labels ((smart-tab-must-expand (&optional prefix)
	  (unless (or (consp prefix)
		mark-active)
	    (looking-at "\\_>"))))
    (cond ((minibufferp)
     (minibuffer-complete))
    ((smart-tab-must-expand prefix)
     (if smart-tab-using-hippie-expand
	 (hippie-expand prefix)
       (dabbrev-expand prefix)))
    ((smart-indent)))))

(defun smart-indent ()
  "Indents region if mark is active, or current line otherwise."
  (interactive)
  (if mark-active
    (indent-region (region-beginning)
       (region-end))
    (indent-for-tab-command)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global-set-key (kbd "TAB") 'smart-tab)


;; ido mode
(setq ido-enable-flex-matching t) ; fuzzy matching is a must have
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere
