;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)
(setq cperl-invalid-face (quote off))
(setq cperl-electric-keywords t)
(setq cperl-indent-level 4)
(setq cperl-continued-statement-offset 0)
(setq cperl-extra-newline-before-brace t)
(setq cperl-indent-parens-as-block t)
(setq cperl-lazy-help-time 0.01)

(cperl-lazy-install)

(provide 'dg-cperl)
