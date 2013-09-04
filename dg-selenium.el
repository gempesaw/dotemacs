(setq selenium-webdriver-version "2.35.0")

(defun start-selenium-server ()
  (interactive)
  (let* ((selenium-proc-name "selenium-webdriver")
         (default-directory "/opt/")
         (selenium-file (locate-file (cadr (file-expand-wildcards "selenium*")) `(,default-directory)))
         (selenium-version (progn (string-match "\\([[:digit:]].[[:digit:]]+.[[:digit:]]\\)" selenium-file)
                                  (match-string 0 selenium-file)))
         (selenium-buffer (concat "*" selenium-proc-name "-" selenium-version "*")))
    (when (and (eq nil (get-buffer selenium-buffer))
               (file-exists-p selenium-file))
      (set-process-query-on-exit-flag
       (start-process selenium-proc-name selenium-buffer
                      "java" "-jar" selenium-file "-Dwebdriver.chrome.driver=/opt/chromedriver"
                      "-Dphantomjs.binary.path=/usr/local/bin/phantomjs"
                      )
       nil)
      (switch-to-buffer selenium-buffer)
      (setq buffer-read-only t))))

(start-selenium-server)

(provide 'dg-selenium)