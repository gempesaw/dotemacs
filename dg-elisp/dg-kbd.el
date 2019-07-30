;; rename buffer
(global-set-key (kbd "C-c r") 'rename-buffer)

;; magit status
(global-set-key (kbd "C-x g") 'magit-status)

;; magit-svn-mode
(add-hook 'magit-mode-hook (lambda() (local-set-key (kbd "N") 'magit-svn-mode)))

;; blame mode
(global-set-key (kbd "C-c g") 'magit-blame-mode)

;; shortcut for revert buffer
(global-set-key (kbd "C-x r") (lambda () (interactive) (revert-buffer t t t)))

;; Easier buffer killing
(global-unset-key (kbd "M-k"))
(global-set-key (kbd "M-k") 'kill-this-buffer)

;; Easier window closing
(global-unset-key (kbd "M-0"))
(global-set-key (kbd "M-0") 'delete-window)

;; Start cterm or switch to it if it's active.
(require 'term)
(global-unset-key (kbd "C-c '"))
(global-set-key (kbd "C-c '") 'cterm)
(define-key term-mode-map (kbd "C-;") 'term-char-mode)
(define-key term-raw-map (kbd "C-;") 'term-line-mode)

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

(eval-after-load "cperl-mode"
  '(progn
     (define-key cperl-mode-map (kbd "RET") 'newline-and-indent)))

(eval-after-load "coffee-mode"
  '(progn
     (define-key coffee-mode-map (kbd "C-c C-c") 'coffee-compile-file)
     (define-key coffee-mode-map (kbd "C-c C-v") 'coffee-compile-buffer)))

(global-set-key (kbd "C-c e") 'replace-last-sexp)

;; remote compilation of feature files
(global-set-key (kbd "M-<f6>") 'remote-feature-compile)

;; look up functions
(global-unset-key (kbd "C-h C-f"))
(global-set-key (kbd "C-h C-f") 'find-function-at-point)
(global-set-key (kbd "C-h C-g") 'find-function)
(global-set-key (kbd "C-h C-k") 'find-function-on-key)

;; and variables
(global-set-key (kbd "C-h C-v") 'describe-variable-at-point)

;; make wdired like wgrep
(global-unset-key (kbd "C-c C-p"))
;; (global-set-key (kbd "C-c C-p") 'wdired-change-to-wdired-mode)
(define-key dired-mode-map (kbd "C-c C-p") 'wdired-change-to-wdired-mode)

;; (define-key grep-mode-map (kbd "C-c C-c") 'wgrep-save-all-buffers))

;; insert eol semi, reindent, go to next line
(global-set-key (kbd "C-M-;") (lambda () (interactive)
                                (save-excursion
                                  (unless (progn
                                            (end-of-line)
                                            (equal ";" (string (preceding-char))))
                                    (insert ";")))))
(global-set-key (kbd "C-;") 'add-semi-eol-and-goto-next-line-indented)
(define-key my-keys-minor-mode-map (kbd "C-;") 'add-semi-eol-and-goto-next-line-indented)

(global-set-key (kbd "C-,") (lambda ()
                              (interactive)
                              (end-of-line)
                              (insert ",")
                              (indent-according-to-mode)
                              (forward-line 1)
                              (indent-according-to-mode)))

(global-set-key (kbd "C-o") 'open-line-and-indent)
(global-set-key (kbd "C-<return>") 'create-newline-from-anywhere)
(global-set-key (kbd "RET") 'newline-and-indent)

;; save easier! c'monnnn
(progn
  (global-unset-key (kbd "C-x C-s"))
  (define-key my-keys-minor-mode-map (kbd "M-s") 'save-buffer)
  (eval-after-load "paredit"
    '(progn
       (define-key paredit-mode-map (kbd "M-s") 'save-buffer))))

;; open a new ssh connection easily
(define-key my-keys-minor-mode-map (kbd "C-c .") 'open-ssh-connection)
(define-key my-keys-minor-mode-map (kbd "C-c C-.") 'open-ssh-connection)

(global-unset-key (kbd "C-c C-j"))
(global-set-key (kbd "C-c C-j") 'join-line)

(global-set-key (kbd "C-c n") 'cleanup-buffer)

(global-unset-key (kbd "M-."))
(global-set-key (kbd "M-.") (lambda ()
                              (interactive)
                              (unless (dumb-jump-go)
                                (find-tag (thing-at-point 'symbol)))
                              ))
(global-unset-key (kbd "M-,"))
(global-set-key (kbd "M-,") 'pop-tag-mark)

(eval-after-load "tracking"
  '(progn
     (define-key tracking-mode-map (kbd "C-x C-j C-k") 'tracking-next-buffer)))

(global-unset-key (kbd "C-x C-r"))
(global-set-key (kbd "C-x C-r") 'find-file-as-root)

(global-set-key (kbd "C-c y") 'toggle-window-split)

(global-set-key [remap move-beginning-of-line] 'smarter-move-beginning-of-line)

;; (eval-after-load 'php-mode
;;   (progn
;;     (define-key php-mode-map (kbd "C-c C-r") 'php-send-region)
;;     ;; (define-key php-mode-map (kbd "<f5>") 'php-send-buffer)
;;     ;; (define-key php-mode-map (kbd "<f6>") 'php-recompile-php-buffer)
;;     (define-key php-mode-map (kbd "C-x C-e") 'php-send-line)
;;     (define-key php-mode-map (kbd "<tab>") 'smart-tab)
;;     nil))

(global-set-key (kbd "s-l") '(lambda () (interactive)
                               (delete-indentation)
                               (indent-according-to-mode)))
(global-set-key (kbd "s-u") (lambda () (interactive)
                              (delete-indentation -1)
                              (indent-according-to-mode)))

(global-set-key (kbd "s-k") 'delete-window-and-kill-buffer)

;; I keep accidentally pop-tag-mark'ing when I don't want to.
(global-unset-key (kbd "M-*"))

(global-set-key (kbd "<f13>") 'execute-feature)

;;; use regexp isearchs by default; switch 'em with their
;;; counterparts.
(global-set-key (kbd "C-s") 'isearch-forward-regexp)
(global-set-key (kbd "C-r") 'isearch-backward-regexp)
(global-set-key (kbd "C-M-r") 'isearch-backward)

;;; shortcut for fat fingering C-x z
(progn
  (global-unset-key (kbd "C-z"))
  (global-set-key (kbd "C-z") 'repeat))

(provide 'dg-kbd)
