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
       '(el-get
         cperl-mode
         crontab-mode
         cssh
         ;; switch-window
         magit
         php-mode-improved)
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
