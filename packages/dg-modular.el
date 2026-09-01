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


;;; projectId: \"9ee8dc9b-29a5-41d0-8dc8-4682e0530719\"
(defun dg-linear-create-ticket (title)
  "Create a Linear ticket with predefined settings and copy the ticket number to clipboard."
  (interactive "sTicket title: ")
  (let* ((api-key (auth-source-pick-first-password :host "linear.app" :user "apikey"))
         (url "https://api.linear.app/graphql")
         (query (json-encode
                 `((query . "mutation CreateIssue($title: String!) {
                             issueCreate(input: {
                               title: $title,
                               teamId: \"eaa359fe-9ad4-4589-a878-e675ed57d21b\",
                               assigneeId: \"596d5e87-e15e-4ed3-86a5-bfd6ca374abf\",
                               priority: 0,
                               stateId: \"e93651d8-0bae-41e9-8824-d7fdfbf03488\",
                             }) {
                               success
                               issue {
                                 identifier
                                 url
                               }
                             }
                           }")
                   (variables . ((title . ,title))))))
         (url-request-method "POST")
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("Authorization" . ,api-key)))
         (url-request-data query))
    (let* ((response-buffer (url-retrieve-synchronously url))
           (json-object-type 'hash-table)
           (response (with-current-buffer response-buffer
                       (goto-char (point-min))
                       (re-search-forward "^$")
                       (let ((json-string (buffer-substring-no-properties (point) (point-max))))
                         (json-read)))))
      (if-let* ((data (gethash "data" response))
                (issue-create (gethash "issueCreate" data))
                (issue (gethash "issue" issue-create))
                (ticket-id (gethash "identifier" issue))
                (url (gethash "url" issue)))
          (progn
            (kill-new (downcase ticket-id))
            (message "Created ticket %s at %s" ticket-id url))
        (if-let ((errors (gethash "errors" response)))
            (message "Error creating ticket: %s"
                     (gethash "message" (aref errors 0)))
          (message "Unknown error creating ticket"))))))

(define-key my-keys-minor-mode-map (kbd "C-M-s-p") 'dg-linear-create-ticket)

;; (let* ((api-key (auth-source-pick-first-password :host "linear.app" :user "apikey"))
;;        (url "https://api.linear.app/graphql")
;;        (query (json-encode
;;                `((query . "query GetMetadata {
;;                              teams {
;;                                nodes {
;;                                  id
;;                                  name
;;                                  key
;;                                }
;;                              }
;;                              workflowStates {
;;                                nodes {
;;                                  id
;;                                  name
;;                                  team {
;;                                    key
;;                                  }
;;                                }
;;                              }
;;                              users {
;;                                nodes {
;;                                  id
;;                                  name
;;                                  email
;;                                }
;;                              }
;;                              projects {
;;                                nodes {
;;                                  id
;;                                  name
;;                                }
;;                              }
;;                            }"))))
;;        (url-request-method "POST")
;;        (url-request-extra-headers
;;         `(("Content-Type" . "application/json")
;;           ("Authorization" . ,api-key)))
;;        (url-request-data query))
;;   (let ((response (with-current-buffer (url-retrieve-synchronously url)
;;                     (goto-char (point-min))
;;                     (re-search-forward "^$")
;;                     (let ((json-string (buffer-substring-no-properties (point) (point-max))))
;;                       (message "Raw response: %s" json-string)
;;                       (json-read)))))
;;     response))


;; (let* ((api-key (auth-source-pick-first-password :host "linear.app" :user "apikey"))
;;          (url "https://api.linear.app/graphql")
;;          (query (json-encode
;;                 `((query . "query GetStates {
;;                              workflowStates(filter: {
;;                                team: { id: { eq: \"eaa359fe-9ad4-4589-a878-e675ed57d21b\" } }
;;                              }) {
;;                                nodes {
;;                                  id
;;                                  name
;;                                }
;;                              }
;;                            }"))))
;;          (url-request-method "POST")
;;          (url-request-extra-headers
;;           `(("Content-Type" . "application/json")
;;             ("Authorization" . ,api-key)))
;;          (url-request-data query))
;;     (let ((response (with-current-buffer (url-retrieve-synchronously url)
;;                      (goto-char (point-min))
;;                      (re-search-forward "^$")
;;                      (let ((json-string (buffer-substring-no-properties (point) (point-max))))
;;                        (message "Raw response: %s" json-string)
;;                        (json-read)))))
;;       response))



;; (let* ((api-key (auth-source-pick-first-password :host "linear.app" :user "apikey"))
;;        (url "https://api.linear.app/graphql")
;;        (query (json-encode
;;                `((query . "{
;; issues(filter: {
;;   team: {
;;     id: {
;;       eq: \"eaa359fe-9ad4-4589-a878-e675ed57d21b\"
;;     }
;;   }
;;   assignee: { id: { eq: \"596d5e87-e15e-4ed3-86a5-bfd6ca374abf\" } }
;; }) {
;;   nodes {
;;     id
;;     title
;;     state {
;;       name
;;     }
;;     assignee {
;;       id
;;       name
;;     }
;;     url
;;   }
;; }
;; }"))))
;;        (url-request-method "POST")
;;        (url-request-extra-headers
;;         `(("Content-Type" . "application/json")
;;           ("Authorization" . ,api-key)))
;;        (url-request-data query))
;;   (let ((response (with-current-buffer (url-retrieve-synchronously url)
;;                     (goto-char (point-min))
;;                     (re-search-forward "^$")
;;                     (let ((json-string (buffer-substring-no-properties (point) (point-max))))
;;                       (json-read)))))
;;     (setq dg-response response)
;;     (let ((issues (cdr (assoc 'nodes (cdr (assoc 'issues (assoc 'data response)))))))
;;       (when issues
;;         (let ((output (list (format "%-15s %-12s %-10s %s" "Assignee" "State" "Key" "Title"))))
;;           (-each issues (lambda (issue)
;;                           (let* ((assignee (cdr (assoc 'name (cdr (assoc 'assignee issue)))))
;;                                  (state (cdr (assoc 'name (cdr (assoc 'state issue)))))
;;                                  (url (cdr (assoc 'url issue)))
;;                                  (title (cdr (assoc 'title issue)))
;;                                  (key (when (string-match "/issue/\\(.*?\\)/" url)
;;                                         (match-string 1 url))))
;;                             (when (s-matches-p "Todo\\|Progress" state)
;;                               (push (format "%-15s %-12s %-10s %s" (or assignee "nil") state key title) output)))))
;;           (let ((buffer (get-buffer-create "*Linear Issues*")))
;;             (with-current-buffer buffer
;;               (erase-buffer)
;;               (insert (string-join (reverse output) "\n")))
;;             (pop-to-buffer buffer)))))))
;;
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
