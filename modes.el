;; enable desktop saving for buffer restore
(desktop-save-mode 1)


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
(setq ido-enable-flex-matching t) ; fuzzy matching is a must have
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere
