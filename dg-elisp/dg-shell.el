;; Start eshell or switch to it if it's active.
(global-unset-key (kbd "C-c ;"))
(global-set-key (kbd "C-c ;") 'eshell)

;; Start a new eshell even if one is active.
(global-unset-key (kbd "C-c C-;"))
(global-set-key (kbd "C-c C-;") (lambda () (interactive) (eshell t)))

;; switch between active shells
(global-unset-key (kbd "C-c /"))
(global-set-key (kbd "C-c /") 'switch-to-shell-or-create)
(define-key my-keys-minor-mode-map (kbd "C-c /") 'switch-to-shell-or-create)

;; start a new shell even if one is active
(global-unset-key (kbd "C-c C-/"))
(global-set-key (kbd "C-c C-/") 'create-new-shell-here)

(when shell-mode-map
  (define-key shell-mode-map [remap shell-resync-dirs] 'comint-send-input))

(defun switch-to-shell-or-create ()
  (interactive)
  (let ((shells (mapcar 'buffer-name
                        (-filter (lambda (buffer)
                                   (string-match "\\*shell[^ ]" (buffer-name buffer)))
                                 (buffer-list))))
        (buf))
    (if shells
        (progn (setq buf (ido-completing-read "Buffer: " shells))
               (unless (get-buffer buf )
                 (setq buf (create-new-shell-here)))
               (switch-to-buffer buf))
      (create-new-shell-here))))

(defadvice shell-directory-tracker (after add-cwd-to-buffer activate)
  (if (string-match "^*shell" (buffer-name (current-buffer)))
      (rename-buffer (format "*shell<%s>*" default-directory) t)))

(defun create-new-shell-here ()
  (interactive)
  (let ((buf (shell (generate-new-buffer "*shell*"))))
    (set-process-query-on-exit-flag (get-buffer-process buf) nil)
    buf))

(setq shell-file-name "bash")

(provide 'dg-shell)
