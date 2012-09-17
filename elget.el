;; set up el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil t)
  (with-current-buffer
      (url-retrieve-synchronously "https://raw.github.com/dimitri/el-get/master/el-get-install.el")
    (end-of-buffer)
    (eval-print-last-sexp)))

;; custom local sources
(setq el-get-sources
      '((:name tumblr-mode
               :type git
               :url "http://github.com/qxj/tumblr-mode.git"
               :features (tumblr-mode))
        ;; (:name org-jira
        ;;        :type git
        ;;        :url "git@github.com:gempesaw/org-jira.git"
        ;;        :features (org-jira))
        (:name ido-ubiquitous
               :type git
               :url "https://github.com/technomancy/ido-ubiquitous"
               :features (ido-ubiquitous))
        (:name mark-multiple
               :type git
               :url "https://github.com/magnars/mark-multiple.el.git"
               :features (mark-more-like-this))
        (:name expand-region
               :type git
               :url "https://github.com/magnars/expand-region.el.git"
               :features (expand-region))
        (:name yasnippet
               :type git
               :url "https://github.com/capitaomorte/yasnippet.git"
               :pkgname "capitaomorte/yasnippet"
               :features "yasnippet"
               :compile "yasnippet.el")
        (:name smart-compile
               :type emacswiki
               :website "http://emacswiki.org/emacs/smart-compile.el")
        (:name web-mode
               :type git
               :url "https://github.com/fxbois/web-mode.git"
               :features (web-mode))
        ;; (:name
        ;;        :type git
        ;;        :url ""
        ;;        :features ())
      ))

(setq my-packages
      (append
       '(;; el-get
         ack
         browse-kill-ring
         coffee-mode
         cperl-mode
         json
         ;; js2-mode
         magit
         markdown-mode
         regex-tool
         ;; mode-compile
         ;; php-mode-improved
         ;; smart-compile
         ;; typing
         unbound
         win-switch
         )
       (mapcar 'el-get-source-name el-get-sources)))

(el-get 'sync my-packages)
