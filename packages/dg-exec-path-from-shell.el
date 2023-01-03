(use-package exec-path-from-shell
  :ensure t
  :config

  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "PATH")
  (setq exec-path (append exec-path `(,(concat (getenv "HOME") "/.emacs.d/elixir-ls/release")))))


