(setq magit-completing-read-function 'magit-ido-completing-read)

(eval-after-load 'magit
  '(progn
     (set-face-foreground 'magit-diff-add "green3")
     (set-face-foreground 'magit-diff-del "red3")
     (set-face-attribute 'magit-item-highlight nil :inherit nil)
     (set-face-background 'magit-item-highlight "gray17")
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

(provide 'dg-magit)
