;; set up previous window as C-x p (like C-x o)
(defun back-window () (interactive) (other-window -1))
(global-set-key (kbd "C-x p") 'back-window)

;; TODO - full screen doesn't work in emacs 24
;; toggle full screen
;; (global-set-key (kbd "M-RET") 'ns-toggle-fullscreen)

;; rename buffer
(global-set-key (kbd "C-c r") 'rename-buffer)

;; magit status
(global-set-key (kbd "C-x g") 'magit-status)

;; magit-svn-mode
(add-hook 'magit-mode-hook (lambda() (local-set-key (kbd "N") 'magit-svn-mode)))

;; blame mode
(global-set-key (kbd "C-c g") 'magit-blame-mode)

;; shortcut for revert buffer
(global-set-key (kbd "C-x r") 'revert-buffer)

;; macro and shortcut to set up in 3 wide, last split window organization
(fset 'startupConfig
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([24 51 24 51 24 112 24 50 24 111 24 50 24 48 24 43 134217848 115 104 101 108 108 return 24 111 24 98 104 111 110 101 121 100 101 119 46 112 108 return 24 112 24 112 24 98 72 111 110 101 121 68 101 119 46 112 109 return 24 112 24 98 100 101 102 97 117 108 116 46 112 109 return] 0 "%d")) arg)))
(global-set-key (kbd "C-x c f g") 'startupConfig)

;; Easier buffer killing
(global-unset-key (kbd "M-k"))
(global-set-key (kbd "M-k") 'kill-this-buffer)

;; Easier window closing
(global-unset-key (kbd "M-0"))
(global-set-key (kbd "M-0") 'delete-window)

;; smart tab - do i need this? YES
(global-set-key (kbd "<tab>") 'smart-tab)
(setq yas/trigger-key "C-<tab>")

;; Start eshell or switch to it if it's active.
(global-unset-key (kbd "C-c ;"))
(global-set-key (kbd "C-c ;") 'eshell)

;; Start a new eshell even if one is active.
(global-unset-key (kbd "C-c C-;"))
(global-set-key (kbd "C-c C-;") (lambda () (interactive) (eshell t)))

;; Start cterm or switch to it if it's active.
(global-unset-key (kbd "C-c '"))
(global-set-key (kbd "C-c '") 'cterm)

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; load file into emacs
(global-unset-key (kbd "C-c C-l"))
(global-set-key (kbd "C-c C-l") 'load-file)

;; quicker el-get list packages
(global-unset-key (kbd "C-c C-e l p"))
(global-set-key (kbd "C-c C-e l p") 'el-get-list-packages)

;; i like using M-` to switch between frames
(global-unset-key (kbd "M-`"))
(global-set-key (kbd "M-`") 'other-frame)

;; search within files with find grep
(global-set-key (kbd "C-c d") 'find-grep-dired)

;; recursive file search ??? there's gotta be a better way!
(global-set-key (kbd "C-x M-f") `find-name-dired)

;; expanding region
;; this gets overwritten in cterm mode :(
(global-set-key (kbd "C-'") 'er/expand-region)

;; shortcuts for compilation
(global-set-key (kbd "<f5>") 'smart-compile)
(global-set-key (kbd "<f6>") 'compile-again)

;; eval region
(global-set-key (kbd "C-<f5>") 'eval-region)

;; google
(global-set-key (kbd "C-x ?") 'google)

;; win switch
(eval-after-load "win-switch"
  '(progn
     (global-set-key "\C-xo" 'win-switch-dispatch)
     ))


(global-unset-key (kbd "C-x C-r"))
(eval-after-load "inline-string-rectangle"
'(progn
   (global-set-key (kbd "C-x C-r t") 'inline-string-rectangle)
   (global-set-key (kbd "C-x C-r C-t") 'inline-string-rectangle)
   ))

;; for multiple marking
(eval-after-load "mark-more-like-this"
  '(progn
     (global-set-key (kbd "C-<") 'mark-previous-like-this)
     (global-set-key (kbd "C->") 'mark-next-like-this)
     (global-set-key (kbd "C-M-m") 'mark-more-like-this) ; like the other two, but takes an argument (negative is previous)
     (global-set-key (kbd "C-*") 'mark-all-like-this)
     ))

;; picks up both tags in sgml mode? i don't use this...
;; (eval-after-load "mark-more-like-this"
;; '(progn
;;    (add-hook 'sgml-mode-hook
;;              (lambda ()
;;                (define-key sgml-mode-map (kbd "C-c C-r") 'rename-sgml-tag)))
;;    ))

;; bookmarks
(global-set-key (kbd "C-c C-b l") 'bookmark-bmenu-list)
(global-set-key (kbd "C-c C-b s") 'bookmark-set)
(global-set-key (kbd "C-c C-b j") 'bookmark-jump)

;; win-switch
(eval-after-load "win-switch"
  (global-set-key (kbd "C-o") 'win-switch-enter))
