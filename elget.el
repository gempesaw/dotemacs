;; set up el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil t)
  (with-current-buffer
      (url-retrieve-synchronously "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
    (end-of-buffer)
    (eval-print-last-sexp)))

;; use marmalade
(add-to-list 'package-archives
	     '("melpa" . "http://melpa.milkbox.net/packages/") t)

;; custom local sources
(setq el-get-sources
      '((:name tumblr-mode
	       :type git
	       :url "http://github.com/qxj/tumblr-mode.git"
	       :features (tumblr-mode))
      ))

(setq my-packages
      (append
       '(;; el-get
	 ack
	 autopair
	 browse-kill-ring
	 coffee-mode
	 cperl-mode
	 expand-region
	 htmlize
	 ido-ubiquitous
	 json
	 magit
	 markdown-mode
	 multiple-cursors
	 powerline
	 popup
	 regex-tool
	 smart-compile
	 yasnippet
	 win-switch
	 zencoding-mode
	 )
       (mapcar 'el-get-source-name el-get-sources)))

;; (el-get-emacswiki-build-local-recipes)
;; (el-get-elpa-build-local-recipes)
(el-get 'sync my-packages)
