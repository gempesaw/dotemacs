;; TODO: refactor into a function?
;; start up selenium if possible.
(if (eq nil (get-buffer "selenium"))
    (when (file-exists-p "/opt/selenium-server-standalone-2.25.0.jar")
      (shell-command "java -jar /opt/selenium-server-standalone-2.25.0.jar -Dwebdriver.chrome.driver=/opt/chromedriver &")
      (set-buffer "*Async Shell Command*")
      (rename-buffer "selenium")
      (set-process-query-on-exit-flag (get-process "Shell") nil)
      (toggle-read-only)))
