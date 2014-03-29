(defun start-selenium-server ()
  (interactive)
  (let* ((selenium-proc-name "selenium-webdriver")
         (selenium-buffer (concat "*" selenium-proc-name "-2.40.0*")))
    (when (eq nil (get-buffer selenium-buffer))
      (set-process-query-on-exit-flag
       (start-process selenium-proc-name selenium-buffer "webdriver-manager" "start")
       nil)
      (switch-to-buffer selenium-buffer)
      (setq buffer-read-only t))))
;; "-Dphantomjs.binary.path=/usr/local/bin/phantomjs"

(start-selenium-server)

(provide 'dg-selenium)
