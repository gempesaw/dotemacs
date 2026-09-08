;;; -*- lexical-binding: t; -*-

(setenv "MODULAR_PATH" "/Users/gempesaw/opt/modular")

(let ((file (concat (getenv "MODULAR_PATH") "/utils/emacs/modular.el")))
  (when (file-exists-p file) (load-file file)))

;;; autoload the start-modular.sh when we're in the modular directory in a
;;; comint shell
(setq dg-start-modular-included nil)
(defun dg-start-modular (&rest args)
  (interactive)
  (let ((dir (cwd)))
    (when (and
           (s-contains-p "/opt/modular/" dir)
           (not dg-start-modular-included))
      (setq-local dg-start-modular-included t)
      (insert "source $HOME/opt/modular/utils/start-modular.sh")
      (comint-send-input nil t))))

(advice-add #'shell-directory-tracker :after #'dg-start-modular)

(setq dg-modular-aws-profile "")
(defun dg-modular-aws-profile-login (profile)
  (interactive
   (list
    (completing-read "select AWS profile"
                     (s-split "\n" (shell-command-to-string "aws configure list-profiles") t)
                     )))
  (dg-modular-ensure-aws-profile-login profile))


(defun dg-modular-ensure-aws-profile-login (profile)
  "Ensure PROFILE has fresh credentials in `~/.aws/credentials [agent-PROFILE]'.
Triggers SSO login via browser if needed. Returns a plist
\\='(:profile AGENT-PROFILE :access-key K :secret-key S :session-token T)
sourced from the credentials file at the end. Callers that just want
the side-effects can ignore the return value."
  (when profile
    (let ((sts-gci-output (--> "aws sts get-caller-identity --profile %s"
                               (format it profile)
                               (shell-command-to-string it)))
          (browser (getenv "BROWSER")))
      (if (s-contains-p "Account" sts-gci-output)
          (message (format "confirmed logged in to profile: %s" profile))
        (message (format "we are logged out; logging in to AWS, profile: %s" profile))
        (->> process-environment
             (--map (car (s-split "=" it t)))
             (--filter (s-starts-with? "AWS_" it))
             (--map (setenv it nil)))

        ;; unintentionally, this blocks until the user finishes the browser
        ;; prompts, so that's kind of nice actually
        (dg-transient-aws-sso-set-emacs-env profile)
        ;; (setenv "BROWSER" browser)
        (message (format "successfully logged in as %s" profile)))
      (setenv "AWS_PROFILE" profile)
      (setq dg-modular-aws-profile profile)
      (dg-modular--read-agent-credentials profile))))

(defun dg-modular--read-agent-credentials (profile)
  "Read `[agent-PROFILE]' from `~/.aws/credentials' as a plist.
Returns nil if the section doesn't exist."
  (require 'ini)
  (let* ((creds-file (expand-file-name "~/.aws/credentials"))
         (agent-profile (concat "agent-" profile))
         (alist (when (file-exists-p creds-file) (ini-decode creds-file)))
         (section (cdr (assoc agent-profile alist)))
         (get (lambda (k) (cdr (assoc k section)))))
    (when section
      (list :profile agent-profile
            :access-key (funcall get "aws_access_key_id")
            :secret-key (funcall get "aws_secret_access_key")
            :session-token (funcall get "aws_session_token")))))


;;
;; (setq dg-modular-gcp-instances (->> "gcloud compute instances list --format='value(name, zone)'"
;;                                     (shell-command-to-string)))

;; (progn

;;   (defun dg-modular-gcp-evaluate-all (cmd)
;;     (interactive)
;;     (let* ((instances (->> dg-modular-gcp-instances
;;                            (s-split "\n")
;;                            (--map (s-split "\t" it))
;;                            (--filter (= 2 (length it)))))
;;            (commands (->> instances
;;                           (--map (list (format "%s" (car it))
;;                                        (format "gcloud compute ssh %s --zone=%s --command=\"%s\"" (car it) (cadr it) cmd))))))
;;       (->> commands
;;            (--map (let ((buf (car it))
;;                         (command (cadr it)))
;;                     (async-shell-command command (get-buffer-create buf)))))
;;       ))



;;   (save-window-excursion
;;     (dg-modular-gcp-evaluate-all "ls -al /home/runner/actions-runner/_work/_temp/_github_home/.cache/huggingface/datasets/AI4Math___math_vista")
;;     ;; (dg-modular-gcp-evaluate-all "sudo rm -rf /home/runner/actions-runner/_work/_temp/_github_home/.cache/huggingface/datasets/AI4Math___math_vista/")
;;     ))

(defun dg-modular-github-workflow-run-dispatch ()
  (interactive)
  (let* ((workflow-name (f-filename (buffer-file-name)))
         (branch (magit-get-current-branch))
         (bpr-colorize-output t)
         (bpr-process-mode #'comint-mode)
         (bpr-on-completion (lambda (proc)
                              (run-with-timer 2
                                              nil
                                              (lambda ()
                                                (->>
                                                 (format "gh run list --workflow=%s --json 'url,headBranch'" workflow-name )
                                                 (shell-command-to-string)
                                                 (json-read-from-string)
                                                 (seq-filter (lambda (it) (s-equals-p (assoc-default 'headBranch it) branch)))
                                                 (car)
                                                 (assoc-default 'url)
                                                 (browse-url)))))))
    (bpr-spawn (format "gh workflow run %s --ref %s" workflow-name branch))))
