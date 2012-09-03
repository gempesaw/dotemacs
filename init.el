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
        (:name re-builder-x
               :type git
               :url "https://github.com/bsdf/re-builder-X.git"
               :features (re-builder))
        (:name yasnippet
               :type git
               :url "https://github.com/capitaomorte/yasnippet.git"
               :pkgname "capitaomorte/yasnippet"
               :features "yasnippet"
               :compile "yasnippet.el")
        (:name smart-compile
               :type emacswiki
               :website "http://emacswiki.org/emacs/smart-compile.el")
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
         ;; js2-mode
         magit
         markdown-mode
         ;; mode-compile
         ;; php-mode-improved
         ;; smart-compile
         ;; typing
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
(setq custom-file "emacs-custom.el")
(load custom-file 'noerror)

;; TODO: refactor into a function?
;; start up selenium if possible.
(if (eq nil (get-buffer "selenium"))
    (when (file-exists-p "/opt/selenium-server-standalone-2.25.0.jar")
      (shell-command "java -jar /opt/selenium-server-standalone-2.25.0.jar &")
      (set-buffer "*Async Shell Command*")
      (rename-buffer "selenium")
      (toggle-read-only)))

(eval-after-load "cperl-mode"
  '(progn
     (define-key cperl-mode-map (kbd "RET") 'newline-and-indent)
     ))

(cterm)
(define-key term-mode-map (kbd "C-;") 'term-char-mode)
(define-key term-raw-map (kbd "C-;") 'term-line-mode)
