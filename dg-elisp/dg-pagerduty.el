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

(provide 'dg-pagerduty)
