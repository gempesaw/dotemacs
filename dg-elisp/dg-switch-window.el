;; switch windows using home row keys
(setq switch-window-shortcut-style 'qwerty
      ;; don't bother running window-configuration-change-hook while `switch-window`-ing
      switch-window-shadow-window-change-hook t)

(defun delete-other-window-and-buffer (&optional kill-window-buffer-too)
  "Display an overlay in each window showing a unique key, then
ask user which window to delete.

If `kill-window-buffer-too` is non-nil, also delete the buffer in
the window."
  (interactive)
  (if (> (length (window-list)) 1)
      (progn
        (let ((index (prompt-for-selected-window "Delete window: "))
              (delete-window-function (if kill-window-buffer-too
                                          'delete-window-and-kill-buffer
                                        'delete-window)))
          (apply-to-window-index delete-window-function index "")))))

(defun delete-window-and-kill-buffer (&optional window)
  "Delete WINDOW and kill it's associated buffer.
WINDOW defaults to the currently selected window.
Return nil."
  (interactive)
  (let ((window (window-normalize-window window)))
    (kill-buffer (window-buffer window))
    (delete-window window))
  nil)

(defadvice prompt-for-selected-window (around shadow-change-hook activate)
  (let ((window-configuration-change-hook nil))
    ad-do-it))

;; window switching - win-switch + switch-window = winner
(global-unset-key (kbd "M-j"))
(eval-after-load "switch-window"
  '(progn
     (define-key my-keys-minor-mode-map (kbd "M-j") 'switch-window)
     (define-key my-keys-minor-mode-map (kbd "C-c j") 'delete-other-window-and-buffer)
     (define-key my-keys-minor-mode-map (kbd "C-c k") (lambda () (interactive) (delete-other-window-and-buffer t)))))


(provide 'dg-switch-window)
