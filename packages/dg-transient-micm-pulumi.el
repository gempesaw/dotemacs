;;; -*- lexical-binding: t; -*-

(require 'posframe)
(require 'yaml)

(defvar dg-transient-micm--project nil)
(defvar dg-transient-micm--stack nil)
(defvar dg-transient-micm--profile nil)
(defvar dg-transient-micm--target nil)
(defvar dg-transient-micm--worktree nil)
(defvar dg-transient-aws-login nil)
(defvar dg-transient-micm--export-file nil)
(defvar dg-micm-ssh-posframe-buffer "*micm-ssh-posframe*")

(defvar-local dg-transient-micm--bl-stamped nil
  "Non-nil once this buffer has had pulumi transient settings persisted.")
(defvar-local dg-transient-micm--bl-project nil)
(defvar-local dg-transient-micm--bl-stack nil)
(defvar-local dg-transient-micm--bl-target nil)
(defvar-local dg-transient-micm--bl-worktree nil)

(defvar dg-transient-micm--origin-buffer nil
  "Buffer the transient was last invoked from, for seeding/persisting settings.")

(defun dg-transient-micm--seed-from-buffer (buffer)
  "Copy BUFFER's stamped buffer-local pulumi settings into the globals, so
the transient's init-values auto-populate from them. No-op if BUFFER was
never stamped, leaving the global last-used values in place."
  (when (and (buffer-live-p buffer)
             (buffer-local-value 'dg-transient-micm--bl-stamped buffer))
    (setq dg-transient-micm--project  (buffer-local-value 'dg-transient-micm--bl-project buffer)
          dg-transient-micm--stack    (buffer-local-value 'dg-transient-micm--bl-stack buffer)
          dg-transient-micm--target   (buffer-local-value 'dg-transient-micm--bl-target buffer)
          dg-transient-micm--worktree (buffer-local-value 'dg-transient-micm--bl-worktree buffer))))

(defun dg-transient-micm--stamp-buffer (buffer project stack target worktree)
  "Persist PROJECT/STACK/TARGET/WORKTREE as buffer-local settings in BUFFER."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (setq-local dg-transient-micm--bl-stamped t
                  dg-transient-micm--bl-project project
                  dg-transient-micm--bl-stack stack
                  dg-transient-micm--bl-target target
                  dg-transient-micm--bl-worktree worktree))))

(defvar dg-transient-micm--worktrees-dir "~/opt/infra/.claude/worktrees")

(defvar dg-transient-micm--infra-dir "~/opt/infra")

(defun dg-transient-micm--git (&rest args)
  "Run git ARGS in the infra repo. Return trimmed stdout, or signal on failure."
  (with-temp-buffer
    (let ((status (apply #'process-file "git" nil t nil
                         "-C" (f-expand dg-transient-micm--infra-dir) args)))
      (if (zerop status)
          (s-trim (buffer-string))
        (error "git %s failed: %s" (s-join " " args) (s-trim (buffer-string)))))))

(defun dg-transient-micm--git-ok-p (&rest args)
  "Return non-nil if git ARGS exits zero in the infra repo."
  (zerop (apply #'process-file "git" nil nil nil
                "-C" (f-expand dg-transient-micm--infra-dir) args)))

(defun dg-transient-micm-list-remote-branches ()
  "Return remote-tracking branches, most recently committed first.
Filters the `refs/remotes/origin/HEAD' symref, which `refname:short'
renders as a bare remote name with no branch component."
  (->> (dg-transient-micm--git "for-each-ref" "--sort=-committerdate"
                               "--format=%(refname:short)" "refs/remotes/")
       (s-split "\n")
       (--remove (s-blank-str-p it))
       (--filter (s-contains-p "/" it))))

(defun dg-transient-micm--local-branch-of (remote-ref)
  "Strip the remote name from REMOTE-REF (\"origin/dg/foo\" -> \"dg/foo\")."
  (->> remote-ref (s-split "/") (cdr) (s-join "/")))

(defun dg-transient-micm--worktree-for-branch (local-branch)
  "Return the path of an existing worktree that has LOCAL-BRANCH checked out.
Parses `git worktree list --porcelain' rather than guessing paths, because
worktree directory names need not match their branch names."
  (let ((target (format "refs/heads/%s" local-branch))
        (path nil)
        (result nil))
    (dolist (line (s-split "\n" (dg-transient-micm--git "worktree" "list" "--porcelain")))
      (cond
       ((s-prefix-p "worktree " line)
        (setq path (s-chop-prefix "worktree " line)))
       ((and (s-prefix-p "branch " line)
             (s-equals-p (s-chop-prefix "branch " line) target))
        (setq result path))))
    result))

(defun dg-transient-micm--worktree-path-for-branch (local-branch)
  (f-expand (s-replace "/" "-" (s-chop-prefix "dg/" local-branch))
            (f-expand dg-transient-micm--worktrees-dir)))

(defun dg-transient-micm--ensure-worktree-for-remote (remote-ref)
  "Ensure a worktree exists for REMOTE-REF and return its absolute path.
Reuses an existing worktree if the branch is already checked out in one.
Only ever runs `git worktree add', which creates a brand new directory with
its own HEAD and index — the main ~/opt/infra checkout is never touched."
  (let* ((local-branch (dg-transient-micm--local-branch-of remote-ref))
         (existing (dg-transient-micm--worktree-for-branch local-branch))
         (main-checkout (f-expand dg-transient-micm--infra-dir)))
    (cond
     ;; The main checkout is itself a worktree entry. Never hand it back as a
     ;; worktree to run from — the whole point is an isolated directory. git
     ;; would also refuse to add a second worktree for an already-checked-out
     ;; branch, so say so plainly instead of failing cryptically later.
     ((and existing (f-equal-p existing main-checkout))
      (error "Branch %s is checked out in the main checkout (%s) — switch it there first, or pick another branch"
             local-branch main-checkout))

     ((and existing (f-directory-p existing))
      (message "Reusing existing worktree for %s: %s" local-branch existing)
      existing)

     (t
      (let ((path (dg-transient-micm--worktree-path-for-branch local-branch)))
        (when (f-exists-p path)
          (error "Path %s already exists but is not a worktree for %s" path local-branch))

        (if (dg-transient-micm--git-ok-p "show-ref" "--verify" "--quiet"
                                         (format "refs/heads/%s" local-branch))
            (dg-transient-micm--git "worktree" "add" path local-branch)
          (dg-transient-micm--git "worktree" "add" "--track"
                                  "-b" local-branch path remote-ref))

        (message "Created worktree %s for %s" path remote-ref)
        path)))))

(defun dg-transient-micm-pick-remote-branch ()
  "Fetch, pick a remote branch, materialize it as a worktree, and select it.
Sets the transient's `--worktree=' value so the pulumi run happens via
`uv run --directory <worktree>'."
  (interactive)
  (message "Fetching origin...")
  (dg-transient-micm--git "fetch" "origin")
  (let* ((branches (dg-transient-micm-list-remote-branches))
         (table (lambda (string pred action)
                  (if (eq action 'metadata)
                      '(metadata (display-sort-function . identity)
                                 (cycle-sort-function . identity))
                    (complete-with-action action branches string pred))))
         (selection (completing-read "Remote branch: " table nil t)))
    (when (and selection (not (s-blank-str-p selection)))
      (let ((path (dg-transient-micm--ensure-worktree-for-remote selection)))
        (setq dg-transient-micm--worktree path)
        (when-let* ((obj (--first (and (object-of-class-p it 'transient-option)
                                       (equal (oref it argument) "--worktree="))
                                  transient--suffixes)))
          (transient-infix-set obj path)))))
  (transient--redisplay))


(defun dg-transient-micm-read-projects-stacks ()
  (->> "~/opt/infra/projects"
       (f-expand)
       (funcall (lambda (dirname)
                  (-concat (f-glob "**/Pulumi*yaml" dirname)
                           (f-glob "**/*/Pulumi*yaml" dirname)
                           (f-glob "**/**/*/Pulumi*yaml" dirname))))
       (--filter (not (s-contains-p "Pulumi.yaml" it)))
       (--map (->> it
                   (s-split "/projects/")
                   (cadr)
                   (s-split "/Pulumi.")))
       (--group-by (car it))
       (--map `(,(car it) . ,(-map (lambda (stack) (s-replace ".yaml" "" (cadr stack))) (cdr it))))))

(defun dg-transient-micm-read-urns ()
  (->> (buffer-list)
       (--filter (s-contains-p "*pulumi" (buffer-name it)))
       (--mapcat (with-current-buffer it
                   (->> (s-split "\n" (buffer-substring-no-properties (point-min) (point-max)))
                        (--map (or (cadr (s-match "\\[urn=\\(urn:[^]]+\\)\\]" it))
                                   (cadr (s-match "\\(urn:pulumi:[^] \t\"]+\\)" it))))
                        (-non-nil))))
       (-uniq)))

(defun dg-transient-micm-read-project (prompt initial-input history)
  (let* ((projects (-map #'car (dg-transient-micm-read-projects-stacks)))
         (current-project-directory (-->
                                     (or (buffer-file-name) "/tmp")
                                     (file-name-directory it)
                                     (locate-dominating-file it "Pulumi.yaml")))
         (initial-input (if current-project-directory
                            (--> current-project-directory
                                 (s-split "projects/" it)
                                 (cadr it)
                                 (s-chop-right 1 it))
                          initial-input))
         (project (completing-read prompt projects nil nil initial-input history)))
    (when project
      (setq dg-transient-micm--stack nil
            dg-transient-micm--project project))))

(defun dg-transient-micm-read-stack (prompt initial-input history)
  (let ((stack (completing-read prompt (cdr (assoc dg-transient-micm--project (dg-transient-micm-read-projects-stacks))) nil nil initial-input history)))
    (when stack
      (setq dg-transient-micm--stack stack))))




(defun dg-transient-micm-read-profile (prompt initial-input history)
  (let ((profile (completing-read prompt
                                  (->> "aws-sso list Profile --csv --sso modular && aws-sso list Profile --csv --sso legacy"
                                       (shell-command-to-string)
                                       (s-split "\n")
                                       (--filter it)
                                       (setq dg-transient-micm-aws-account-roles))
                                  nil
                                  nil
                                  initial-input
                                  history)))
    (when profile
      (setq dg-transient-aws-login nil
            dg-transient-micm--profile profile))))

(defun dg-transient-micm-read-target (prompt initial-input history)
  (let* ((urns (dg-transient-micm-read-urns))
         (choices (if urns
                      (cons "" urns)
                    '("")))
         (target (completing-read prompt choices nil nil initial-input history)))
    (setq dg-transient-micm--target (if (string-empty-p target) nil target))))

(defun dg-transient-micm-list-worktrees ()
  "Return absolute worktree paths under `dg-transient-micm--worktrees-dir',
sorted by modification time (most recent first)."
  (let ((dir (f-expand dg-transient-micm--worktrees-dir)))
    (when (f-directory-p dir)
      (->> (directory-files dir t directory-files-no-dot-files-regexp)
           (-filter #'f-directory-p)
           (--sort (time-less-p
                    (file-attribute-modification-time (file-attributes other))
                    (file-attribute-modification-time (file-attributes it))))))))

(defun dg-transient-micm-read-worktree (prompt initial-input history)
  (let* ((paths (dg-transient-micm-list-worktrees))
         (alist (--map (cons (f-filename it) it) paths))
         (names (cons "" (-map #'car alist)))
         (table (lambda (string pred action)
                  (if (eq action 'metadata)
                      '(metadata (display-sort-function . identity)
                                 (cycle-sort-function . identity))
                    (complete-with-action action names string pred))))
         (selection (completing-read prompt table nil t initial-input history)))
    (setq dg-transient-micm--worktree
          (if (string-empty-p selection)
              nil
            (cdr (assoc selection alist))))))

(defclass dg-transient-bare-option (transient-option)
  ((display-fn :initarg :display-fn :initform nil))
  "Like `transient-option', but renders only the value (without the
argument prefix). When `display-fn' is set, it is called on the value
to produce the displayed string.")

(cl-defmethod transient-format-value ((obj dg-transient-bare-option))
  (let* ((value (oref obj value))
         (display-fn (oref obj display-fn))
         (shown (cond ((null value) "")
                      (display-fn (funcall display-fn value))
                      (t value))))
    (propertize shown 'face (if value 'transient-value 'transient-inactive-value))))

(transient-define-argument dg-transient-micm-aws-profile ()
  :description "which AWS profile to use"
  :class 'transient-option
  :key "a"
  :always-read t
  :argument ""
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-micm--profile))
  :reader #'dg-transient-micm-read-profile)

(transient-define-argument dg-transient-micm-project ()
  :description "which pulumi project to operate on"
  :class 'dg-transient-bare-option
  :key "p"
  :always-read t
  :argument "--project="
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-micm--project))
  :reader #'dg-transient-micm-read-project)

(transient-define-argument dg-transient-micm-stack ()
  :description "which pulumi stack to operate on"
  :class 'dg-transient-bare-option
  :key "s"
  :always-read t
  :argument "--stack="
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-micm--stack))
  :reader #'dg-transient-micm-read-stack)

(transient-define-argument dg-transient-micm-target ()
  :description "target specific resource URN"
  :class 'dg-transient-bare-option
  :key "t"
  :always-read t
  :argument "--target="
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-micm--target))
  :reader #'dg-transient-micm-read-target)

(transient-define-argument dg-transient-micm-worktree ()
  :description "run from infra worktree (recency order)"
  :class 'dg-transient-bare-option
  :key "w"
  :always-read t
  :argument "--worktree="
  :display-fn #'f-filename
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-micm--worktree))
  :reader #'dg-transient-micm-read-worktree)

(defun dg-transient-micm-kubie-command (stack)
  (let ((cluster (cond
                  ((s-contains-p "dev" stack) "ci-dev-eks-cluster-74fc2c4")
                  ((and (s-contains-p "github" stack)
                        (s-contains-p "prod" stack)) "ci-github-prod-eks-cluster-49c02d6")
                  (t "ci-dev-eks-cluster-74fc2c4")))
        )
    (format "export KUBECONFIG=$(kubie export %s default)" cluster)))

(defun dg-transient-micm-ignore-deprecation (string)
  (if (or (s-contains-p "unique_name" string)
          (s-contains-p "DeprecationWarning" string))
      ""
    string))

(defun dg-transient-micm-hide-outputs (_string)
  "Post-output filter: collapse the post-apply pulumi `Outputs:' section.
Scans the buffer for any complete `^Outputs:' ... `^Resources:' range and
deletes the inner content (the `Resources:' line is kept). Runs after
insertion, so output streams normally — collapse only happens once
`Resources:' actually appears in the buffer. We scan on every output
chunk because comint can split `Resources:' across chunks, so guarding
on the chunk's own contents would miss real matches.

The `--outputs:--' marker in `preview --diff' is left alone because it
can be followed by legitimate resource diffs before the final `Resources:'
line."
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^Outputs:[[:space:]]*$" nil t)
        (let ((section-start (match-beginning 0)))
          (when (re-search-forward "^Resources:[[:space:]]*$" nil t)
            (goto-char (match-beginning 0))
            (delete-region section-start (point))))))))

(defun dg-transient-micm--get-sso-arg (profile)
  (if (and profile
           (s-starts-with-p "modular.com" profile))
      "--sso legacy"
    "--sso modular"))

(defun dg-transient-micm--submit-at-prompt (cmd)
  "Insert CMD at the comint prompt of the current buffer and submit it
via `comint-send-input', so the command is visible and lands in input
history (`M-p' / `M-n'). After submitting, scroll any window showing the
buffer so the prompt line sits at the top — preserving scrollback while
giving the illusion of a fresh buffer."
  (let ((proc (get-buffer-process (current-buffer))))
    (when proc
      (goto-char (process-mark proc))
      (delete-region (point) (point-max))
      (insert cmd)
      (let ((cmd-line-start (line-beginning-position)))
        (comint-send-input)
        (dolist (win (get-buffer-window-list (current-buffer) nil t))
          (set-window-start win cmd-line-start)
          (set-window-point win (point-max)))))))

(defvar-local dg-transient-micm--queue nil
  "Remaining (CMD . MARKER) pairs to submit. MARKER nil = last/plain cmd.")

(defvar-local dg-transient-micm--queue-expecting nil
  "The marker string the queue watcher is currently waiting for.")

(defun dg-transient-micm--queue-watcher (_output)
  (when dg-transient-micm--queue-expecting
    (let ((re (concat (regexp-quote dg-transient-micm--queue-expecting)
                      "=\\([0-9]+\\)")))
      (when (save-excursion
              (goto-char (point-max))
              (forward-line -30)
              (re-search-forward re nil t))
        (let ((exit (string-to-number (match-string 1)))
              (buf (current-buffer)))
          (setq dg-transient-micm--queue-expecting nil)
          (if (zerop exit)
              (run-at-time
               0 nil
               (lambda ()
                 (when (buffer-live-p buf)
                   (with-current-buffer buf
                     (dg-transient-micm--queue-advance)))))
            (setq dg-transient-micm--queue nil)
            (remove-hook 'comint-output-filter-functions
                         #'dg-transient-micm--queue-watcher t)
            (message "Pulumi presetup failed (exit %d) — chain stopped" exit)))))))

(defun dg-transient-micm--queue-advance ()
  (let ((next (pop dg-transient-micm--queue)))
    (if next
        (let ((cmd (car next))
              (marker (cdr next)))
          (setq dg-transient-micm--queue-expecting marker)
          (unless marker
            (remove-hook 'comint-output-filter-functions
                         #'dg-transient-micm--queue-watcher t))
          (dg-transient-micm--submit-at-prompt
           (if marker
               (format "%s ; echo %s=$?" cmd marker)
             cmd)))
      (setq dg-transient-micm--queue-expecting nil)
      (remove-hook 'comint-output-filter-functions
                   #'dg-transient-micm--queue-watcher t))))

(defun dg-transient-micm--submit-sequence (commands)
  "Submit COMMANDS one at a time, gating each on the previous one's success.
Every command except the last is wrapped with an echo-of-exit-code so the
watcher can detect completion and either advance the queue or bail out. The
last command is submitted bare, so `M-p' in the buffer recalls just it."
  (let* ((n (length commands))
         (queue (cl-loop for cmd in commands
                         for i from 0
                         collect
                         (cons cmd
                               (and (< i (1- n))
                                    (format "DG_MICM_MARK_%s"
                                            (substring
                                             (md5 (format "%d-%d-%s"
                                                          i (random) cmd))
                                             0 8)))))))
    (setq dg-transient-micm--queue queue
          dg-transient-micm--queue-expecting nil)
    (when (> n 1)
      (add-hook 'comint-output-filter-functions
                #'dg-transient-micm--queue-watcher nil t))
    (dg-transient-micm--queue-advance)))

(defun dg-transient-micm-execute (pulumi-sub-command &optional args)
  (interactive (list nil (transient-args transient-current-command)))
  (save-window-excursion
    (let* ((project (transient-arg-value "--project=" args))
           (stack (transient-arg-value "--stack=" args))
           (target (transient-arg-value "--target=" args))
           (worktree (transient-arg-value "--worktree=" args))
           (profile (dg-transient-micm--get-aws-role stack project))
           (_ (when profile
                (dg-modular-ensure-aws-profile-login profile)))
           (target-argument (if target
                                (format "--target '%s' --target-dependents" target)
                              ""))
           (pulumi-passthrough-command (if pulumi-sub-command
                                           (if target
                                               (format "-- %s %s" pulumi-sub-command target-argument)
                                             (format "-- %s" pulumi-sub-command))
                                         ""))
           (sso-arg (dg-transient-micm--get-sso-arg profile))
           (micm-command-prefix (if profile
                                    (format "unset `env | awk -F= '/AWS_/ { print $1 }'` && aws-sso login %s && eval $(aws-sso eval %s --no-region --profile=%s) && aws sts get-caller-identity" sso-arg sso-arg profile)
                                  (format "echo 'No profile found for %s/%s'" project stack)))
           (micm-runner (if worktree
                            (format "uv run --directory %s micm" (shell-quote-argument worktree))
                          "micm"))
           (micm-command (format
                          "%s pulumi --project %s --stack %s %s"
                          micm-runner
                          project
                          stack
                          pulumi-passthrough-command))
           (kubie-export-command (dg-transient-micm-kubie-command stack))
           (buffer-name (format "*pulumi* | %s | %s" project stack))
           (existing-buffer (get-buffer buffer-name))
           (visible-frames (visible-frame-list)))

      ;; Persist the chosen settings back to the buffer the transient was
      ;; invoked from, so re-invoking from there auto-populates them.
      (dg-transient-micm--stamp-buffer dg-transient-micm--origin-buffer
                                       project stack target worktree)

      (let ((setup-command (format "%s && %s"
                                   kubie-export-command
                                   micm-command-prefix)))
        (if existing-buffer
            (with-current-buffer existing-buffer
              (add-hook 'comint-preoutput-filter-functions #'dg-transient-micm-ignore-deprecation nil t)
              (add-hook 'comint-output-filter-functions #'dg-transient-micm-hide-outputs nil t)
              (add-hook 'comint-output-filter-functions #'dg-pulumi-stacks--track-activity nil t)
              (setq-local comint-scroll-show-maximum-output nil
                          comint-move-point-for-output nil)
              (setq dg-pulumi-stacks--last-activity (current-time))
              (dg-transient-micm--stamp-buffer existing-buffer project stack target worktree)
              (dg-transient-micm--submit-sequence (list setup-command micm-command)))

          (let* ((default-directory (f-expand "~/opt/infra"))
                 (buf (create-new-shell-here)))
            (with-current-buffer buf
              (rename-buffer buffer-name t)
              (add-hook 'comint-preoutput-filter-functions #'dg-transient-micm-ignore-deprecation nil t)
              (add-hook 'comint-output-filter-functions #'dg-transient-micm-hide-outputs nil t)
              (add-hook 'comint-output-filter-functions #'dg-pulumi-stacks--track-activity nil t)
              (setq-local comint-scroll-show-maximum-output nil
                          comint-move-point-for-output nil)
              (setq dg-pulumi-stacks--last-activity (current-time))
              (dg-transient-micm--stamp-buffer buf project stack target worktree)
              (dg-transient-micm--submit-sequence (list setup-command micm-command))))))

      ;; if there's another frame with a pulumi window, switch it to this one.
      ;; if there's only a single frame, open a new frame and focus the pulumi buffer.
      (let ((current-frame (selected-frame))
            (other-frame (next-frame (selected-frame))))
        (if other-frame
            ;; There's another frame - switch its pulumi window to this buffer
            (with-selected-frame other-frame
              (if-let* ((pulumi-window (--find (let ((buf (window-buffer it)))
                                                 (and (buffer-live-p buf)
                                                      (string-prefix-p "*pulumi*" (buffer-name buf))))
                                               (window-list)))
                        ((not (string= (buffer-name (window-buffer pulumi-window)) buffer-name))))
                  (set-window-buffer pulumi-window buffer-name)))
          ;; Only one frame - create a new frame and display the pulumi buffer in it
          (let ((new-frame (make-frame)))
            (select-frame-set-input-focus new-frame)
            (switch-to-buffer buffer-name)))
        ))))

(defun dg-transient-micm--get-aws-role (stack &optional project)
  "Dynamically look up AWS profile for STACK and PROJECT.
Reads the Pulumi env config to get the AWS account name, looks it up
in the account mapping to get the account number, then finds the
appropriate automation role in AWS config."
  (let* ((pulumi-file (format "~/opt/infra/projects/%s/Pulumi.%s.yaml" project stack))
         (pulumi-file-expanded (f-expand pulumi-file)))

    (if (not (f-exists-p pulumi-file-expanded))
        ;; Fallback to legacy dispatch for stacks without Pulumi files
        (dg-transient-micm--get-aws-role-legacy stack project)

      ;; Dynamic lookup
      (let* ((pulumi-config (with-temp-buffer
                              (insert-file-contents pulumi-file-expanded)
                              (yaml-parse-string (buffer-string)
                                                 :object-type 'alist
                                                 :sequence-type 'list)))
             (aws-stack-name (alist-get 'stack
                                        (alist-get 'aws
                                                   (alist-get 'identity
                                                              (alist-get 'deployment
                                                                         (alist-get 'modular:platform
                                                                                    (alist-get 'config pulumi-config))))))))

        ;; If there's no AWS config in the Pulumi file, return nil
        (if (not aws-stack-name)
            nil

          (let* ((account-mapping-file (f-expand "~/opt/infra/tools/micm/aws_account_mapping.yaml"))
                 (account-mapping (with-temp-buffer
                                    (insert-file-contents account-mapping-file)
                                    (yaml-parse-string (buffer-string)
                                                       :object-type 'alist
                                                       :sequence-type 'list)))
                 (account-id-raw (alist-get (intern aws-stack-name) account-mapping))
                 (account-id (if (integerp account-id-raw)
                                 (format "%012d" account-id-raw)
                               account-id-raw))
                 (aws-config-file (f-expand "~/.aws/config"))
                 (aws-config (with-temp-buffer
                               (insert-file-contents aws-config-file)
                               (buffer-string)))
                 (profile-regex (format "\\[profile \\([^]]+\\)\\]\n[^\[]*sso_account_id = %s\n[^\[]*sso_role_name = \\(automation-access\\|automation-prev-access\\)" account-id))
                 (profiles (let (result)
                             (with-temp-buffer
                               (insert aws-config)
                               (goto-char (point-min))
                               (while (re-search-forward profile-regex nil t)
                                 (let ((profile-name (match-string 1))
                                       (role-type (match-string 2)))
                                   (push (cons profile-name role-type) result))))
                             (nreverse result)))
                 (automation-access-profile (--find (string= (cdr it) "automation-access") profiles))
                 (automation-prev-profile (--find (string= (cdr it) "automation-prev-access") profiles)))

            (or (car automation-access-profile)
                (car automation-prev-profile)
                (dg-transient-micm--get-aws-role-legacy stack project))))))))

(defun dg-transient-micm--get-aws-role-legacy (stack &optional project)
  "Legacy manual dispatch for AWS roles based on stack/project names."
  (cond

   ((s-contains-p "dns" project) "modular.com.super-user-8ed90a7")
   ((s-contains-p "dev" stack) "modular.com.super-user-8ed90a7")
   ((s-contains-p "github" stack) "modular.com.super-user-8ed90a7")
   ((s-contains-p "karpenter" stack) "modular.com.super-user-8ed90a7")
   ((s-contains-p "platform" stack) "modular.com.super-user-8ed90a7")
   ((or (s-contains-p "external" project)
        (s-contains-p "destination" project)
        (s-contains-p "mammoth" project))
    (if (or (s-contains-p "staging" stack)
            (s-contains-p "external" stack))
        "external-staging-4afbf9a6.automation-access-91b319d"
      "external-prod-8e65a7d5.automation-access-91b319d"))

   ((s-contains-p "networking" project)
    (if (s-contains-p "staging" stack)
        "networking-staging-2875ef80.automation-access-91b319d"
      "networking-prod-3bdb3844.automation-prev-access-0a74a01"))

   ((s-contains-p "workspaces" project) "Management.AdministratorAccess")
   ((s-contains-p "management" project) "Management.AdministratorAccess")

   ((s-contains-p "east1" stack) "internal-dev-workloads-ef01a06b.automation-access-91b319d")
   ((and (s-contains-p "prod" stack)
         (not (s-contains-p "staging" stack))) "internal-prod-c6646158.automation-access-91b319d")
   ((s-contains-p "staging" stack) "internal-staging-c56d17e7.automation-access-91b319d")

   (t (completing-read "Select AWS profile: "
                       (->> (shell-command-to-string "aws configure list-profiles")
                            (s-split "\n")
                            (--filter (s-contains-p "automation-access" it)))))))

(defvar-local dg-transient-micm--export-signal nil
  "Token to watch for in comint output to detect export completion.")
(defvar-local dg-transient-micm--export-target nil
  "Path of the export temp file the watcher should open on completion.")

(defun dg-transient-micm--export-watcher (output)
  (when (and dg-transient-micm--export-signal
             (string-match-p (regexp-quote dg-transient-micm--export-signal) output))
    (let ((file dg-transient-micm--export-target))
      (setq dg-transient-micm--export-signal nil
            dg-transient-micm--export-target nil)
      (remove-hook 'comint-output-filter-functions
                   #'dg-transient-micm--export-watcher t)
      (if (and file (file-readable-p file)
               (> (file-attribute-size (file-attributes file)) 0))
          (progn
            (find-file file)
            (json-mode)
            (message "Pulumi state exported to buffer. Edit and use 'm i' to import."))
        (message "Pulumi export completion echo arrived but %s is missing/empty"
                 file)))))

(defun dg-transient-micm-export-state (&optional args)
  "Export pulumi state to a temp file and open it in a buffer for editing."
  (interactive (list (transient-args transient-current-command)))
  (let* ((project (transient-arg-value "--project=" args))
         (stack (transient-arg-value "--stack=" args))
         (sanitized-project (replace-regexp-in-string "[/\\]" "-" project))
         (sanitized-stack (replace-regexp-in-string "[/\\]" "-" stack))
         (temp-file (concat (make-temp-name
                             (expand-file-name
                              (format "pulumi-state-%s-%s-"
                                      sanitized-project sanitized-stack)
                              temporary-file-directory))
                            ".json"))
         (signal-token (format "DG_PULUMI_EXPORT_DONE_%s" (md5 temp-file)))
         (buffer-name (format "*pulumi* | %s | %s" project stack)))
    (setq dg-transient-micm--export-file temp-file)
    (message "Exporting state to %s..." temp-file)
    (dg-transient-micm-execute
     (format "stack export --show-secrets --file %s && echo '%s'"
             (shell-quote-argument temp-file)
             signal-token)
     args)
    (when-let* ((buf (get-buffer buffer-name)))
      (with-current-buffer buf
        (setq dg-transient-micm--export-signal signal-token
              dg-transient-micm--export-target temp-file)
        (add-hook 'comint-output-filter-functions
                  #'dg-transient-micm--export-watcher nil t))
      (run-with-timer
       300 nil
       (lambda ()
         (when (buffer-live-p buf)
           (with-current-buffer buf
             (when (equal dg-transient-micm--export-signal signal-token)
               (setq dg-transient-micm--export-signal nil
                     dg-transient-micm--export-target nil)
               (remove-hook 'comint-output-filter-functions
                            #'dg-transient-micm--export-watcher t)
               (message "Pulumi export timed out after 5min — check %s for errors"
                        buffer-name))))))) ))

(defun dg-transient-micm-import-state (&optional args)
  "Import pulumi state from the current buffer or exported file."
  (interactive (list (transient-args transient-current-command)))
  (let ((import-file
         (cond
          ;; If we're in a buffer visiting the export file, use that
          ((and buffer-file-name
                dg-transient-micm--export-file
                (string= buffer-file-name dg-transient-micm--export-file))
           (save-buffer)
           buffer-file-name)
          ;; If we have an export file, use it
          (dg-transient-micm--export-file
           dg-transient-micm--export-file)
          ;; Otherwise prompt for file
          (t
           (read-file-name "Import state from file: ")))))
    (when import-file
      (dg-transient-micm-execute (format "stack import --file %s" (shell-quote-argument import-file)) args))))

(defun dg-transient-micm-fetch-urns (project stack)
  (let* ((profile (dg-transient-micm--get-aws-role stack project))
         (sso-arg (dg-transient-micm--get-sso-arg profile))
         (kubie-export-command (dg-transient-micm-kubie-command stack))
         (auth-command (if profile
                           (format "unset `env | awk -F= '/AWS_/ { print $1 }'`; eval $(aws-sso eval %s --no-region --profile=%s)"
                                   sso-arg profile)
                         (error "No profile found for %s/%s" project stack)))
         (micm-command (format "micm pulumi --project %s --stack %s -- stack --show-urns --show-secrets" project stack))
         (full-command (format "cd ~/opt/infra && %s; %s; %s 2>/dev/null" kubie-export-command auth-command micm-command))
         (output (shell-command-to-string full-command)))
    (->> output
         (s-split "\n")
         (--filter (s-contains-p "urn:pulumi" it))
         (--map (s-trim (car (last (s-split " " (s-trim it))))))
         (-uniq))))

(defun dg-transient-micm-state-delete (&optional args)
  (interactive (list (transient-args transient-current-command)))
  (let* ((project (transient-arg-value "--project=" args))
         (stack (transient-arg-value "--stack=" args))
         (buffer-urns (dg-transient-micm-read-urns))
         (urns (or buffer-urns
                   (progn
                     (message "Fetching URNs for %s/%s..." project stack)
                     (dg-transient-micm-fetch-urns project stack))))
         (urn (completing-read "Delete resource from state: " urns nil t)))
    (when (and urn (not (string-empty-p urn))
               (yes-or-no-p (format "Delete %s from state?" urn)))
      (dg-transient-micm-execute (format "state delete --yes '%s'" urn) args))))

(transient-define-prefix dg-transient-micm ()
  "choose project, stack, and operation"

  ["Options"
   (dg-transient-micm-project)
   (dg-transient-micm-stack)
   (dg-transient-micm-target)
   (dg-transient-micm-worktree)
   ("b" "fetch + pick remote branch as worktree"
    dg-transient-micm-pick-remote-branch :transient t)
   ]

  ["Actions"
   [("m p" "plan" (lambda (&optional args)
                    (interactive (list (transient-args transient-current-command)))
                    (dg-transient-micm-execute "preview --diff --show-secrets" args)))

    ("m s" "preview, summary" (lambda (&optional args)
                                (interactive (list (transient-args transient-current-command)))
                                (dg-transient-micm-execute "preview --show-secrets" args)))

    ("m r" "refresh" (lambda (&optional args)
                       (interactive (list (transient-args transient-current-command)))
                       (dg-transient-micm-execute "refresh --run-program " args)))

    ("m a" "apply" (lambda (&optional args)
                     (interactive (list (transient-args transient-current-command)))
                     (dg-transient-micm-execute "up --yes --skip-preview" args)))

    ("m o" "outputs" (lambda (&optional args)
                       (interactive (list (transient-args transient-current-command)))
                       (dg-transient-micm-execute "stack output --show-secrets" args)))

    ("m u" "urns" (lambda (&optional args)
                    (interactive (list (transient-args transient-current-command)))
                    (dg-transient-micm-execute "stack --show-urns --show-secrets" args)))

    ("m x" "export state" dg-transient-micm-export-state)

    ("m i" "import state" dg-transient-micm-import-state)

    ("m D" "state delete" dg-transient-micm-state-delete)

    ("m d" "dashboard" dg-pulumi-stacks)
    ]])


(defun dg-transient-aws-profile-open-console (profile)

  (if (s-contains-p ":" profile)
      (let* ((account-id (caar (--filter (s-equals-p (cadr it) profile) dg-transient-micm-aws-account-roles)))
             (role-name (nth 1 (s-split ":" profile)))
             (start-url (if (s-equals-p account-id "466483404629")
                            "https://d-9067baa9e0.awsapps.com/start/#"
                          "https://d-906789f3a0.awsapps.com/start/#"))
             (console-url (format "%s/console?account_id=%s&role_name=%s"
                                  start-url
                                  account-id
                                  role-name))
             )
        (browse-url console-url))
    (let* ((profile (dg-modular-ensure-aws-profile-login profile))
           (account-id (s-trim (shell-command-to-string "aws configure get sso_account_id")))
           (role-name (s-trim (shell-command-to-string "aws configure get sso_role_name")))
           (start-url (if (s-equals-p account-id "466483404629")
                          "https://d-9067baa9e0.awsapps.com/start/#"
                        "https://d-906789f3a0.awsapps.com/start/#"))
           (console-url (format "%s/console?account_id=%s&role_name=%s"
                                start-url
                                account-id
                                role-name)))

      (browse-url console-url)))
  )



(transient-define-prefix dg-transient-aws-profile ()
  ["profile" (dg-transient-micm-aws-profile)]

  ["login"
   [("SPC" "authenticate shell" (lambda (&optional args)
                                  (interactive (list (transient-args transient-current-command)))
                                  (let* ((profile (nth 0 args))
                                         (sso-arg (dg-transient-micm--get-sso-arg profile)))
                                    (dg-modular-ensure-aws-profile-login profile)
                                    (dg-transient-aws-sso-set-emacs-env profile)
                                    (dg-maybe-ghostel-submit
                                     (format "eval $(aws-sso eval %s --no-region --profile=%s) && unset AWS_PROFILE" sso-arg profile)))))

    ("e" "authenticate emacs environment" (lambda (&optional args)
                                            (interactive (list (transient-args transient-current-command)))
                                            (let ((profile (nth 0 args)))
                                              (dg-modular-ensure-aws-profile-login profile)
                                              (dg-transient-aws-sso-set-emacs-env profile))))

    ("b" "open logged-in browser" (lambda (&optional args)
                                    (interactive (list (transient-args transient-current-command)))
                                    (let ((profile (nth 0 args)))
                                      (dg-transient-aws-profile-open-console profile))))

    ]])

(defun dg-transient-aws-sso-set-emacs-env (profile)
  "Set AWS environment variables in Emacs from aws-sso eval output.
Also writes credentials to ~/.aws/credentials under the profile name."
  (let* (;; (reset (->> process-environment
         ;;             (--filter (s-starts-with? "AWS_" it))
         ;;             (--map (setenv (car (s-split "=" it)) nil))))
         (sso-argument (dg-transient-micm--get-sso-arg profile))
         (output (shell-command-to-string
                  (format "aws-sso login %s && aws-sso eval %s --no-region --profile=%s" sso-argument sso-argument profile)))
         (lines (split-string output "\n" t))
         (access-key-id nil)
         (secret-access-key nil)
         (session-token nil))

    (dolist (line lines)
      (when (string-match "^export \\([A-Z_]+\\)=\"\\(.*\\)\"$" line)
        (let ((var-name (match-string 1 line))
              (var-value (match-string 2 line)))
          (setenv var-name var-value)
          (message "Set %s" var-name)
          (cond
           ((string= var-name "AWS_ACCESS_KEY_ID") (setq access-key-id var-value))
           ((string= var-name "AWS_SECRET_ACCESS_KEY") (setq secret-access-key var-value))
           ((string= var-name "AWS_SESSION_TOKEN") (setq session-token var-value))))))

    (when (and access-key-id secret-access-key)
      (dg-transient-aws-sso--update-credentials-file profile access-key-id secret-access-key session-token))
    (message "AWS SSO credentials set in Emacs environment for profile: %s" profile)))

(defun dg-transient-aws-sso--update-credentials-file (profile access-key-id secret-access-key &optional session-token)
  "Update ~/.aws/credentials with an agent-prefixed section for PROFILE.
Preserves other existing sections in the file.
Uses \"agent-\" prefix to avoid colliding with SSO profiles in ~/.aws/config."
  (let* ((creds-file (expand-file-name "~/.aws/credentials"))
         (agent-profile (concat "agent-" profile))
         (existing (if (file-exists-p creds-file)
                       (with-temp-buffer
                         (insert-file-contents creds-file)
                         (buffer-string))
                     ""))
         (section-re (format "^\\[%s\\]" (regexp-quote agent-profile)))
         (new-section (format "[%s]\naws_access_key_id = %s\naws_secret_access_key = %s\n%s"
                              agent-profile
                              access-key-id
                              secret-access-key
                              (if session-token
                                  (format "aws_session_token = %s\n" session-token)
                                "")))
         (cleaned (if (string-match-p section-re existing)
                      (replace-regexp-in-string
                       (format "\\[%s\\][^\[]*" (regexp-quote agent-profile))
                       ""
                       existing)
                    existing))
         (result (concat (string-trim-right cleaned) "\n\n" new-section "\n")))
    (with-temp-file creds-file
      (insert result))
    (message "Wrote credentials for %s to ~/.aws/credentials [%s]" profile agent-profile)))

(defun dg-transient-aws-profile-login ()
  (interactive)
  (setq dg-transient-aws-login t)
  (run-with-timer 0 nil (lambda () (dg-transient-aws-profile))))

(defun dg-transient-micm-open ()
  (interactive)
  (window-configuration-to-register ?Z)
  (setq dg-pulumi-stacks--origin-frame (selected-frame))
  (setq dg-transient-micm--origin-buffer (current-buffer))
  (dg-transient-micm--seed-from-buffer (current-buffer))
  (dg-transient-micm))

(key-chord-define-global "zp" 'dg-transient-micm-open)
(key-chord-define-global ",/" 'dg-transient-aws-profile-login)

(load-file "/Users/gempesaw/.emacs.d/packages/dg-pulumi-stacks.el")

(provide 'dg-transient-micm-pulumi)


;; (let* ((credentials (->> "aws configure export-credentials --output=json"
;;                          (shell-command-to-string)
;;                          (json-read-from-string)))
;;        (access-key-id (alist-get 'AccessKeyId credentials))
;;        (secret-access-key (alist-get 'SecretAccessKey credentials))
;;        (session-token (alist-get 'SessionToken credentials))
;;        (signin-token-json (json-serialize
;;                            `((sessionId . ,access-key-id)
;;                              (sessionKey . ,secret-access-key)
;;                              (sessionToken . ,session-token))))
;;        (encoded-signin-token (url-hexify-string signin-token-json))
;;        (console-url (concat "https://signin.aws.amazon.com/federation"
;;                             "?Action=login"
;;                             "&Issuer=Emacs"
;;                             "&Destination=https%3A%2F%2Fconsole.aws.amazon.com%2F"
;;                             "&SigninToken=" encoded-signin-token))
;;        )
;;   (kill-new console-url))

(defun dg-micm-ssh-with-posframe ()
  "Run micm ssh in a small posframe window for faster fzf+coterm, then switch to normal window."
  (interactive)
  (let* ((shell-buffer-name "*micm-ssh-shell*")
         (shell-buffer (get-buffer shell-buffer-name)))

    ;; Kill existing shell buffer if it exists
    (when shell-buffer
      (kill-buffer shell-buffer))

    ;; Create a new shell buffer
    (let ((new-shell-buffer (shell shell-buffer-name)))

      ;; Show the shell in a small posframe
      (posframe-show new-shell-buffer
                     :poshandler #'posframe-poshandler-frame-center
                     :width 60
                     :height 15
                     :border-width 2
                     :internal-border-width 10
                     :internal-border-color "#555555"
                     :background-color "#1e1e1e")

      ;; Switch to the shell buffer in the posframe
      (with-current-buffer new-shell-buffer
        ;; Set up a hook to detect when coterm/fzf is done
        (let ((original-buffer new-shell-buffer))
          (add-hook 'comint-output-filter-functions
                    (lambda (text)
                      ;; When we see a prompt after micm ssh completes, hide posframe
                      (when (and (get-buffer original-buffer)
                                 (string-match-p "bash-[0-9.]+\\$\\|\\$" text))
                        (run-with-timer 0.1 nil
                                        (lambda ()
                                          ;; Hide the posframe
                                          (posframe-hide original-buffer)
                                          ;; Switch to the shell buffer in a normal window
                                          (switch-to-buffer original-buffer)
                                          ;; Clean up the hook
                                          (remove-hook 'comint-output-filter-functions
                                                       'dg-micm-ssh-completion-hook)))))
                    nil t))

        ;; Send the micm ssh command
        (insert "micm ssh")
        (comint-send-input)))))
