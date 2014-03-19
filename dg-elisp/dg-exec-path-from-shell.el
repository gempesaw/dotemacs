(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setenv "NODE_PATH" (concat (getenv "NODE_PATH") "/Usr/Local/lib/node_modules"))
(setq exec-path (append exec-path '("/usr/local/bin")))
(exec-path-from-shell-copy-env "PERL5LIB")

(provide 'dg-exec-path-from-shell)
