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

(defun switch-to-shell-or-create ()
  (interactive)
  (let ((shells (mapcar 'buffer-name
                        (-filter (lambda (buffer)
                                   (string-match "\\*shell" (buffer-name buffer)))
                                 (buffer-list)))))
    (if shells
        (switch-to-buffer
         (ido-completing-read "Buffer: " shells))
      (create-new-shell-here))))

(defun create-new-shell-here ()
  (interactive)
  (set-process-query-on-exit-flag
   (get-buffer-process
    (shell
     (generate-new-buffer "*shell*"))) nil))

(provide 'dg-shell)
