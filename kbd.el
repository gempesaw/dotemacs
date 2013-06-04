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

;; start shell or switch to it if it's active
(global-unset-key (kbd "C-c /"))
(global-set-key (kbd "C-c /")
                (lambda ()
                  (interactive)
                  (set-process-query-on-exit-flag
                   (get-buffer-process (shell)) nil)))

;; start a new shell even if one is active
(global-unset-key (kbd "C-c C-/"))
(global-set-key (kbd "C-c C-/")
                (lambda ()
                  (interactive)
                  (set-process-query-on-exit-flag
                   (get-buffer-process
                    (shell
                     (generate-new-buffer "*shell*"))) nil)))

;; start hnew shell or switch to it if it's active
(global-set-key (kbd "C-c ,") 'open-existing-hnew-shell)

;; Start cterm or switch to it if it's active.
(require 'term)
(global-unset-key (kbd "C-c '"))
(global-set-key (kbd "C-c '") 'cterm)
(define-key term-mode-map (kbd "C-;") 'term-char-mode)
(define-key term-raw-map (kbd "C-;") 'term-line-mode)

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-c C-b") 'ibuffer)
(global-set-key (kbd "C-x C-b") 'ido-switch-buffer)

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

;; search within files faster with grep-find
(global-set-key (kbd "C-c f") 'grep-find)

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

;; bookmarks
(global-set-key (kbd "C-c b l") 'bookmark-bmenu-list)
(global-set-key (kbd "C-c b s") 'bookmark-set)
(global-set-key (kbd "C-c b j") 'bookmark-jump)

;; multiple cursors
(eval-after-load "multiple-cursors"
  '(progn
     (global-set-key (kbd "C-c C-S-c") 'mc/edit-lines)
     (global-set-key (kbd "C->") 'mc/mark-next-like-this)
     (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
     (global-set-key (kbd "C-*") 'mc/mark-all-like-this)))

;; window switching - win-switch + switch-window = winner
(global-unset-key (kbd "M-j"))
(eval-after-load "switch-window"
  '(progn
     (define-key my-keys-minor-mode-map (kbd "M-j") 'switch-window)
     (define-key my-keys-minor-mode-map (kbd "C-c j") 'delete-other-window)))

(eval-after-load "cperl-mode"
  '(progn
     (define-key cperl-mode-map (kbd "RET") 'newline-and-indent)
     ))

(eval-after-load "coffee-mode"
  '(progn
     (define-key coffee-mode-map (kbd "C-c C-c") 'coffee-compile-file)
     (define-key coffee-mode-map (kbd "C-c C-v") 'coffee-compile-buffer)))

(global-set-key (kbd "C-c e") 'replace-last-sexp)

;; key binding for ace jump mode
(eval-after-load "ace-jump-mode"
  '(progn
     (define-key my-keys-minor-mode-map (kbd "C-.") 'ace-jump-mode)))

;; remote compilation of feature files
(global-set-key (kbd "M-<f6>") 'remote-feature-compile)

;; look up functions
(global-unset-key (kbd "C-h C-f"))
(global-set-key (kbd "C-h C-f") 'find-function-at-point)
(global-set-key (kbd "C-h C-g") 'find-function)

;; and variables
(global-set-key (kbd "C-h C-v") 'describe-variable-at-point)

;; make wdired like wgrep
(global-set-key (kbd "C-c C-p") 'wdired-change-to-wdired-mode)
;; (define-key grep-mode-map (kbd "C-c C-c") 'wgrep-save-all-buffers))

;; insert eol semi, reindent, go to next line
(global-set-key (kbd "C-;") 'add-semi-eol-and-goto-next-line-indented)
(global-set-key (kbd "C-,") (lambda ()
                              (interactive)
                              (end-of-line)
                              (insert ",")
                              (indent-according-to-mode)
                              (forward-line 1)
                              (indent-according-to-mode)))

(global-set-key (kbd "C-<return>") 'create-newline-from-anywhere)

;; use smex?!
(global-unset-key (kbd "M-x"))
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "C-c M-x") 'smex-major-mode-commands)
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;; save easier! c'monnnn
(global-unset-key (kbd "C-x C-s"))
(define-key my-keys-minor-mode-map (kbd "M-s") 'save-buffer)
(eval-after-load "paredit"
  '(progn
     (define-key paredit-mode-map (kbd "M-s") 'save-buffer)))

;; open a new ssh connection easily
(define-key my-keys-minor-mode-map (kbd "C-c .") 'open-ssh-connection)
(define-key my-keys-minor-mode-map (kbd "C-c C-.") 'open-ssh-connection)

(global-unset-key (kbd "C-c C-j"))
(global-set-key (kbd "C-c C-j") 'join-line)

(global-set-key (kbd "C-x f") 'fetchmacs-view-notes)

(global-set-key (kbd "C-c n") 'cleanup-buffer)

(global-set-key (kbd "s-1") 'sc-update-all-builds)
(global-set-key (kbd "s-2") 'sc-open-catalina-logs)
(global-set-key (kbd "s-3") 'sc-restart-qa-boxes)
(global-set-key (kbd "s-4") 'sc-close-qa-catalina)


(global-unset-key (kbd "M-."))
(global-set-key (kbd "M-.") 'find-tag-other-window)

(eval-after-load "tracking"
  '(progn
     (define-key tracking-mode-map (kbd "C-.") 'ace-jump-mode)
     (define-key tracking-mode-map (kbd "C-c C-@") 'ace-jump-mode)
     (define-key tracking-mode-map (kbd "C-x C-j C-k") 'tracking-next-buffer)))

(global-unset-key (kbd "s-q"))
(global-set-key (kbd "s-q") (lambda () (interactive)
                              (if (switch-between-buffers "*-jabber-groupchat-qa@conference.sharecare.com-*")
                                  (jabber-muc-names))))

(global-unset-key (kbd "s-m"))
(global-set-key (kbd "s-m") (lambda ()
                              (interactive)
                              (let ((buf "*mu4e-headers*"))
                                (if (not (string= buf (buffer-name)))
                                    (progn
                                      (with-current-buffer (get-buffer-create buf)
                                        (unless (string-match "Search" (buffer-string))
                                          (execute-kbd-macro 'mu4e-open-inbox))
                                        (mu4e-update-mail-and-index t)
                                        (switch-to-buffer buf)))
                                  (switch-to-prev-buffer)))))


(global-unset-key (kbd "C-x C-r"))
(global-set-key (kbd "C-x C-r") 'find-file-as-root)

(global-set-key (kbd "C-c y") 'toggle-window-split)

(eval-after-load "mu4e"
  '(progn
     (define-key mu4e-headers-mode-map (kbd "@") 'mu4e-headers-mark-all-as-read)
     (define-key mu4e-headers-mode-map (kbd "J") 'mu4e-headers-open-jira-ticket)
     (define-key mu4e-headers-mode-map (kbd "m") 'mu4e-headers-mark-for-something)
     (define-key mu4e-view-mode-map (kbd "J") 'mu4e-message-open-jira-ticket)))

(global-unset-key (kbd "s-o"))
(global-set-key (kbd "s-o") '(lambda () (interactive) (async-shell-command "ps aux | grep offline" nil nil)))

(global-set-key [remap move-beginning-of-line] 'smarter-move-beginning-of-line)

(eval-after-load 'key-chord
  (progn
    (key-chord-define-global "xg" 'magit-status)
    (key-chord-define-global "qq" 'window-configuration-to-register)
    (key-chord-define-global "wj" 'jump-to-register)
    (key-chord-define-global "xf" 'find-file)
    nil
    ))


(define-key php-mode-map (kbd "C-c C-r") 'php-send-buffer)
(define-key php-mode-map (kbd "C-x C-e") 'php-send-line)
(define-key php-mode-map (kbd "<tab>") 'smart-tab)
