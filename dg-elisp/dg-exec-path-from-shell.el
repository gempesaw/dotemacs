;; (when (fboundp 'nvm-use) (nvm-use "v8.4.0"))


(when (file-exists-p "~/.nvm")
  (require 'nvm)
  (nvm-use "10.6.0")

  (when (not (string-equal system-type "windows-nt"))
    (setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
    (setq exec-path (append exec-path '("/usr/local/bin")))
    (when (getenv "PERL5LIB")
      (ignore-errors (exec-path-from-shell-copy-env "PERL5LIB"))))

  (when (string-equal system-type "windows-nt")
    (setenv "PATH" "C:\\ProgramData\\Oracle\\Java\\javapath;C:\\WINDOWS\\system32;C:\\WINDOWS;C:\\WINDOWS\\System32\\Wbem;C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\;C:\\Program Files (x86)\\ATI Technologies\\ATI.ACE\\Core-Static;C:\\Program Files (x86)\\Skype\\Phone\\;C:\\Strawberry\\c\\bin;C:\\Strawberry\\perl\\site\\bin;C:\\Strawberry\\perl\\bin;C:\\Program Files\\Git\\cmd;C:\\Program Files\\Git\\mingw64\\bin;C:\\Program Files\\Git\\usr\\bin;C:\\emacs\\bin;C:\\Program Files\\nodejs\\;C:\\Program Files (x86)\\AMD\\ATI.ACE\\Core-Static;C:\\Users\\Daniel\\AppData\\Roaming\\npm"))
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
  )


(provide 'dg-exec-path-from-shell)
