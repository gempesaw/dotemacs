(use-package flycheck
  :ensure t
  :config
  (setq-default flycheck-disabled-checkers (append flycheck-disabled-checkers '(javascript-jshint)))
  (setq flycheck-temp-prefix ".flycheck"))
