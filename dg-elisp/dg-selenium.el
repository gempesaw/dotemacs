(defun start-selenium-server ()
  (interactive)
  (let* ((selenium-proc-name "selenium-webdriver")
         (selenium-buffer (concat "*" selenium-proc-name "-2.40.0*")))
    (when (eq nil (get-buffer selenium-buffer))
      (set-process-query-on-exit-flag
       (start-process selenium-proc-name selenium-buffer "webdriver-manager" "start" "--versions.standalone" "3.0.1")
       nil)
      (switch-to-buffer selenium-buffer))))
;; "-Dphantomjs.binary.path=/usr/local/bin/phantomjs"

(defun restart-appium-server ()
  (interactive)
  (let* ((appium-proc-name "appium")
         (appium-buffer (concat "*<" appium-proc-name ">*")))
    (when (get-buffer appium-buffer) (kill-buffer appium-buffer))
    (with-current-buffer (get-buffer-create appium-buffer)
      (make-local-variable 'process-environment)
      (setenv "ANDROID_HOME" "/usr/local/opt/android-sdk")
      (comint-mode)
      (setq-local comint-output-filter-functions '(comint-postoutput-scroll-to-bottom
                                                   comint-truncate-buffer))
      (set-process-query-on-exit-flag
       (start-process appium-proc-name appium-buffer
                      "appium"
                      ;; "--avd"
                      ;; "appium"
                      ;; "--full-reset"
                      "--log-no-colors"
                      "--port" "4723"
                      )
       nil))
    (switch-to-buffer appium-buffer)))

(defun start-browsermob-proxy ()
  (interactive)
  (let* ((bmp-proc-name "browsermob-proxy")
         (bmp-executable (or (executable-find "browsermob-proxy")
                             "/opt/bmp-service/browsermob-proxy/bin/browsermob-proxy"))
         (default-directory (f-dirname bmp-executable))
         (buf (format "*%s*<bmp>" bmp-proc-name))
         (exec))
    (with-current-buffer (get-buffer-create buf)
      (message (concat "/Users/dgempesaw/.jenv/bin/jenv" "exec" bmp-executable "-port" "8080" "--use-littleproxy" "true"))
      (comint-mode)
      (setq-local comint-output-filter-functions '(comint-postoutput-scroll-to-bottom
                                                   comint-truncate-buffer))
      (set-process-query-on-exit-flag
       (start-process bmp-proc-name buf "/Users/dgempesaw/.jenv/bin/jenv" "exec" bmp-executable "-port" "8080" "--use-littleproxy" "true")
       nil))))

(defun reset-emulator ()
  (interactive)
  (async-shell-command "sh /Users/dgempesaw/opt/AndroidSC/emulator.sh"))

(defun start-redis-server ()
  (interactive)
  (let* ((proc-name "redis-server")
         (buffer "redis-server<redis>")
         (executable (executable-find "redis-server")))
    (when (eq nil (get-buffer buffer))
      (set-process-query-on-exit-flag
       (start-process proc-name buffer executable)
       nil))))

(defun start-bitlbee-server ()
  (interactive)
  (start-process "" " *kill*" "pkill" "bitlbee")
  (start-buffer-process "bitlbee" (executable-find "bitlbee") "-F"))

(defun start-buffer-process (name cmd &rest opts)
  (let* ((proc-name (concat name "-server"))
         (buffer (format "*%s*<%s>" proc-name name))
         (args (append `(,proc-name ,buffer ,cmd) opts)))
    (with-current-buffer (get-buffer-create buffer)
      (make-local-variable 'process-environment)
      (comint-mode)
      (setq-local comint-output-filter-functions '(comint-postoutput-scroll-to-bottom
                                                   comint-truncate-buffer))
      (set-process-query-on-exit-flag
       (apply 'start-process args) nil))
    buffer))

(if (executable-find "protractor")
    (start-selenium-server))

(if (executable-find "redis-server")
    (start-redis-server))

(if (executable-find "appium")
    (save-window-excursion (restart-appium-server)))

(if (executable-find "bitlbee")
    (save-window-excursion (start-bitlbee-server)))

(if (executable-find "browsermob-proxy")
    (save-window-excursion (start-browsermob-proxy)))

(provide 'dg-selenium)
