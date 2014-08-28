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
                                            '(
                                              "chrome"
                                              "firefox"
                                              "phantomjs localhost"
                                              "Local Mobile Emulator"
                                              )))
              (hostname (ido-completing-read "hostname: "
                                             '("http://localhost"
                                               "http://www.qa.sharecare.com"
                                               "https://www.dw.sharecare.com"
                                               "http://www.stage.sharecare.com"
                                               "http://www.sharecare.com"
                                               "http://www.qa.startle.com"
                                               "http://www.stage.startle.com"
                                               "http://www.startle.com"
                                               "http://www.qa.doctoroz.com"
                                               "http://www.stage.doctoroz.com"
                                               "http://www.doctoroz.com"
                                               "https://armyfit.dev.sharecare.com"
                                               "https://armyfit.stage.sharecare.com"
                                               "https://test.armyfit.army.mil"
                                               "https://armyfit.army.mil"
                                               "https://ultimateme.dev.sharecare.com"
                                               "https://ultimateme.stage.sharecare.com"
                                               "https://armyfit.army.mil/UltimateMe"
                                               "http://s.qa.origin.sharecare.com/honeydew/app.zip")))
              (sauce (ido-completing-read "sauce: " '("nil" "t"))))
          (setq command (concat command
                                (if (string= sauce "t") " -sauce")
                                " -browser='" browser " webdriver'"
                                " -hostname='" hostname "'"))))
    (setq compile-command (concat "perl -" command))
    (compile compile-command t)))

(defun sc-hdew-prove-all ()
  "runs all the tests in the honeydew folder"
  (interactive)
  (let ((buf "*sc-hdew-prove-all*"))
    (start-process "hdew-generate-js-rules" nil "perl" "/opt/honeydew/bin/parseRules.pl")
    (start-process "hdew-make-pod" nil "perl" "/opt/honeydew/bin/makePod.pl")
    (if (string= buf (buffer-name (current-buffer)))
        (async-shell-command
         "prove -I /opt/honeydew/lib/ -j9 --state=failed,save  --trap --merge --verbose" buf)
      (async-shell-command
       "prove -I /opt/honeydew/lib/ -j9 --verbose --trap --merge --state=save,slow /opt/honeydew/t/ --rules='seq=0{2,5,6}-*' --rules='par=**'" buf))))

(defun sc-execute-file-at-point ()
  (interactive)
  (compile (format "perl -I/opt/honeydew/t/lib -I/opt/honeydew/lib -w %s" (thing-at-point 'filename))))

(defun sc-hdew-push-to-prod (&optional pfx)
  (interactive "p")
  (save-excursion
    (goto-char (point-min))
    (if (or (> pfx 1)
            (and (search-forward "Result: PASS" nil t)
                 (string= "*sc-hdew-prove-all*" (buffer-name (current-buffer)))))
        (async-shell-command "ssh termdew . pullAndDeployHoneydew" "*hdew-prod*")
      (message "Try again from a successful hdew prove buffer!"))))

(defun sc-hdew-push-to-prod-backend ()
  (interactive)
  (async-shell-command "ssh termdew \"cd stage_hdew && git pull --rebase && . deploy.sh ui\""))

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
