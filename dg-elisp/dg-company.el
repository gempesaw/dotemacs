(require 'company)
(require 'company-go)

(setq company-idle-delay .275
      company-minimum-prefix-length 2
      company-tooltip-limit 20
      company-echo-delay 0
      company-begin-commands '(self-insert-command))

(add-hook 'after-init-hook 'global-company-mode)

(provide 'dg-company)
