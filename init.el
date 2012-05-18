;; el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get") (unless (require 'el-get nil t) (with-current-buffer (url-retrieve-synchronously "https://raw.github.com/dimitri/el-get/master/el-get-install.el") (end-of-buffer) (eval-print-last-sexp))) (el-get 'sync)

;; tramp settings
(setq tramp-default-method "ssh")
(setq tramp-auto-save-directory "~/tmp/tramp/")
(setq tramp-chunksize 2000)

;; get gpg into the path
(add-to-list 'exec-path "/usr/bin")
(add-to-list 'exec-path "/usr/local/bin")
(setq epg-gpg-program "/usr/local/bin/gpg")

;; start in full screen
;; (ns-toggle-fullscreen)

(add-to-list 'load-path "~/.emacs.d/")
(load "customize.el")
(load "kbd.el")
(load "modes.el")
(load "tabs.el")
