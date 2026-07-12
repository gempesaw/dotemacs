;;; -*- lexical-binding: t; -*-

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

(use-package ghostel
  :ensure t
  :demand t
  :custom
  (ghostel-shell "/opt/homebrew/bin/bash")
  (ghostel-buffer-name-function #'dg-ghostel-name-by-cwd)
  (ghostel-kill-buffer-on-exit t)
  (ghostel-query-before-killing nil)
  :bind* (("C-c /" . dg-ghostel-switch-or-create)
          ("C-c C-/" . dg-ghostel-new-here)))
