;;; -*- lexical-binding: t; -*-
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

  ;; Add fzf detection to coterm auto-char functions
  (defun dg-coterm--auto-char-fzf ()
    "Enter `coterm-char-mode' if fzf is running.
Detects fzf by looking for its characteristic prompt pattern."
    (when (and (eobp)
               (save-excursion
                 (forward-line -1)
                 ;; Look for fzf's characteristic ">" prompt or info line
                 (or (looking-at "^>")
                     (looking-at "^  [0-9]+/[0-9]+")
                     ;; Also check if process name contains fzf
                     (when-let* ((proc (get-buffer-process (current-buffer)))
                                 (cmd (process-command proc)))
                       (seq-some (lambda (arg) (string-match-p "fzf" arg)) cmd)))))
      (unless coterm-char-mode (coterm-char-mode 1))
      (unless coterm-scroll-snap-mode (coterm-scroll-snap-mode 1))
      t))

  ;; Add our fzf detector to the beginning of the hook list
  (add-hook 'coterm-auto-char-functions #'dg-coterm--auto-char-fzf)

  ;; Allow C-c k and C-c j to pass through to Emacs in Char mode
  (define-key coterm-char-mode-map (kbd "C-c k") nil)
  (define-key coterm-char-mode-map (kbd "C-c j") nil)
  (define-key coterm-char-mode-map (kbd "M-j") nil)

  :bind ((:map comint-mode-map ("C-;" . #'coterm-char-mode-cycle))
         (:map dired-mode-map
               ("V" . dg-shell-exec-at-point)))
  )

(defun dg-shell-exec (&optional cmd sentinel-arg)
  (interactive)
  (let* ((command (if cmd (format "%s && exit" cmd) ""))
         (sentinel (if sentinel-arg sentinel-arg #'dg-cleanup-posframe))
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
        (insert command)
        (comint-send-input)))))

(defun dg-shell-exec-at-point ()
  (interactive)
  (let* ((filename (car (dired-get-marked-files))))
    (dg-shell-exec filename)))

(defun dg-shell-open-aws ()
  (interactive)
  (dg-shell-exec "sso"))


(define-key my-keys-minor-mode-map (kbd "C-c 7") 'dg-shell-exec)
(define-key my-keys-minor-mode-map (kbd "C-c a") 'dg-shell-open-aws)
