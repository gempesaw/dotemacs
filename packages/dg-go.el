(use-package go-mode
  :ensure t
  :hook (go-mode . lsp-deferred)
  :config
  (add-hook 'go-ts-mode-hook 'lsp-deferred)

  (add-to-list 'auto-mode-alist '("\\.proto\\'" . go-mode))

  (->> "go env"
       (shell-command-to-string)
       (s-split "\n")
       (--map (s-split "=" it))
       (--filter (nth 1 it))
       (--map (list (nth 0 it) (s-replace "'" "" (nth 1 it))))
       (--map (if (s-starts-with? "GO" (nth 0 it))
                  (setenv (nth 0 it) (nth 1 it)))))

  )

;;; asdf plugin add golang
;;; asdf install golang 1.23.0
;;; go install golang.org/x/tools/gopls@latest
;;;
