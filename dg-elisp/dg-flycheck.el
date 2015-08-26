(require 'flycheck)

(setq-default flycheck-disabled-checkers
              (append flycheck-disabled-checkers
                      '(javascript-jshint)))

(setq flycheck-temp-prefix ".flycheck")

(add-hook 'js2-mode-hook 'flycheck-mode)

(provide 'dg-flycheck)
