(define-key dired-mode-map (kbd "i")
  (lambda ()
    (interactive)
    (dired-subtree-insert)
    (revert-buffer)))


(define-key dired-mode-map (kbd "k")
  (lambda ()
    (interactive)
    (dired-subtree-remove)
    (revert-buffer)))

(defun dired-subtree--readin (dir-name)
  "Read in the directory.

Return a string suitable for insertion in `dired' buffer."
  (with-temp-buffer
    (insert-directory dir-name dired-listing-switches nil t)
    (delete-char -1)
    (goto-char (point-min))
    (kill-line 3)
    (setq kill-ring (cdr kill-ring))
    (insert "  ")
    (while (= (forward-line) 0)
      (insert "  "))
    (delete-char -2)
    (buffer-string)))

(provide 'dg-dired-subtree)
