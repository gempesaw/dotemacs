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
               :features (mark-multiple))
        (:name expand-region
               :type git
               :url "https://github.com/magnars/expand-region.el.git"
               :features (expand-region))

        ;; (:name
        ;;        :type git
        ;;        :url ""
        ;;        :features ())
      )
)

(setq my-packages
      (append
       '(;; el-get
         ack
         browse-kill-ring
         cperl-mode
         json
         magit
         markdown-mode
         mode-compile
         ;; php-mode-improved
         typing
         unbound
         )
       (mapcar 'el-get-source-name el-get-sources)))

(el-get 'sync my-packages)

;; load the child files
(add-to-list 'load-path "~/.emacs.d/")
(load "alias.el")
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
 '(custom-enabled-themes (quote (tango-dark)))
 '(custom-safe-themes (quote ("1d1e97c4804a04441b08226e4775295843baae033673e63513ae925eafcdc9bf" "d2622a2a2966905a5237b54f35996ca6fda2f79a9253d44793cfe31079e3c92b" "38784c7094a1df1cae422c86315318c33ec4c5da8d9646bebdc434ce83a70ecf" "66c133d8ee85853cbafb0fde95334057e61e9bb9dc7e3188a2389fb565efe6fd" "459e760e4d16ec11821721d9e39bf315116b2eb396bc0fd9e1e3f68a285ff82d" "183884e94bca3760f6e15e34106e3b21eda32868867e66c5db36be7ed5ed35ef" "ce1b305bc7613cd3ee298f1d8149e7565e87e19cebfaa4e6e91af46f1ad2d768" "0e14a39ac94df99f31f7110f2e806c52501e702ace9a6a6a24d3636904baa2f0" "83f0f087feac843259b3f6795b7a721995b48001f4303015c4d665a38f0c11ac" "b812e81cbf56a7b8326fec621e04eadcb4b3b723189bcaaee459c33cb47e5d3b" "3f833eb2a2da85f670c2c4efdfee4d58ac26d56016715361f57b71c943aa7701" "501caa208affa1145ccbb4b74b6cd66c3091e41c5bb66c677feda9def5eab19c" "6fb8d6a7208505c2e51466280e6abc4786e2f97c04698e605de857a1f533cd0a" default)))
 '(fci-rule-color "#eee8d5"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; TODO: refactor into a function?
;; start up selenium if possible.
(when (file-exists-p "/opt/selenium-server-standalone-2.25.0.jar")
     (shell-command "java -jar /opt/selenium-server-standalone-2.25.0.jar &")
     (set-buffer "*Async Shell Command*")
     (rename-buffer "selenium")
     (toggle-read-only))

(require 'cperl-mode)
(define-key cperl-mode-map (kbd "RET") 'newline-and-indent)
(cterm)
(define-key term-mode-map (kbd "C-'") 'term-char-mode)
(define-key term-raw-map (kbd "C-'") 'term-line-mode)
