(use-package exec-path-from-shell
  :ensure t
  :config

  ;; (setenv "PATH" "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin")

  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "PATH")
  ;; (setenv "GOPATH" (format "%s/go" (getenv "HOME")))
  ;; (setq exec-path (append exec-path `(
  ;;                                     ,(concat (getenv "HOME") "/.emacs.d/.cache/lsp/elixir-ls/")
  ;;                                     ,(format "%s/bin" (getenv "GOPATH"))                                    )))
  (push "/opt/homebrew/bin" exec-path)
  (push "/opt/homebrew/sbin" exec-path)
  (push (f-expand "~/.asdf/shims/") exec-path)

  (setenv "PATH" (s-join ":" exec-path)))
