(add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))

(add-hook 'typescript-mode-hook 'tide-mode)

(setq tide-format-options '(:indentSize 2))

(provide 'dg-typescript)
