(push 'company-robe company-backends)
(add-hook 'ruby-mode-hook 'robe-mode)
(add-hook 'ruby-mode-hook 'company-mode)
;; (add-hook 'ruby-mode-hook 'flycheck-mode)
(add-hook 'ruby-mode-hook 'projectile-rails-on)

(add-hook 'coffee-mode-hook 'projectile-rails-on)

(setq coffee-tab-width 2)

(defun disable-electric-indent ()
  (set (make-local-variable 'electric-indent-functions)
       (list (lambda (arg) 'no-indent))))

(add-hook 'coffee-mode-hook 'disable-electric-indent)
(eval-after-load 'projectile-rails
  (progn
    (rvm-use-default)

    (setq company-idle-delay 0)

    (defadvice inf-ruby-console-auto (before activate-rvm-for-robe activate)
      (rvm-activate-corresponding-ruby))

    (global-set-key (kbd "C-<tab>") 'company-complete)
    (key-chord-define projectile-rails-mode-map "jk" 'projectile-rails-command-map)))

(provide 'dg-ruby)
