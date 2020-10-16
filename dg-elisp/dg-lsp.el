(eval-after-load 'lsp
  '(progn
     (setq lsp-print-io nil
           lsp-ui-doc-enable nil)
     (add-hook 'lsp-after-open-hook 'lsp-enable-imenu)

     (define-key lsp-mode-map (kbd "C-c C-l") lsp-command-map)
     (define-key lsp-mode-map (kbd "s-l") nil)

     (push 'company-lsp company-backends)
     (define-key lsp-ui-mode-map [remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
     (define-key lsp-ui-mode-map [remap xref-find-references] #'lsp-ui-peek-find-references)

     ;; elixir puts its deps here, but we don't want to watch them
     (push "[/\\\\]deps$" lsp-file-watch-ignored)
     (push "[/\\\\]\\.elixir_ls$" lsp-file-watch-ignored)
     (push "[/\\\\]_build$" lsp-file-watch-ignored)))



(provide 'dg-lsp)
