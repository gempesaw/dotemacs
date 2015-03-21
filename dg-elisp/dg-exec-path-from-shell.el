(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setenv "NODE_PATH" (concat (getenv "NODE_PATH") "/Usr/Local/lib/node_modules"))
(setq exec-path (append exec-path '("/usr/local/bin")))
(when (getenv "PERL5LIB")
  (ignore-errors (exec-path-from-shell-copy-env "PERL5LIB")))

;;; reset the path if necessary
;; (setq exec-path '("/usr/local/bin"
;;                   "/usr/local/opt/android-sdk/tools"
;;                   "/usr/local/opt/android-sdk/platform-tools"
;;                   "/opt/dev_hdew/browsermob-proxy/bin"
;;                   "/Users/dgempesaw/.jenv/bin"
;;                   "/Users/dgempesaw/perl5/bin"
;;                   "/usr/bin"
;;                   "/bin"
;;                   "/usr/sbin"
;;                   "/sbin"
;;                   "/usr/local/bin"
;;                   "/opt/X11/bin"
;;                   "/usr/texbin"
;;                   "/Users/dgempesaw/.rvm/bin"))

(provide 'dg-exec-path-from-shell)
