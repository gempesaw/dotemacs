(use-package tree-sitter
  :ensure t)

(use-package tree-sitter-langs
  :requires (tree-sitter)
  :ensure t
  :config
  (add-to-list 'treesit-extra-load-path (f-expand "~/opt/tree-sitter-module/dist"))
  )
