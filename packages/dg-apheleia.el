(use-package apheleia
  :ensure t
  :demand t
  :after python
  :config
  (apheleia-global-mode +1)
  (add-to-list 'apheleia-mode-alist '(python-mode . (ruff-isort ruff)))
  (add-to-list 'apheleia-mode-alist '(python-ts-mode . (ruff-isort ruff)))

  (add-to-list 'apheleia-formatters '(ruff-isort "ruff" "check" "-n" "--select" "I" "--select" "F401" "--fix" "--fix-only" "--stdin-filename" filepath "-")))
