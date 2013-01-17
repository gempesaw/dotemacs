;; TODO: refactor into a function?
;; start up selenium if possible.

(let ((selenium-proc-name "selenium-webdriver")
      (selenium-version "2.28.0")
      (selenium-buffer nil)
      (selenium-file))
  (setq selenium-buffer (concat "*" selenium-proc-name "-" selenium-version "*"))
  (setq selenium-file (concat "/opt/selenium-server-standalone-" selenium-version ".jar"))
    (save-window-excursion
      (when (and (eq nil (get-buffer selenium-buffer)) (file-exists-p selenium-file))
        (set-process-query-on-exit-flag
         (start-process selenium-proc-name selenium-buffer
                        "java" "-jar" selenium-file "-Dwebdriver.chrome.driver=/opt/chromedriver")
         nil)
        (switch-to-buffer selenium-buffer)
        (setq buffer-read-only t))))
