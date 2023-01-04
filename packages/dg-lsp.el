(use-package lsp-ui
  :ensure t)

(use-package lsp-mode
  :requires (lsp-ui)
  :ensure t
  :bind (:map lsp-mode-map
              ("C-c C-l" . lsp-command-map)
              ("s-l" . nil))
  
  :config
  (setq lsp-keymap-prefix "s-i")
  (setq lsp-print-io nil
        lsp-ui-doc-enable nil)

  (setq lsp-ui-peek-enable t
        lsp-ui-sideline-enable t
        lsp-ui-imenu-enable nil
        lsp-ui-flycheck-enable t)


  ;; https://ianyepan.github.io/posts/emacs-ide/
  (setq lsp-ui-doc-enable nil)
  (setq lsp-ui-doc-header t)
  (setq lsp-ui-doc-include-signature t)
  (setq lsp-ui-doc-border (face-foreground 'default))
  (setq lsp-ui-sideline-show-code-actions t)
  (setq lsp-ui-sideline-delay 0.05)

  ;; (setq lsp-auto-guess-root t)
  (setq lsp-restart 'auto-restart)
  
  (define-key lsp-ui-mode-map [remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
  (define-key lsp-ui-mode-map [remap xref-find-references] #'lsp-ui-peek-find-references)
  
  (push "[/\\\\]node_modules$" lsp-file-watch-ignored)
  (push "[/\\\\]venv$" lsp-file-watch-ignored)
  (push "[/\\\\]deps$" lsp-file-watch-ignored)
  
  ;; elixir puts its deps here, but we don't want to watch them
  (push "[/\\\\]\\.elixir_ls$" lsp-file-watch-ignored)
  (push "[/\\\\]_build$" lsp-file-watch-ignored)
  )

