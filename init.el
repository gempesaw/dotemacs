;; set up el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil t)
  (with-current-buffer
      (url-retrieve-synchronously "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
    (end-of-buffer)
    (eval-print-last-sexp)))

(setq el-get-sources
      '((:name tumblr-mode
             :type git
             :url "http://github.com/qxj/tumblr-mode.git"
             :features (tumblr-mode))))

(setq my-packages
      (append
       '(;; el-get
         cperl-mode
         ;; crontab-mode
         cssh
         ;; switch-window
         magit
         php-mode
         )
       (mapcar 'el-get-source-name el-get-sources)))

(el-get 'sync my-packages)

;; load the child files
(add-to-list 'load-path "~/.emacs.d/")
(load "customize.el")
(load "defun.el")
(load "kbd.el")
(load "modes.el")
(load "tabs.el")
(load "themes.el")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes (quote ("3f833eb2a2da85f670c2c4efdfee4d58ac26d56016715361f57b71c943aa7701" "501caa208affa1145ccbb4b74b6cd66c3091e41c5bb66c677feda9def5eab19c" "6fb8d6a7208505c2e51466280e6abc4786e2f97c04698e605de857a1f533cd0a" default)))
)
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
