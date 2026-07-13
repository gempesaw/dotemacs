;;; -*- lexical-binding: t; -*-

(defvar dg-use-ghostel t)

(defun dg-ghostel-name-by-cwd (_title)
  (format "*ghostel<%s>*" (abbreviate-file-name default-directory)))

(defun dg-ghostel-new-here ()
  (interactive)
  (ghostel '(4)))

(defun dg-ghostel-switch-or-create ()
  (interactive)
  (let ((terminals (->> (buffer-list)
                        (--filter (with-current-buffer it
                                    (derived-mode-p 'ghostel-mode)))
                        (-map 'buffer-name))))
    (if terminals
        (let ((buf (completing-read "Ghostel: " terminals)))
          (if (get-buffer buf)
              (switch-to-buffer buf)
            (dg-ghostel-new-here)))
      (dg-ghostel-new-here))))

(defun dg-ghostel-exec (&optional cmd _sentinel-arg)
  (interactive)
  (let* ((command (if cmd (format "%s && exit" cmd) ""))
         (buf (save-window-excursion (ghostel '(4)))))
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
        (add-hook 'ghostel-exit-functions
                  (lambda (b _event) (posframe-delete-frame b))
                  nil t)
        (unless (string-empty-p command)
          (ghostel-send-string command)
          (ghostel-send-key "return"))))))

(defun dg-maybe-ghostel-new-here ()
  (interactive)
  (if dg-use-ghostel
      (dg-ghostel-new-here)
    (create-new-shell-here)))

(defun dg-maybe-ghostel-switch-or-create ()
  (interactive)
  (if dg-use-ghostel
      (dg-ghostel-switch-or-create)
    (switch-to-shell-or-create)))

(defun dg-maybe-ghostel-submit (cmd)
  (if dg-use-ghostel
      (progn (ghostel-send-string cmd)
             (ghostel-send-key "return"))
    (insert cmd)
    (comint-send-input nil t)))

(defun dg-maybe-ghostel-type (str)
  (if dg-use-ghostel
      (ghostel-send-string str)
    (insert str)))

(defun dg-maybe-ghostel-exec (&optional cmd sentinel-arg)
  (interactive)
  (if dg-use-ghostel
      (dg-ghostel-exec cmd sentinel-arg)
    (dg-shell-exec cmd sentinel-arg)))

(defun dg-ghostel-beginning-of-input-or-bol ()
  (interactive "^")
  (let ((start (point)))
    (ghostel-beginning-of-input-or-line)
    (when (= (point) start)
      (move-beginning-of-line 1))))

(use-package ghostel
  :ensure t
  :demand t
  :custom
  (ghostel-shell "/opt/homebrew/bin/bash")
  (ghostel-initial-input-mode 'line)
  (ghostel-buffer-name-function #'dg-ghostel-name-by-cwd)
  (ghostel-kill-buffer-on-exit t)
  (ghostel-query-before-killing nil)
  :config
  (define-key ghostel-line-mode-map (kbd "C-a") #'dg-ghostel-beginning-of-input-or-bol)
  (dolist (ch (number-sequence ?! ?~))
    (modify-syntax-entry
     ch
     (if (= (with-syntax-table (standard-syntax-table) (char-syntax ch)) ?w) "w" ".")
     ghostel-mode-syntax-table))
  :bind* (("C-c /" . dg-maybe-ghostel-switch-or-create)
          ("C-c C-/" . dg-maybe-ghostel-new-here)))
