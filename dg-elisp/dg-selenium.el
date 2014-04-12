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

(defun start-appium-server ()
  (interactive)
  (let* ((appium-proc-name "appium")
         (appium-buffer (concat "*" appium-proc-name "-0.17.6*")))
    (with-current-buffer (get-buffer-create appium-buffer)
      (comint-mode)
      (set-process-query-on-exit-flag
       (start-process appium-proc-name appium-buffer "appium" "--log-no-colors")
       nil))))

(start-selenium-server)

(provide 'dg-selenium)
