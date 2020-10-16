(defun dg-pd-run-web-test ()
  (interactive)
  (save-excursion
    (let
        ((regex (progn
                  (end-of-line)
                  (search-backward "should '")
                  (car (reverse (s-match "should .\\(.*\\). do" (current-line-contents))))
                  ))
         (file (file-relative-name buffer-file-name (projectile-project-root))))
      (kill-new (format "bundle exec spring testunit %s -n \"/%s/\"" file regex)))))

(defun dg-pd-run-les-test ()
  (interactive)
  (save-excursion
    (let
        ((line (progn
                  (end-of-line)
                  (search-backward "test \"")
                  (line-number-at-pos)
                  ))
         (file (file-relative-name buffer-file-name (projectile-project-root))))
      (kill-new (format "docker-compose run --rm les mix test %s:%s" file line)))))


(defun dg-pd-open-remote-directory (ssh-command)
  (interactive "sSSH Command for box: ")
  (let* ((parts (s-split " " ssh-command))
         (box (nth 2 parts))
         (container (nth 7 parts)))
    (dired (format "/ssh:%s|sudo:%s|docker:%s:/app" box box container))))
(provide 'dg-pagerduty)
