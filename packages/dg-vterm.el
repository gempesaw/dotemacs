(use-package vterm
  :ensure t
  :config
  (setq vterm-kill-buffer-on-exit t)
  (define-key vterm-mode-map (kbd "TAB") #'vterm-send-tab)

  (defun dg-vterm-open-aws-kill (process event)
    "A process sentinel. Kills PROCESS's buffer even if it is live."
    (let ((b (process-buffer process)))
      (posframe-delete-frame b)
      (kill-buffer b)))

  (defun dg-vterm-open-aws ()
    (interactive)
    (let ((buf (vterm--internal (lambda (&rest args)) "*pk-open-aws*")))
      (when (posframe-workable-p)
        (posframe-show buf
                       :position (point)
                       :poshandler #'posframe-poshandler-point-top-left-corner
                       :min-width 80
                       :min-height 30
                       :border-width 2
                       :border-color "white"
                       :accept-focus t)
        (with-current-buffer buf
          (set-process-sentinel vterm--process #'dg-vterm-open-aws-kill)
          (vterm-send-string "pk open aws && exit")
          (vterm-send-return)))))

  (defun dg-vterm-exec-at-point ()
    (interactive)
    (let ((filename (car (dired-get-marked-files)))
          (buf (vterm--internal (lambda (&rest args)) (format "*%s*" (dired-get-marked-files t)))))
      (when (posframe-workable-p)
        (posframe-show buf
                       :position (point)
                       :poshandler #'posframe-poshandler-point-top-left-corner
                       :min-width 80
                       :min-height 30
                       :border-width 2
                       :border-color "white"
                       :accept-focus t)
        (with-current-buffer buf
          (set-process-sentinel vterm--process #'dg-vterm-open-aws-kill)
          (vterm-send-string (format "%s && exit" filename))
          (vterm-send-return)))
      ))
  )


(use-package term
  :config
  (global-unset-key (kbd "C-c M-/"))
  (global-set-key (kbd "C-c M-/") 'term)
  (define-key term-mode-map (kbd "C-;") 'term-char-mode)
  (define-key term-raw-map (kbd "C-;") 'term-line-mode))
