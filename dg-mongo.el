(defun mongo ()
  (interactive)
  (let* ((titles (mapcar (lambda (it) (car it)) mongo-db-choices))
         (choice (ido-completing-read "Which DB: " titles))
         (mongo-buffer (format "*%s-mongodb*" choice))
         (address (cdr (assoc choice mongo-db-choices)))
         (args " --ssl ")
         (mongo-command (format "mongo %s %s" args address)))
    (async-shell-command mongo-command mongo-buffer)
    (smother-process-query-on-exit (pop-to-buffer mongo-buffer))
    (goto-char (point-max))
    (insert "use SharecareDB")))



(provide 'dg-mongo)
