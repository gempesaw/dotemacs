(push 'company-robe company-backends)
(add-hook 'ruby-mode-hook 'robe-mode)
(add-hook 'ruby-mode-hook 'company-mode)

(progn
  (rvm-use-default)

  (setq company-idle-delay 0)

  (defadvice inf-ruby-console-auto (before activate-rvm-for-robe activate)
    (rvm-activate-corresponding-ruby))

  (global-set-key (kbd "C-<tab>") 'company-complete))

(provide 'dg-ruby)
