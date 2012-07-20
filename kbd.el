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

;; smart tab - do i need this?
(global-set-key (kbd "TAB") 'smart-tab)

;; Start eshell or switch to it if it's active.
(global-unset-key (kbd "C-c ;"))
(global-set-key (kbd "C-c ;") 'eshell)

;; Start a new eshell even if one is active.
(global-unset-key (kbd "C-c C-;"))
(global-set-key (kbd "C-c C-;") (lambda () (interactive) (eshell t)))

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
