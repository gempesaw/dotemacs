(defun kill-magit-git-process ()
  (interactive)
  (let ((magit-process (get-buffer-process "*magit-process*")))
    (when magit-process
      (set-process-query-on-exit-flag magit-process nil)
      (kill-process magit-process))))

(provide 'dg-magit)
