(setq magit-completing-read-function 'magit-ido-completing-read)

;; magit status
(global-set-key (kbd "C-x g") 'magit-status)

;; magit-svn-mode
(add-hook 'magit-mode-hook (lambda() (local-set-key (kbd "N") 'magit-svn-mode)))

;; blame mode
(global-set-key (kbd "C-c g") 'magit-blame)

(eval-after-load 'magit
  '(progn
     ;; be like dired, use d for killing
     (define-key magit-status-mode-map (kbd "d") 'magit-discard)
     ;; quit magit smartly
     (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)

     (add-to-list 'git-commit-style-convention-checks
                  'overlong-summary-line)
     (add-hook 'magit-mode-hook 'turn-on-magit-gitflow)
         ))

(magit-auto-revert-mode -1)
(setq magit-save-repository-buffers nil)

(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; Default to side-by-side comparisons in ediff.
(setq ediff-split-window-function 'split-window-horizontally)

(defun kill-magit-git-process ()
  (interactive)
  (let ((magit-process (get-buffer-process "*magit-process*")))
    (when magit-process
      (set-process-query-on-exit-flag magit-process nil)
      (kill-process magit-process))))

(let ((homebrew-emacsclient "/usr/local/Cellar/emacs/HEAD/bin/emacsclient"))
  (when (file-exists-p homebrew-emacsclient)
    (setq magit-emacsclient-executable homebrew-emacsclient)))

(let ((homebrew-emacsclient "E:/emacs/bin/emacsclient.exe"))
  (when (file-exists-p homebrew-emacsclient)
    (setq magit-emacsclient-executable homebrew-emacsclient)))

(defun dg-clone-github ()
  (interactive)
  (when (file-exists-p "/opt")
    (let ((buf " *github clone*")
          (url (read-from-minibuffer "Repository to clone: " (current-kill 0) )))
      (async-shell-command (format "cd /opt && git clone %s" url) buf buf ))))

(defun dg-magit-browse-remote ()
  (interactive)
  (let ((remote (cadr (s-split "[\t\s]" (shell-command-to-string "git remote -v | head -n 1")))))
    (browse-url remote)))

(defun magit-clone-opt ()
  (interactive)
  (let ((default-directory (format "%s/opt/" (getenv "HOME"))))
    (call-interactively 'magit-clone)))

(provide 'dg-magit)
