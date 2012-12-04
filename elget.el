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
(package-initialize)

;; custom local sources
(setq el-get-sources
      '(
	(:name simple-httpd
	       :type git
	       :url "https://github.com/skeeto/emacs-http-server.git"
	       :features (simple-httpd))
	(:name impatient-mode
	       :type git
	       :url "https://github.com/netguy204/imp.el.git"
	       :features (impatient-mode))
	(:name switch-window
	       :type git
	       :url "https://github.com/gempesaw/switch-window.git"
	       :features (switch-window))
	(:name js2-mode
	       :type git
	       :url "git://github.com/mooz/js2-mode.git"
	       :features (js2-mode))
      ))

(setq my-packages
      (append
       '(;; el-get
	 ace-jump-mode
	 ack
	 browse-kill-ring
	 coffee-mode
	 cperl-mode
	 emacs-w3m
	 exec-path-from-shell
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
	 smex
	 win-switch
	 wgrep
	 yasnippet
	 zencoding-mode
	 )
       (mapcar 'el-get-source-name el-get-sources)))

;; (el-get-emacswiki-build-local-recipes)
;; (el-get-elpa-build-local-recipes)
(el-get 'sync my-packages)
