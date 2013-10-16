(defun run-feature-in-all-browsers ()
  "passes the current file to a perl script that runs it in all
browsers."
  (interactive)
  (save-window-excursion
    (async-shell-command
     (concat "perl -w /opt/honeydew/bin/multipleBrowsers.pl "
             (buffer-file-name))
     "run-feature-in-all-browsers"))
  (set-buffer "run-feature-in-all-browsers")
  (dired-other-window "/Users/dgempesaw/tmp/sauce/"))

(defun execute-feature (&optional arg)
  (interactive "p")
  (let ((filename (buffer-file-name (current-buffer)))
        (command "w /opt/honeydew/bin/honeydew.pl -isMine")
        (compile-command))
    (setq command (concat command " -feature=" filename))
    (if (eq arg 64)
        (setq command (concat command " -database ")))
    (if (eq arg 16)
        (setq command (concat "d -" command)))
    (if (>= arg 4)
        (let ((browser (ido-completing-read "browser: "
                                            '("phantomjs localhost"
                                              "chrome"
                                              "firefox"
                                              "ie 10"
                                              "ie 9"
                                              "ie 8")))
              (hostname (ido-completing-read "hostname: "
                                             '("localhost"
                                               "www.qa.sharecare.com"
                                               "www.stage.sharecare.com"
                                               "www.sharecare.com"
                                               "www.qa.startle.com"
                                               "www.stage.startle.com"
                                               "www.startle.com"
                                               "www.qa.doctoroz.com"
                                               "www.stage.doctoroz.com"
                                               "www.doctoroz.com")))
              (sauce (ido-completing-read "sauce: " '("nil" "t"))))
          (setq command (concat command
                                (if (string= sauce "t") " -sauce")
                                " -browser='" browser " webdriver'"
                                " -hostname='http://" hostname "'"))))
    (setq compile-command (concat "perl -" command))
    (compile compile-command t)))

(defun sc-hdew-prove-all ()
  "runs all the tests in the honeydew folder"
  (interactive)
  (let ((buf "*sc-hdew-prove-all*"))
    (start-process "hdew-generate-js-rules" nil "perl" "/opt/honeydew/bin/parseRules.pl")
    (start-process "hdew-make-pod" nil "perl" "/opt/honeydew/bin/makePod.pl")
    (setenv "HDEW_TESTS" "1")
    (if (string= buf (buffer-name (current-buffer)))
        (async-shell-command
         "prove -I /opt/honeydew/lib/ -j9 --state=failed,save  --trap --merge --verbose" buf)
      (async-shell-command
       "prove -I /opt/honeydew/lib/ -j9 --verbose --trap --merge --state=save,slow /opt/honeydew/t/ --rules='seq=0{2,5,6}-*' --rules='par=**'" buf))
    (setenv "HDEW_TESTS" "0")))

(defun sc-hdew-push-to-prod ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (and (not (eq nil (search-forward "Result: PASS" nil t)))
             (not (string= "*sc-hdew-prove-all*" (buffer-name (current-buffer)))))
        (message "Try again from a successful hdew prove buffer!")
      (async-shell-command "ssh hnew . pullAndDeployHoneydew" "*hdew-prod*"))))

(defun sc-kabocha-test ()
  (interactive)
  (async-shell-command "sh /opt/kabocha/run-tests" "*kabocha-run-tests*"))

(defun sc-kabocha-self-test ()
  (interactive)
  (async-shell-command "cd /opt/kabocha;prove" "*kabocha-run-tests*"))

(defun sc-kabocha-test-sso ()
  (interactive)
  (async-shell-command "sh /opt/kabocha/run-sso-tests" "*kabocha-run-tests*"))

(defun sc-hdew-update-keywords ()
  (interactive)
  (let ((buf (get-buffer " *update keywords*"))
        (update "curl -k https://server-422.lab1a.openstack.internal/keywords/getKeywordsFile.php")
        (copy "scp honeydew@hnew:/opt/honeydew/features/keywords.txt /opt/HDEW/honeydew/features/keywords.txt"))
    (save-window-excursion
      (async-shell-command (concat update " && " copy) buf buf))))

(provide 'dg-sc-perl)
