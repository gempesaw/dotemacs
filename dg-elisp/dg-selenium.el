(defun start-selenium-server ()
  (interactive)
  (let* ((selenium-proc-name "selenium-webdriver")
         (selenium-buffer (concat "*" selenium-proc-name "-2.40.0*")))
    (when (eq nil (get-buffer selenium-buffer))
      (set-process-query-on-exit-flag
       (start-process selenium-proc-name selenium-buffer "webdriver-manager" "start")
       nil)
      (switch-to-buffer selenium-buffer))))
;; "-Dphantomjs.binary.path=/usr/local/bin/phantomjs"

(defun start-appium-server ()
  (interactive)
  (let* ((appium-proc-name "appium")
         (appium-buffer (concat "*<" appium-proc-name ">*")))
    (with-current-buffer (get-buffer-create appium-buffer)
      (comint-mode)
      (set-process-query-on-exit-flag
       (start-process appium-proc-name appium-buffer
                      "appium"
                      ;; "--avd"
                      ;; "appium"
                      "--full-reset"
                      "--log-no-colors"
                      "--port" "4723"
                      )
       nil))
    (switch-to-buffer appium-buffer)))

(if (executable-find "protractor")
    (start-selenium-server))

(defun start-browsermob-proxy ()
  (interactive)
  (let* ((bmp-proc-name "browsermob-proxy")
       (bmp-executable (or (executable-find "browsermob-proxy")
                           "/opt/dev_hdew/browsermob-proxy/bin/browsermob-proxy"))
       (default-directory (f-dirname bmp-executable))
       (buf (format "*%s*<bmp>" bmp-proc-name)))
  (with-current-buffer (get-buffer-create buf)
    (comint-mode)
    (set-process-query-on-exit-flag
     (start-process bmp-proc-name buf "/Users/dgempesaw/.jenv/bin/jenv" "exec" bmp-executable)
     nil))))

(defun reset-emulator ()
  (interactive)
  (async-shell-command "sh /Users/dgempesaw/opt/AndroidSC/emulator.sh"))

(provide 'dg-selenium)

(setenv "PATH" "/usr/local/bin:/opt/adt-bundle-mac-x86_64-20140321/sdk/tools:/opt/adt-bundle-mac-x86_64-20140321/sdk/platform-tools:/opt/dev_hdew/browsermob-proxy/bin:/Users/dgempesaw/.jenv/bin:/Users/dgempesaw/perl5/bin:usr/local/bin:/opt/adt-bundle-mac-x86_64-20140321/sdk/tools:/opt/adt-bundle-mac-x86_64-20140321/sdk/platform-tools:/opt/dev_hdew/browsermob-proxy/bin:/Users/dgempesaw/perl5/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/usr/texbin:/usr/texbin:/usr/texbin")
