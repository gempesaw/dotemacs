;; some packages aren't autoloaded, unfortunately
(require 'dired-details)
(require 'ace-jump-mode)
(require 'switch-window)
(require 'powerline)
(require 'multiple-cursors)
(require 'simple-httpd)
(require 'elisp-slime-nav)
(require 'smart-compile)
(require 'dash)

;; enable desktop saving for buffer restore
(desktop-save-mode 1)

;; winner mode
(when (fboundp 'winner-mode)
  (winner-mode 1))

;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)
(setq cperl-invalid-face (quote off))
(setq cperl-electric-keywords t)
(setq cperl-indent-level 4)
(setq cperl-continued-statement-offset 0)
(setq cperl-extra-newline-before-brace t)
(setq cperl-indent-parens-as-block t)

(add-hook 'cperl-mode-hook
  (lambda()
    (local-set-key (kbd "C-c C-k") 'hs-show-block)
    (local-set-key (kbd "C-c C-j") 'hs-hide-block)
    (local-set-key (kbd "C-c C-p") 'hs-hide-all)
    (local-set-key (kbd "C-c C-n") 'hs-show-all)
    (hs-minor-mode t)))

;; ido mode
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere

;; Use ido everywhere
(ido-ubiquitous 1)

;; auto-completion in minibuffer
(icomplete-mode +1)

;; delete the selection with a keypress
(delete-selection-mode t)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; smart pairing for all
;; (electric-pair-mode t)

;; dired - reuse current buffer by pressing 'a'
(put 'dired-find-alternate-file 'disabled nil)

;; clean up obsolete buffers automatically
;; (require 'midnight)

;; the blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

;; tumblr-mode settings
(setq
 tumblr-email "gempesaw@gmail.com"
 tumblr-hostnames (quote ("danzorx.tumblr.com"))
 tumblr-retrieve-posts-num-total 5
)

;; passwords in a file not on github :p
(load "passwords.el" 'noerror)

;; org-jira mode
(setq jiralib-url "https://arnoldmedia.jira.com")

;; turn on html mode for .tag files
(setq auto-mode-alist (cons '("\\.tag$" . html-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.out$" . auto-revert-tail-mode) auto-mode-alist))

;; load my feature mode
(load "feature-mode.el")

(global-subword-mode t)

;; personal snippets
(setq yas-snippet-dirs
      '("~/.emacs.d/snippets"            ;; personal snippets
        "~/.emacs.d/el-get/yasnippet/snippets/"    ;; the default collection
        ))
(yas-global-mode 1)
(autopair-global-mode 1)

;; activate my minor mode to override keybindings
(my-keys-minor-mode 1)

(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

(eval-after-load "paredit"
  '(progn
     (put 'paredit-forward-delete 'delete-selection 'supersede)
     (put 'paredit-backward-delete 'delete-selection 'supersede)
     (put 'paredit-open-round 'delete-selection t)
     (put 'paredit-open-square 'delete-selection t)
     (put 'paredit-doublequote 'delete-selection t)
     (put 'paredit-newline 'delete-selection t)
     ))
