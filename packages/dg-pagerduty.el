(defun dg-pd-run-web-test ()
  (interactive)
  (save-excursion
    (let
        ((regex (progn
                  (end-of-line)
                  (search-backward "should '")
                  (car (reverse (s-match "should .\\(.*\\). do" (current-line-contents))))
                  ))
         (file (file-relative-name buffer-file-name (projectile-project-root))))
      (kill-new (format "bundle exec ruby -Itest %s -n \"/%s/\"" file regex)))))

(defun dg-pd-run-les-test ()
  (interactive)
  (save-excursion
    (let
        ((line (progn
                  (end-of-line)
                  (search-backward "test \"")
                  (line-number-at-pos)
                  ))
         (file (file-relative-name buffer-file-name (projectile-project-root))))
      (kill-new (format "mix test %s:%s" file line)))))

(defun dg-pd-run-elixir-test-at-point ()
  (interactive)
  (let ((command (dg-pd-run-les-test))
        (default-directory (projectile-project-root)))
    (compile command)))

(defun dg-pd-open-remote-directory (ssh-command)
  (interactive "sSSH Command for box: ")
  (let* ((parts (s-split " " ssh-command))
         (box (nth 2 parts))
         (container (nth 7 parts)))
    ;; (dg-pd-get-infra-password)
    (message (format "/ssh:%s|sudo:%s|docker:%s:/app" box box container))
    (dired (format "/ssh:%s|sudo:%s|docker:%s:/app" box box container))))

(defun dg-pd-get-infra-password ()
  (interactive)
  (let ((pw (with-temp-buffer
              (progn
                (cd "/Users/dgempesaw")
                (insert (s-trim (shell-command-to-string "security find-generic-password -s Infrastructure -w")))
                (buffer-string)))))
    (kill-new pw)
    (when (window-minibuffer-p)
      (insert pw)
      (exit-minibuffer))))

(defun dg-get-vault-password ()
  (interactive)
  (kill-new (s-trim (shell-command-to-string "security find-generic-password -s 'github vault token' -w"))))

(define-key my-keys-minor-mode-map (kbd "C-c M-i") 'dg-pd-get-infra-password)

(setq require-final-newline t)

(defun dg-terraform-snake-case ()
  (interactive)
  (beginning-of-line)
  (while (re-search-forward "-" (line-end-position) t)
    (replace-match "_" nil nil)))

(defun dg-terraform-console ()
  (interactive)
  (let* ((default-directory (make-temp-file "" t))
         (temp-file (f-join default-directory "temp.tf")))
    (window-configuration-to-register ?z)
    (f-touch temp-file)
    (f-write (substring-no-properties (car kill-ring)) 'utf-8 temp-file)
    (find-file temp-file)
    (let ((buf (create-new-shell-here)))
      (select-window (display-buffer buf))
      (insert "terraform console"))))


(defun dg-get-mfa ()
  (interactive)
  (let ((code (->> "ykman --device 20200898 oath accounts code pagerduty"
                   (shell-command-to-string)
                   (s-split " ")
                   (reverse)
                   (car)
                   (s-split "\n")
                   (car))))
    (if (s-equals-p major-mode "term-mode")
        (term-line-mode)
      (end-of-buffer))
    (insert code)
    (if (s-equals-p major-mode "term-mode")
        (progn
          (term-send-input)
          (term-char-mode))
      (comint-send-input))))

(global-set-key (kbd "C-c M-m") 'dg-get-mfa)

(provide 'dg-pagerduty)
