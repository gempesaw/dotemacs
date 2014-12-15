;; start hnew shell or switch to it if it's active
(global-set-key (kbd "C-c ,") 'sc-open-existing-hnew-shell)

(defun sc-open-existing-hnew-shell ()
  (interactive)
  (let ((buffer "*ssh-hnew*"))
    (if (or (eq nil (get-buffer-process buffer))
            (eq nil (get-buffer buffer)))
        (save-window-excursion
          (open-ssh-connection "hnew")
          (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))
    (switch-to-buffer buffer)))

(defun sc-open-jira-ticket-at-point ()
  (interactive)
  (let ((ticket (thing-at-point 'sexp)))
    (string-match "\\([A-Z]+-[0-9]+$\\)" ticket)
    (browse-url
     (concat "http://arnoldmedia.jira.com/browse/"
             (match-string 0 ticket)))))

(defun sc-army-login ()
  (interactive)
  (let ((env (ido-completing-read "Env:" '("https://armyfit.dev.sharecare.com"
                                           "https://ultimateme.dev.sharecare.com"
                                           "https://ultimateme.stage.sharecare.com"
                                           "https://armyfit.stage.sharecare.com"
                                           "https://test.armyfit.army.mil"
                                           "https://armyfit.army.mil"
                                           "https://ultimateme.army.mil"
                                           )))
        (user (ido-completing-read "User:" '("jesse.watters"
                                             "erin.graziano"
                                             "allison.pepper"
                                             "amy.emerson"
                                             "test.maigret"
                                             "jennifer.walsh"))))
    (save-window-excursion
      (async-shell-command
       (format "perl -w /Users/dgempesaw/tmp/login.pl '%s' '%s'" env user) " hide" " hide"))))

(defun sc-open-vpn-connection ()
  (interactive)
  (reset-ssh-connections)
  (tramp-cleanup-all-connections)
  (tramp-cleanup-all-buffers)
  (async-shell-command "perl ~/vpn.pl" "*vpn-script*"))

(defun tail-log-on-termdew ()
  (interactive)
  (with-temp-buffer
    (let ((file (read-from-minibuffer "File? ")))
      (cd "/ssh:honeydewdew:/home/honeydew")
      (async-shell-command (format "tail -f %s" file) (concat "*tail-" file) (concat "*tail-" file) ))))

(defun sc-restart-sauce-tunnel ()
  (interactive)
  (async-shell-command "ssh arnoldmedia-sauce ./sauce restart"))

(when nil
  (progn
    (setq talk-index-html-file "/opt/ya-ng-intro/ng/app/index.html")
    (defun restart-talk (&optional copy)
      (interactive)
      (setq current-slide-number 0)
      (unless copy
        (copy-next-file-here)))
    (restart-talk t)

    (defun copy-next-file-here ()
      (interactive)
      (let* ((next-number (1+ current-slide-number))
             (next-file (expand-file-name
                         (car
                          (file-expand-wildcards
                           (format "%s-*" next-number))))))
        (copy-file next-file talk-index-html-file t)
        (revert-buffer t t t)
        (revert-buffer t t t)
        (setq current-slide-number (1+ current-slide-number))))

    (defun copy-previous-file-here ()
      (interactive)
      (let* ((next-number (1- current-slide-number))
             (next-file (expand-file-name
                         (car
                          (file-expand-wildcards
                           (format "%s-*" next-number))))))
        (copy-file next-file talk-index-html-file t)
        (revert-buffer t t t)
        (revert-buffer t t t)
        (setq current-slide-number (1- current-slide-number))))

    (global-set-key (kbd "<M-up>")
                    (lambda ()
                      (interactive)
                      (if (use-region-p)
                          (fancy-narrow-to-region
                           (region-beginning)
                           (region-end))
                        (fancy-narrow-to-region
                         (progn (beginning-of-line) (point))
                         (progn (end-of-line) (point))))))
    (global-set-key (kbd "<M-down>") 'fancy-widen)
    (global-set-key (kbd "<M-left>") 'copy-previous-file-here)
    (global-set-key (kbd "<M-right>") 'copy-next-file-here)))

(defun dg-sc-check-status ()
  (interactive)
  (async-shell-command "ssh honeydew ./status.pl" "honeydew-nightly" nil)
  (async-shell-command "ssh sauce-connect ./sauce status" "sauce-status" nil)
  (switch-to-buffer "honeydew-nightly")
  (delete-other-windows)
  (split-window-right)
  (switch-to-buffer "sauce-status"))

(provide 'dg-sc)
