(use-package typescript-mode
  :ensure t
  :hook (typescript-mode . lsp-deferred)
  :config
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))
  ;; (add-hook 'typescript-mode-hook 'tide-mode)
  (setq tide-format-options '(:indentSize 2))
  )

(use-package tide
  :ensure t)





(provide 'dg-typescript)
