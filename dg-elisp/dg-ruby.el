(push 'company-robe company-backends)
(add-hook 'ruby-mode-hook 'robe-mode)
(add-hook 'ruby-mode-hook 'company-mode)
(add-hook 'ruby-mode-hook 'flycheck-mode)
(add-hook 'ruby-mode-hook 'projectile-rails-on)

(eval-after-load 'projectile-rails
  (progn
    (rvm-use-default)

    (setq company-idle-delay 0)

    (defadvice inf-ruby-console-auto (before activate-rvm-for-robe activate)
      (rvm-activate-corresponding-ruby))

    (global-set-key (kbd "C-<tab>") 'company-complete)
    (key-chord-define projectile-rails-mode-map "jk" 'projectile-rails-command-map)))

(provide 'dg-ruby)
