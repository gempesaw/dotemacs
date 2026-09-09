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
    ;; Assignment first, export second: `export V=$(cmd)' exits 0 even when
    ;; cmd fails, but a plain assignment propagates the substitution's status.
    (format "KUBECONFIG=\"$(kubie export %s default)\" && export KUBECONFIG" cluster)))

(defvar dg-transient-micm--unset-aws-env
  "unset `env | awk -F= '/^AWS_/ { print $1 }'`"
  "Strip inherited AWS_* variables from the shell.
Anchored to `^AWS_' so it matches variable names. The old pattern matched
anywhere in `env' output, so a variable whose *value* mentioned AWS_ got
its own name printed and unset instead.")

(defun dg-transient-micm--login-command (profile &optional account-id)
  "Shell chain that authenticates to PROFILE, asserting ACCOUNT-ID when known.

Every step is `&&'-joined so the queue watcher's exit-status gate stops
the chain the moment one fails. With ACCOUNT-ID the last step is a proof:
pulumi does not start unless `sts get-caller-identity' reports it.
Without that check the chain only established that *some* credentials
existed, which a stale AWS_* pair inherited from Emacs satisfies happily.

ACCOUNT-ID is nil for the identities micm's aws_account_mapping.yaml does
not name. `ensure_local_aws_account_matches_stack' returns early on those
too, so asserting here would refuse runs micm is content to make."
  (let ((sso (dg-transient-micm--get-sso-arg profile)))
    (s-join
     " && "
     (-non-nil
      (list dg-transient-micm--unset-aws-env
            (format "aws-sso login %s" sso)
            ;; Assign before eval: `eval $(cmd)' evaluates empty output with
            ;; exit 0 when cmd fails, and the failure resurfaces later as a
            ;; baffling NoCredentials from sts, after the chain moved on.
            (format "DG_AWS_CREDS=\"$(aws-sso eval %s --no-region --profile=%s)\"" sso profile)
            "eval \"$DG_AWS_CREDS\""
            "unset DG_AWS_CREDS"
            (when account-id
              "DG_AWS_ACCOUNT=\"$(aws sts get-caller-identity --query Account --output text)\"")
            (when account-id
              (format
               (concat "{ [ \"$DG_AWS_ACCOUNT\" = %s ] "
                       "|| { echo \">>> WRONG AWS ACCOUNT: wanted %s (%s), got $DG_AWS_ACCOUNT\" >&2; false; }; }")
               (shell-quote-argument account-id) account-id profile))
            (when account-id "unset DG_AWS_ACCOUNT")
            (format "echo \">>> authenticated as %s%s\""
                    profile
                    (if account-id (format " in %s" account-id) " (account unverified)")))))))

(defun dg-transient-micm--no-identity-command (project stack)
  "Shell command for a stack that declares no AWS identity.
Such a stack needs no credentials, so it gets none: the inherited AWS_*
variables are stripped and no login runs. Passing through is what micm
does -- it is only stacks with a *declared* account that it checks -- and
refusing here would block the ones that legitimately touch no AWS."
  (format "%s && echo \">>> %s/%s declares no AWS identity — running without credentials\""
          dg-transient-micm--unset-aws-env project stack))

(defun dg-transient-micm-hide-outputs (window &optional _force)
  "Collapse the post-apply pulumi `Outputs:' section in this buffer.
Runs from `ghostel-inhibit-anchor-functions', which fires after every
redraw with WINDOW's buffer current.

Ghostel owns the buffer text and repaints the viewport from the terminal
grid on every frame, so the comint implementation's `delete-region' would
desync the renderer. Mark the section invisible instead and re-apply it
per redraw, the same way the submitted-input face is maintained. The scan
starts at WINDOW's first visible line so the cost stays bounded by the
window rather than the whole scrollback; the closing `Resources:' line is
searched for beyond it because the section can run past the window.

Always returns nil, so window anchoring is never vetoed.

The `--outputs:--' marker in `preview --diff' is left alone because it can
be followed by legitimate resource diffs before the final `Resources:'."
  (ignore-errors
    (with-silent-modifications
      (save-excursion
        (goto-char (window-start window))
        (let ((limit (window-end window t)))
          (while (re-search-forward "^Outputs:[[:space:]]*$" limit t)
            (let ((section-start (match-beginning 0)))
              (when (re-search-forward "^Resources:[[:space:]]*$" nil t)
                (let ((section-end (match-beginning 0)))
                  (unless (get-text-property section-start 'invisible)
                    (put-text-property section-start section-end
                                       'invisible t))))))))))
  nil)

(defun dg-transient-micm--get-sso-arg (profile)
  (if (and profile
           (s-starts-with-p "modular.com" profile))
      "--sso legacy"
    "--sso modular"))

(defvar-local dg-transient-micm--run-start nil
  "Marker at the first line of the run currently displayed in this buffer.")

(defun dg-transient-micm--submit-at-prompt (cmd)
  "Send CMD to this buffer's ghostel terminal and scroll it to the top.
`dg-maybe-ghostel-submit' both writes the line and records it in the
history ring, so the command stays recallable with `M-p'. Scrolling the
command line to the top of the window preserves scrollback while giving
the illusion of a fresh buffer."
  (let ((start (point-max)))
    (dg-maybe-ghostel-submit cmd)
    (setq dg-transient-micm--run-start (copy-marker start))
    (dolist (win (get-buffer-window-list (current-buffer) nil t))
      (set-window-start win start)
      (set-window-point win (point-max)))))

(defvar-local dg-transient-micm--queue nil
  "Commands still to submit in this buffer, in order.")

(defvar-local dg-transient-micm--saw-command-start nil
  "Non-nil once an OSC 133 C marker arrived for the command in flight.
Bash emits a D (finish) marker on bare prompt redraws too, so a finish
only counts as ours when a start preceded it.")

(defvar-local dg-transient-micm--on-setup-success nil
  "Thunk run once, when a gated step in the queue first reports exit 0.
Used to piggyback Emacs-side AWS env syncing on the shell's login, which
is the authoritative check.")

(defvar-local dg-transient-micm--on-complete nil
  "Thunk run once, after the final queued command exits 0.")

(defun dg-transient-micm--queue-cleanup ()
  (setq dg-transient-micm--queue nil
        dg-transient-micm--saw-command-start nil)
  (remove-hook 'ghostel-command-start-functions
               #'dg-transient-micm--command-started t)
  (remove-hook 'ghostel-command-finish-functions
               #'dg-transient-micm--command-finished t))

(defun dg-transient-micm--command-started (&rest _)
  (setq dg-transient-micm--saw-command-start t
        dg-pulumi-stacks--last-activity (current-time)))

(defun dg-transient-micm--command-finished (buffer exit)
  "Advance the queue when the command in flight finishes.
EXIT is the real status reported by OSC 133, so no output scraping is
needed. Ignores the bare prompt redraws bash also reports as finishes."
  (setq dg-pulumi-stacks--last-activity (current-time))
  (when (and dg-transient-micm--saw-command-start (buffer-live-p buffer))
    (setq dg-transient-micm--saw-command-start nil)
    (if (and exit (not (zerop exit)))
        (let ((remaining dg-transient-micm--queue))
          (dg-transient-micm--queue-cleanup)
          (message (if remaining
                       "Pulumi step failed (exit %d) — chain stopped"
                     "Pulumi command failed (exit %d)")
                   exit))
      (when dg-transient-micm--on-setup-success
        (let ((thunk dg-transient-micm--on-setup-success))
          (setq dg-transient-micm--on-setup-success nil)
          (run-at-time 0 nil thunk)))
      ;; The hook fires synchronously from the terminal parser, so defer
      ;; until the buffer is fully rendered before writing into it.
      (run-at-time
       0 nil
       (lambda ()
         (when (buffer-live-p buffer)
           (with-current-buffer buffer
             (dg-transient-micm--queue-advance))))))))

(defun dg-transient-micm--queue-advance ()
  (let ((next (pop dg-transient-micm--queue)))
    (if next
        (dg-transient-micm--submit-at-prompt next)
      (let ((thunk dg-transient-micm--on-complete))
        (setq dg-transient-micm--on-complete nil)
        (dg-transient-micm--queue-cleanup)
        (when thunk (run-at-time 0 nil thunk))))))

(defun dg-transient-micm--start-queue-when-ready (buffer &optional tries)
  "Kick off BUFFER's queue once its shell has drawn a prompt.
A brand-new ghostel accepts sent keys before bash has even started
reading input, so submitting immediately races shell startup — the
command text lands ahead of the login banner and may be dropped. Poll
`ghostel--prompt-positions' (populated at the first OSC 133 prompt)
instead of hooking command-finish, because the very first prompt of a
session emits no finish marker to hook onto."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (cond
       (ghostel--prompt-positions
        (dg-transient-micm--queue-advance))
       ((> (or tries 0) 50)
        (dg-transient-micm--queue-cleanup)
        (message "Pulumi: shell in %s never drew a prompt — chain abandoned"
                 (buffer-name buffer)))
       (t
        (run-at-time 0.2 nil #'dg-transient-micm--start-queue-when-ready
                     buffer (1+ (or tries 0))))))))

(defun dg-transient-micm--submit-sequence (commands)
  "Submit COMMANDS one at a time, gating each on the previous one's exit code.
Ghostel reports exit status natively through OSC 133, so unlike the comint
implementation this needs no `echo $?' wrapping and no output scraping —
the finish hook hands us the real status. A non-zero status stops the chain
and leaves the failure on screen."
  (setq dg-transient-micm--queue commands
        dg-transient-micm--saw-command-start nil)
  (add-hook 'ghostel-command-start-functions
            #'dg-transient-micm--command-started nil t)
  (add-hook 'ghostel-command-finish-functions
            #'dg-transient-micm--command-finished nil t)
  (dg-transient-micm--start-queue-when-ready (current-buffer)))

(defun dg-transient-micm--real-frames ()
  "Return the visible top-level frames.
`frame-list' is not a list of the user's windows onto the world: it also
reports the invisible minibuffer frame and the child frames corfu and
posframe keep permanently allocated. Counting those makes the
single-frame case unreachable — there are always four or five of them —
and a visible completion popup would read as somebody's workspace."
  (--filter (not (frame-parent it)) (visible-frame-list)))

(defun dg-transient-micm--display-pulumi-buffer (buf)
  "Show BUF without disturbing frames that are not already showing pulumi.
A frame already displaying a `*pulumi*' buffer is the user's monitor for
these runs, so reuse its window. A frame showing anything else is not:
leave it alone entirely and display here instead.

Operates on the buffer object — never its name, which may have been
uniquified out from under a string lookup. Always leaves BUF displayed:
a ghostel terminal that has never had a window renders nothing and never
reports OSC 133 command start/finish, so a run submitted into an
undisplayed buffer stalls silently."
  (let* ((other-frames (--remove (eq it (selected-frame))
                                 (dg-transient-micm--real-frames)))
         ;; Scan every other frame, not just `next-frame': with three frames
         ;; the pulumi monitor is often not the next one round the ring.
         (pulumi-window
          (car (delq nil
                     (--map (--find (let ((wb (window-buffer it)))
                                      (and (buffer-live-p wb)
                                           (string-prefix-p "*pulumi*" (buffer-name wb))))
                                    (window-list it 'no-mini))
                            other-frames)))))
    (cond
     ;; A frame already showing some pulumi run is the monitor — reuse it.
     (pulumi-window
      (unless (eq (window-buffer pulumi-window) buf)
        (set-window-buffer pulumi-window buf)))

     ;; Already on screen somewhere: nothing to disturb.
     ((get-buffer-window buf t))

     ;; Sole frame: a dedicated frame for the run is welcome.
     ((null other-frames)
      (let ((new-frame (make-frame)))
        (select-frame-set-input-focus new-frame)
        (switch-to-buffer buf)))

     ;; Other frames exist but none of them is showing pulumi, so they are
     ;; somebody else's workspace — display here rather than stealing one of
     ;; their windows. `inhibit-switch-frame' keeps `display-buffer' from
     ;; wandering off to another frame to do it.
     (t
      (display-buffer buf (append dg-ghostel-display-action
                                  '((inhibit-switch-frame . t))))))))

(defun dg-transient-micm-execute (pulumi-sub-command &optional args on-complete)
  "Run PULUMI-SUB-COMMAND for the project/stack in ARGS in a ghostel terminal.
ON-COMPLETE, when given, is a thunk run after the pulumi command exits 0."
  (interactive (list nil (transient-args transient-current-command)))
  (progn
    (let* ((project (transient-arg-value "--project=" args))
           (stack (transient-arg-value "--stack=" args))
           (target (transient-arg-value "--target=" args))
           (worktree (transient-arg-value "--worktree=" args))
           ;; Resolve the identity from the same tree the run executes in --
           ;; see `dg-transient-micm--resolve-identity'.
           (identity (dg-transient-micm--resolve-identity stack project worktree))
           (profile (car identity))
           (target-argument (if target
                                (format "--target '%s' --target-dependents" target)
                              ""))
           (pulumi-passthrough-command (if pulumi-sub-command
                                           (if target
                                               (format "-- %s %s" pulumi-sub-command target-argument)
                                             (format "-- %s" pulumi-sub-command))
                                         ""))
           ;; No declared identity means the stack touches no AWS, so it runs
           ;; with the inherited AWS_* stripped and no login. The old branch
           ;; here echoed "No profile found" and exited 0, which let the queue
           ;; advance into pulumi with whatever credentials were lying around
           ;; -- the pass-through has to clear them, not merely skip the login.
           (micm-command-prefix (if identity
                                    (dg-transient-micm--login-command profile (cdr identity))
                                  (dg-transient-micm--no-identity-command project stack)))
           (micm-runner (if worktree
                            (format "uv run --directory %s micm" (shell-quote-argument worktree))
                          "micm"))
           ;; Suppress the deprecation noise at the source. The comint
           ;; implementation stripped these lines with a preoutput filter;
           ;; ghostel renders from the terminal grid, so there is no text to
           ;; rewrite before it lands — tell Python not to emit them instead.
           (micm-command (format
                          "PYTHONWARNINGS=ignore::DeprecationWarning %s pulumi --project %s --stack %s %s"
                          micm-runner
                          project
                          stack
                          pulumi-passthrough-command))
           (kubie-export-command (dg-transient-micm-kubie-command stack))
           (buffer-name (format "*pulumi* | %s | %s" project stack))
           (existing-buffer (get-buffer buffer-name)))

      ;; Persist the chosen settings back to the buffer the transient was
      ;; invoked from, so re-invoking from there auto-populates them.
      (dg-transient-micm--stamp-buffer dg-transient-micm--origin-buffer
                                       project stack target worktree)

      ;; The shell chain below is the authoritative login gate: `aws-sso login'
      ;; runs there, and the queue watcher holds the pulumi command until it
      ;; exits 0. Doing the login in Emacs too would only duplicate it — and
      ;; would freeze the UI for the whole browser flow.
      (let ((setup-command (format "echo '>>> AWS login (%s) — Emacs is not blocked, hang tight...' && %s && %s"
                                   (or profile "none declared")
                                   kubie-export-command
                                   micm-command-prefix))
            ;; Nothing to sync back when the stack authenticates to nothing.
            (sync-env (and profile
                           (lambda () (dg-transient-micm--sync-aws-env-async profile))))
            (buf nil))
        ;; Acquire the buffer inside an excursion: `dg-ghostel-new-here'
        ;; displays into the current frame, and that layout change should
        ;; not stick — the authoritative display happens below.
        (save-window-excursion
          ;; Reuse the terminal only while it still has a live shell; a dead
          ;; ghostel buffer cannot be typed into, so start a fresh one.
          (setq buf (if (and existing-buffer
                             (buffer-live-p existing-buffer)
                             (buffer-local-value 'ghostel--term existing-buffer))
                        existing-buffer
                      (let ((default-directory (f-expand "~/opt/infra")))
                        (dg-ghostel-new-here))))
          (with-current-buffer buf
            ;; Renaming also pins the name: ghostel only auto-renames a
            ;; buffer whose name it still owns, so the OSC 7 directory
            ;; tracker stops renaming this one out from under us.
            (unless (equal (buffer-name) buffer-name)
              ;; A dead pulumi buffer can squat on the canonical name (its
              ;; shell exited but the buffer survived). Renaming would then
              ;; uniquify to a <N> name, the run would land in a buffer no
              ;; window ever shows, and ghostel never renders or reports
              ;; OSC 133 for an undisplayed buffer — the silent stall this
              ;; eviction exists to prevent.
              (when-let* ((squatter (get-buffer buffer-name)))
                (unless (buffer-local-value 'ghostel--term squatter)
                  (let ((kill-buffer-query-functions nil))
                    (kill-buffer squatter))))
              (rename-buffer buffer-name t))
            (add-hook 'ghostel-inhibit-anchor-functions
                      #'dg-transient-micm-hide-outputs nil t)
            (setq dg-pulumi-stacks--last-activity (current-time))
            (dg-transient-micm--stamp-buffer buf project stack target worktree)))

        ;; Display before submitting, outside the excursion so it persists.
        (dg-transient-micm--display-pulumi-buffer buf)

        (with-current-buffer buf
          (setq dg-transient-micm--on-setup-success sync-env
                dg-transient-micm--on-complete on-complete)
          (dg-transient-micm--submit-sequence (list setup-command micm-command)))))))

(defun dg-transient-micm--resolve-identity (stack &optional project root)
  "Return (PROFILE . ACCOUNT-ID) for STACK and PROJECT, or nil for no AWS.

ACCOUNT-ID comes from the stack's own `deployment.identity.aws.stack'
resolved through micm's account mapping, so it is what the stack declares
it targets -- never merely the account whichever profile we picked happens
to belong to. `dg-transient-micm--login-command' asserts against it, which
is only meaningful because the two are derived independently.

PROFILE is the automation role for that account when ~/.aws/config has
one. When it does not, the legacy name dispatch supplies a profile but
ACCOUNT-ID stays the declared one, so a wrong guess trips the assertion
instead of quietly satisfying it.

Returns nil when the stack declares no AWS identity, which callers treat
as "needs no credentials" rather than as an error -- see
`dg-transient-micm--no-identity-command'.

ROOT is the infra checkout to read from, defaulting to the main one. The
run itself happens under `uv run --directory <worktree>', so reading the
identity from anywhere else answers a question about a different revision
of the stack: a branch that adds the identity block looks like a stack
that has none."
  (let* ((root (or root dg-transient-micm--infra-dir))
         (pulumi-file (f-join (f-expand root) "projects" project
                              (format "Pulumi.%s.yaml" stack)))
         (pulumi-file-expanded (f-expand pulumi-file)))

    (if (not (f-exists-p pulumi-file-expanded))
        ;; No file, so no declared identity and nothing to assert against.
        nil

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

        (if (not aws-stack-name)
            nil

          (let* ((account-mapping-file (f-join (f-expand root) "tools/micm/aws_account_mapping.yaml"))
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
                 (automation-prev-profile (--find (string= (cdr it) "automation-prev-access") profiles))
                 (profile (or (car automation-access-profile)
                              (car automation-prev-profile)
                              (dg-transient-micm--get-aws-role-legacy stack project))))

            ;; Pair the profile with the *declared* account, not with its own.
            ;; Asserting a guessed profile against the account that profile
            ;; belongs to would compare a number to itself and always pass.
            ;;
            ;; account-id is nil for the identities the mapping does not name
            ;; -- prod-aws-global and aws-global between them cover 86 stacks,
            ;; and both point at identity stacks whose account lives in pulumi
            ;; state rather than any yaml. Still log in; just do not claim to
            ;; have verified where. micm returns early on these as well.
            (when profile
              (cons profile account-id))))))))

(defun dg-transient-micm--get-aws-role (stack &optional project root)
  "Return just the AWS profile for STACK and PROJECT under ROOT.
See `dg-transient-micm--resolve-identity', which also yields the account
the run must land in."
  (car (dg-transient-micm--resolve-identity stack project root)))

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

(defun dg-transient-micm--open-export (file)
  "Open FILE, the just-written pulumi state export, for editing."
  (if (and file (file-readable-p file)
           (> (file-attribute-size (file-attributes file)) 0))
      (progn
        (find-file file)
        (json-mode)
        (message "Pulumi state exported to buffer. Edit and use 'm i' to import."))
    (message "Pulumi export reported success but %s is missing or empty" file)))

(defun dg-transient-micm-export-state (&optional args)
  "Export pulumi state to a temp file and open it in a buffer for editing.
The export command's own exit status decides when (and whether) the file
is opened, so this needs no echoed completion token, no output scraping,
and no timeout — a failed export simply never fires the callback."
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
                            ".json")))
    (setq dg-transient-micm--export-file temp-file)
    (message "Exporting state to %s..." temp-file)
    (dg-transient-micm-execute
     (format "stack export --show-secrets --file %s"
             (shell-quote-argument temp-file))
     args
     (lambda () (dg-transient-micm--open-export temp-file)))))

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

(defun dg-transient-micm-fetch-urns (project stack &optional worktree)
  "Read the URNs in PROJECT/STACK, authenticating first.
Resolves the identity from WORKTREE when given, for the same reason
`dg-transient-micm--resolve-identity' takes a root.

Shares the login chain with the run path, so this reaches
`--show-secrets' only after the same account assertion. The steps are
`&&'-joined for that reason: the old `;' separators ran the micm command
even when the login before it had failed."
  (let* ((root (or worktree dg-transient-micm--infra-dir))
         (identity (dg-transient-micm--resolve-identity stack project worktree))
         (kubie-export-command (dg-transient-micm-kubie-command stack))
         (auth-command (if identity
                           (dg-transient-micm--login-command (car identity) (cdr identity))
                         (dg-transient-micm--no-identity-command project stack)))
         (micm-command (format "micm pulumi --project %s --stack %s -- stack --show-urns --show-secrets" project stack))
         (full-command (format "cd %s && %s && %s && %s 2>/dev/null"
                               (shell-quote-argument (f-expand root))
                               kubie-export-command auth-command micm-command))
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
         (worktree (transient-arg-value "--worktree=" args))
         (buffer-urns (dg-transient-micm-read-urns))
         (urns (or buffer-urns
                   (progn
                     (message "Fetching URNs for %s/%s..." project stack)
                     (dg-transient-micm-fetch-urns project stack worktree))))
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

(defun dg-transient-micm--apply-aws-eval-output (profile output)
  "Apply `aws-sso eval' OUTPUT for PROFILE to the Emacs environment.
Sets the AWS_* variables, records PROFILE as current, and refreshes the
`[agent-PROFILE]' section of ~/.aws/credentials. Returns non-nil when a
usable key pair was found. Pure post-processing — does no I/O of its own,
so it is safe to call from a process sentinel."
  (let (access-key-id secret-access-key session-token)
    (dolist (line (split-string output "\n" t))
      (when (string-match "^export \\([A-Z_]+\\)=\"\\(.*\\)\"$" line)
        (let ((var-name (match-string 1 line))
              (var-value (match-string 2 line)))
          (setenv var-name var-value)
          (cond
           ((string= var-name "AWS_ACCESS_KEY_ID") (setq access-key-id var-value))
           ((string= var-name "AWS_SECRET_ACCESS_KEY") (setq secret-access-key var-value))
           ((string= var-name "AWS_SESSION_TOKEN") (setq session-token var-value))))))

    (when (and access-key-id secret-access-key)
      (dg-transient-aws-sso--update-credentials-file
       profile access-key-id secret-access-key session-token)
      (setenv "AWS_PROFILE" profile)
      (setq dg-modular-aws-profile profile)
      t)))

(defun dg-transient-micm--sync-aws-env-async (profile)
  "Refresh Emacs's AWS env and ~/.aws/credentials for PROFILE in the background.
Assumes an SSO session already exists — call this only after a login has
succeeded — so `aws-sso eval' returns promptly and never prompts. Uses
`make-process' so the Emacs UI is never blocked."
  (when profile
    (let* ((sso-arg (dg-transient-micm--get-sso-arg profile))
           (buf (generate-new-buffer " *dg-aws-sso-eval*")))
      (make-process
       :name "dg-aws-sso-eval"
       :buffer buf
       :noquery t
       :connection-type 'pipe
       :command (list shell-file-name "-lc"
                      (format "aws-sso eval %s --no-region --profile=%s"
                              sso-arg profile))
       :sentinel
       (lambda (proc _event)
         (when (memq (process-status proc) '(exit signal))
           (let ((code (process-exit-status proc))
                 (output (and (buffer-live-p buf)
                              (with-current-buffer buf (buffer-string)))))
             (when (buffer-live-p buf) (kill-buffer buf))
             (cond
              ((not (zerop code))
               (message "AWS env sync for %s failed (exit %d)" profile code))
              ((dg-transient-micm--apply-aws-eval-output profile output)
               (message "AWS env synced in background for %s" profile))
              (t
               (message "AWS env sync for %s returned no credentials" profile))))))))))

(defun dg-transient-aws-sso-set-emacs-env (profile)
  "Set AWS environment variables in Emacs from aws-sso eval output.
Also writes credentials to ~/.aws/credentials under the profile name.
Blocks on the SSO browser flow — used by the interactive profile transient,
where waiting is the point. Pulumi runs use the async path instead."
  (let* ((sso-argument (dg-transient-micm--get-sso-arg profile))
         (output (shell-command-to-string
                  (format "aws-sso login %s && aws-sso eval %s --no-region --profile=%s"
                          sso-argument sso-argument profile))))
    (dg-transient-micm--apply-aws-eval-output profile output)
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

;; The directory loader gets to dg-pulumi-stacks on its own, but not
;; necessarily before this file, and the transient's `m d' entry needs
;; `dg-pulumi-stacks' bound at definition time.
(require 'dg-pulumi-stacks
         (expand-file-name "packages/dg-pulumi-stacks.el" user-emacs-directory))

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
  "Run micm ssh in a small centered posframe, then switch to a normal window.
The posframe originally existed to keep fzf usable under comint, which was
slow enough to need a tiny window. Ghostel gives fzf a real TTY, so the
posframe is now only about keeping the picker compact — and the session
moves to a normal window once the command exits, reported by OSC 133
rather than sniffed out of the output stream."
  (interactive)
  (when-let* ((existing (get-buffer "*micm-ssh-shell*")))
    (kill-buffer existing))
  (let ((buf (save-window-excursion (dg-ghostel-new-here))))
    (with-current-buffer buf
      (rename-buffer "*micm-ssh-shell*" t)
      (when (posframe-workable-p)
        (posframe-show buf
                       :poshandler #'posframe-poshandler-frame-center
                       :width 60
                       :height 15
                       :border-width 2
                       :internal-border-width 10
                       :internal-border-color "#555555"
                       :background-color "#1e1e1e"
                       :accept-focus t))
      (add-hook 'ghostel-command-finish-functions
                (lambda (b &optional _exit)
                  (run-at-time
                   0 nil
                   (lambda ()
                     (when (buffer-live-p b)
                       (posframe-delete-frame b)
                       (switch-to-buffer b)))))
                nil t)
      (dg-maybe-ghostel-submit "micm ssh"))
    buf))
