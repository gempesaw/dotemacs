(setq magit-completing-read-function 'magit-ido-completing-read)

(eval-after-load 'magit
  '(progn
     ;; be like dired, use d for killing
     (define-key magit-status-mode-map (kbd "d") 'magit-discard-item)
     ;; quit magit smartly
     (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)
     ;; magit whitespace
     (define-key magit-status-mode-map (kbd "W") 'magit-toggle-whitespace)))

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

(provide 'dg-magit)
