;; (progn
;;   (global-unset-key (kbd "C-c ;"))
;;   (global-unset-key (kbd "C-c C-;"))
;;   (global-set-key (kbd "C-c ;") 'dg-atlantis-transient)
;;   (global-set-key (kbd "C-c C-;") 'dg-atlantis-transient))

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
  (let ((shells (->> (buffer-list)
                     (-map 'buffer-name)
                     (--filter (and (s-matches-p "*shell[^ ]" it)
                                    (not (s-contains-p "comint" it))))))
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
  (let ((buf (save-window-excursion (shell (generate-new-buffer "*shell*")))))
    (set-process-query-on-exit-flag (get-buffer-process buf) nil)
    (switch-to-buffer-other-window buf)
    buf))

(setq shell-file-name "bash")

(add-hook 'find-file-hook
          (lambda ()
            (when (file-remote-p default-directory)
              (setq-local projectile-mode-line "Projectile"))))
