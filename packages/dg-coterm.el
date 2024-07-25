(use-package coterm
  :ensure t
  :demand
  :config
  (coterm-mode)
  (coterm-auto-char-mode)
  ;; (setq comint-process-echoes t)

  (defun dg-cleanup-posframe (process event)
    "A process sentinel. Kills PROCESS's buffer even if it is live."
    (let ((b (process-buffer process)))
      (posframe-delete-frame b)
      (kill-buffer b)))



  :bind (:map dired-mode-map
              ("V" . dg-shell-exec-at-point))
  )

(defun dg-shell-exec (command &optional sentinel-arg)
  (interactive)
  (let* ((sentinel (if sentinel-arg sentinel-arg #'dg-cleanup-posframe))
         (buf (save-window-excursion
                (shell (get-buffer-create (format "*dg-shell-exec-%s: %s*"
                                                  (s-join "." (-map #'number-to-string (current-time)))
                                                  command)))))
         (proc (get-buffer-process buf)))
    (when (posframe-workable-p)
      (posframe-show buf
                     :position (point)
                     :poshandler #'posframe-poshandler-frame-center
                     :min-width 180
                     :min-height 30
                     :border-width 2
                     :border-color "white"
                     :accept-focus t)
      (with-current-buffer buf
        (set-process-query-on-exit-flag proc nil)
        (set-process-sentinel proc sentinel)
        (insert (format "%s && exit" command))
        (comint-send-input)))))

(defun dg-shell-exec-at-point ()
  (interactive)
  (let* ((filename (car (dired-get-marked-files))))
    (dg-shell-exec filename)))

(defun dg-shell-open-aws ()
  (interactive)
  (dg-shell-exec "pk open aws"))


(define-key my-keys-minor-mode-map (kbd "C-c 7") 'dg-shell-exec)
(define-key my-keys-minor-mode-map (kbd "C-c a") 'dg-shell-open-aws)
