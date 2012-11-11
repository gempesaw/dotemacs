;; TODO: refactor into a function?
;; start up selenium if possible.
(let ((buffer "*selenium-webdriver*"))
  (when (eq nil (get-buffer buffer))
    (when (file-exists-p "/opt/selenium-server-standalone-2.25.0.jar")
      (set-process-query-on-exit-flag
       (start-process "selenium-webdriver" buffer "java" "-jar" "/opt/selenium-server-standalone-2.25.0.jar" "-Dwebdriver.chrome.driver=/opt/chromedriver") nil)
      (switch-to-buffer buffer)
      (setq buffer-read-only t))))
