(use-package exec-path-from-shell
  :ensure t
  :config

  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "PATH")
  (setenv "GOPATH" (format "%s/go" (getenv "HOME")))
  (setq exec-path (append exec-path `(
                                      ,(concat (getenv "HOME") "/.emacs.d/.cache/lsp/elixir-ls/")
                                      ,(format "%s/bin" (getenv "GOPATH"))                                    )))
  (push "/opt/homebrew/bin" exec-path)
  (push (format "%s/.asdf/shims" (getenv "HOME")) exec-path)

  (setenv "PATH" (s-join ":" exec-path))
  )
