(use-package lsp-ui
  :ensure t)

(use-package lsp-mode
  :requires (lsp-ui)
  :ensure t
  :bind (:map lsp-mode-map
              ("C-c C-l" . lsp-command-map)
              ("s-l" . nil))

  :config
  (setq lsp-client-packages (delq 'lsp-ts-query lsp-client-packages))

  (setq lsp-keymap-prefix "s-i")

  ;; we use corfu + capf, not company. skip lsp-mode's company autoconfig
  ;; so it stops warning "Unable to autoconfigure company-mode."
  (setq lsp-completion-provider :none)

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

  (push "[/\\\\]node_modules$" lsp-file-watch-ignored)
  (push "[/\\\\].venv$" lsp-file-watch-ignored)
  (push "[/\\\\]deps$" lsp-file-watch-ignored)

  (push "[/\\\\]\\.venv\\" lsp-file-watch-ignored-directories)
  (push "[/\\\\]venvs" lsp-file-watch-ignored-directories)
  (push "[/\\\\]\\.ruff_cache\\" lsp-file-watch-ignored-directories)
  )
