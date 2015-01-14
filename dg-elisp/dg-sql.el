(defun dg-sql-mysql ()
  (interactive)
  (let* ((server (assoc
                  (intern
                   (ido-completing-read
                    "Which server? "
                    (mapcar (lambda (it)
                              (symbol-name (car it)))
                            db-lookup)))
                  db-lookup))
         (sql-user (cadr (assoc 'user server)))
         (sql-password (cadr (assoc 'password server)))
         (sql-server (cadr (assoc 'server server)))
         (sql-database (cadr (assoc 'database server)))
         (remote (cadr (assoc 'remote server))))
    (noflet ((sql-get-login (&rest args)))
          (with-temp-buffer
            (when remote (cd remote))
            (sql-mysql (concat sql-user "@"
                               sql-database "."
                               sql-server))
            (sql-set-product 'mysql)))))

(add-hook 'sql-interactive-mode-hook
          (lambda ()
            (toggle-truncate-lines t)))

(provide 'dg-sql)
