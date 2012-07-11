;; enable desktop saving for buffer restore
(desktop-save-mode 1)

;; magit svn inclusion
(require 'magit-svn)

;; winner mode
(when (fboundp 'winner-mode)
  (winner-mode 1))

;; erc setup
(require 'erc-match)
(setq erc-keywords '("resolve" "dgempesaw"))

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

;; ido mode
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere
(setq ido-enable-prefix nil
      ido-enable-flex-matching t ; fuzzy matching is a must have
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10
      ido-default-file-method 'selected-window)

(add-to-list 'ido-ignore-directories "target")
(add-to-list 'ido-ignore-directories "node_modules")

;; Use ido everywhere
(ido-ubiquitous 1)

;; auto-completion in minibuffer
(icomplete-mode +1)

;; delete the selection with a keypress
(delete-selection-mode t)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; saveplace remembers your location in a file when saving files
(setq save-place-file (concat user-emacs-directory "saveplace"))
;; activate it for all buffers
(setq-default save-place t)
(require 'saveplace)

;; smart pairing for all
(electric-pair-mode t)

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

(load "passwords.el")
