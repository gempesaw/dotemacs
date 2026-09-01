;;; -*- lexical-binding: t; -*-



(defvar dg-pulumi-stacks--origin-frame nil)

(defvar dg-pulumi-stacks--update-timer nil)

(defvar dg-pulumi-stacks--filter nil)

(defvar dg-pulumi-stacks--all-entries nil)

(defvar-local dg-pulumi-stacks--last-activity nil
  "Time of the most recent shell output in this pulumi buffer.")

(defun dg-pulumi-stacks--track-activity (_string)
  (setq dg-pulumi-stacks--last-activity (current-time)))

(defun dg-pulumi-stacks--get-buffer (project stack)
  (get-buffer (format "*pulumi* | %s | %s" project stack)))

(defun dg-pulumi-stacks--process-status (buf)
  "Return a status string for the pulumi terminal in BUF.
Ghostel terminals report whether a command is in flight through OSC 133,
which is exact — `process-running-child-p' only sees the shell's direct
child and does not see through a PTY reliably, so prefer the marker and
keep the process probe as the fallback."
  (if (not buf)
      "-"
    (let ((proc (get-buffer-process buf)))
      (cond
       ((not proc) "exited")
       ((not (process-live-p proc)) "finished")
       ((buffer-local-value 'ghostel--term buf)
        (if (buffer-local-value 'ghostel--command-running buf) "running" "idle"))
       ((process-running-child-p proc) "running")
       (t "idle")))))

(defun dg-pulumi-stacks--build-entries ()
  "Rebuild the dashboard entries, preserving marks across the rebuild.
Refreshes fire from a timer shortly after every dashboard-initiated run,
so marks set in the meantime must survive — otherwise `x'/`X' silently
find nothing marked moments after the user marked a row."
  (let* ((marked-ids (--map (car it)
                            (--filter (dg-pulumi-stacks--marked-p it)
                                      dg-pulumi-stacks--all-entries)))
         (projects-stacks (dg-transient-micm-read-projects-stacks))
         (entries (--mapcat
                   (let ((project (car it)))
                     (--map
                      (let* ((stack it)
                             (buf (dg-pulumi-stacks--get-buffer project stack))
                             (status (dg-pulumi-stacks--process-status buf))
                             (mark (if (member (cons project stack) marked-ids) "*" " ")))
                        (list (cons project stack)
                              (vector mark project stack status)))
                      (cdr it)))
                   projects-stacks)))
    (--sort
     (let* ((id1 (car it))
            (id2 (car other))
            (b1 (dg-pulumi-stacks--get-buffer (car id1) (cdr id1)))
            (b2 (dg-pulumi-stacks--get-buffer (car id2) (cdr id2)))
            (t1 (and b1 (buffer-local-value 'dg-pulumi-stacks--last-activity b1)))
            (t2 (and b2 (buffer-local-value 'dg-pulumi-stacks--last-activity b2))))
       (cond
        ((and t1 t2) (time-less-p t2 t1))
        (b1 t)
        (b2 nil)
        (t nil)))
     entries)))

(defun dg-pulumi-stacks--marked-p (entry)
  (s-equals-p "*" (aref (cadr entry) 0)))

(defun dg-pulumi-stacks--apply-filter (entries)
  (if (not dg-pulumi-stacks--filter)
      entries
    (let ((type (car dg-pulumi-stacks--filter))
          (val (cdr dg-pulumi-stacks--filter)))
      (--filter
       (let ((project (aref (cadr it) 1))
             (stack (aref (cadr it) 2)))
         (or (dg-pulumi-stacks--marked-p it)
             (pcase type
               ('project (s-contains-p val project t))
               ('stack (s-contains-p val stack t)))))
       entries))))

(defun dg-pulumi-stacks--refresh ()
  (interactive)
  (setq dg-pulumi-stacks--all-entries (dg-pulumi-stacks--build-entries))
  (setq tabulated-list-entries
        (dg-pulumi-stacks--apply-filter dg-pulumi-stacks--all-entries))
  (tabulated-list-print t))

(defun dg-pulumi-stacks--follow ()
  (when dg-pulumi-stacks--update-timer
    (cancel-timer dg-pulumi-stacks--update-timer))
  (let* ((win (selected-window))
         (frame (selected-frame))
         (id (tabulated-list-get-id))
         (buf (when id
                (dg-pulumi-stacks--get-buffer (car id) (cdr id)))))
    (when buf
      (setq dg-pulumi-stacks--update-timer
            (run-with-idle-timer
             0.1 nil
             (lambda ()
               (when (and buf (buffer-live-p buf)
                          (window-live-p win) (frame-live-p frame))
                 (with-selected-frame frame
                   (let ((other (--first (not (eq it win))
                                         (window-list frame 'no-mini))))
                     (unless other
                       (setq other (split-window win nil 'right)))
                     (set-window-buffer other buf)
                     (with-selected-window other
                       (goto-char (point-max))
                       (recenter -1))
                     (select-window win))))))))))

(defvar dg-pulumi-stacks-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") #'dg-pulumi-stacks-next)
    (define-key map (kbd "p") #'dg-pulumi-stacks-prev)
    (define-key map (kbd "m") #'dg-pulumi-stacks-mark)
    (define-key map (kbd "u") #'dg-pulumi-stacks-unmark)
    (define-key map (kbd "U") #'dg-pulumi-stacks-unmark-all)
    (define-key map (kbd "t") #'dg-pulumi-stacks-toggle-marks)
    (define-key map (kbd "/ p") #'dg-pulumi-stacks-filter-project)
    (define-key map (kbd "/ s") #'dg-pulumi-stacks-filter-stack)
    (define-key map (kbd "/ /") #'dg-pulumi-stacks-filter-clear)
    (define-key map (kbd "x") #'dg-pulumi-stacks-execute)
    (define-key map (kbd "X") #'dg-pulumi-stacks-execute-up)
    (define-key map (kbd "k") #'dg-pulumi-stacks-kill)
    (define-key map (kbd "w") #'dg-pulumi-stacks-set-worktree)
    (define-key map (kbd "RET") #'dg-pulumi-stacks-visit)
    (define-key map (kbd "g") #'dg-pulumi-stacks--refresh)
    (define-key map (kbd "q") #'dg-pulumi-stacks-quit)
    map))

(define-derived-mode dg-pulumi-stacks-mode tabulated-list-mode "Pulumi"
  (setq tabulated-list-format [("M" 1 t)
                               ("Project" 35 t)
                               ("Stack" 30 t)
                               ("Status" 10 t)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header)
  (setq-local header-line-format '(:eval (dg-pulumi-stacks--header-line))))

(defun dg-pulumi-stacks--header-line ()
  (substitute-command-keys
   (format "\\<dg-pulumi-stacks-mode-map>m:mark  u:unmark  t:toggle  /p:project  /s:stack  //:clear  x:preview  X:up  k:kill  w:worktree[%s]  n/p:browse  g:refresh  q:quit"
           (if dg-transient-micm--worktree
               (f-filename dg-transient-micm--worktree)
             "-"))))

(defun dg-pulumi-stacks-next ()
  (interactive)
  (forward-line 1)
  (dg-pulumi-stacks--follow))

(defun dg-pulumi-stacks-prev ()
  (interactive)
  (forward-line -1)
  (dg-pulumi-stacks--follow))

(defun dg-pulumi-stacks-visit ()
  (interactive)
  (when-let* ((id (tabulated-list-get-id))
              (buf (dg-pulumi-stacks--get-buffer (car id) (cdr id)))
              ((buffer-live-p buf)))
    (switch-to-buffer buf)))

(defun dg-pulumi-stacks-mark ()
  (interactive)
  (when-let* ((id (tabulated-list-get-id))
              (entry (--first (equal (car it) id) dg-pulumi-stacks--all-entries)))
    (aset (cadr entry) 0 "*"))
  (forward-line 1)
  (dg-pulumi-stacks--refresh-display))

(defun dg-pulumi-stacks-unmark ()
  (interactive)
  (when-let* ((id (tabulated-list-get-id))
              (entry (--first (equal (car it) id) dg-pulumi-stacks--all-entries)))
    (aset (cadr entry) 0 " "))
  (forward-line 1)
  (dg-pulumi-stacks--refresh-display))

(defun dg-pulumi-stacks-unmark-all ()
  (interactive)
  (--each dg-pulumi-stacks--all-entries
    (aset (cadr it) 0 " "))
  (dg-pulumi-stacks--refresh-display))

(defun dg-pulumi-stacks-toggle-marks ()
  (interactive)
  (--each tabulated-list-entries
    (aset (cadr it) 0 (if (s-equals-p "*" (aref (cadr it) 0)) " " "*")))
  (dg-pulumi-stacks--refresh-display))

(defun dg-pulumi-stacks--refresh-display ()
  (setq tabulated-list-entries
        (dg-pulumi-stacks--apply-filter dg-pulumi-stacks--all-entries))
  (tabulated-list-print t))

(defun dg-pulumi-stacks-filter-project ()
  (interactive)
  (let ((val (read-string "Filter project: ")))
    (setq dg-pulumi-stacks--filter (cons 'project val))
    (dg-pulumi-stacks--refresh-display)))

(defun dg-pulumi-stacks-filter-stack ()
  (interactive)
  (let ((val (read-string "Filter stack: ")))
    (setq dg-pulumi-stacks--filter (cons 'stack val))
    (dg-pulumi-stacks--refresh-display)))

(defun dg-pulumi-stacks-filter-clear ()
  (interactive)
  (setq dg-pulumi-stacks--filter nil)
  (dg-pulumi-stacks--refresh-display))

(defun dg-pulumi-stacks--target-entries ()
  "Entries to act on: the marked ones, or the row at point when none are.
The point fallback matters because every dashboard-initiated run unmarks
what it ran, so a bare `x'/`X' repeat would otherwise hit nothing."
  (or (--filter (dg-pulumi-stacks--marked-p it) dg-pulumi-stacks--all-entries)
      (when-let* ((id (tabulated-list-get-id)))
        (--filter (equal (car it) id) dg-pulumi-stacks--all-entries))))

(defun dg-pulumi-stacks--run-on-marked (sub-command)
  (let ((targets (dg-pulumi-stacks--target-entries)))
    (unless targets
      (user-error "No stacks marked and no stack at point"))
    (--each targets
      (let* ((project (car (car it)))
             (stack (cdr (car it)))
             (args (-non-nil
                    (list (format "--project=%s" project)
                          (format "--stack=%s" stack)
                          (when dg-transient-micm--worktree
                            (format "--worktree=%s" dg-transient-micm--worktree))))))
        (dg-transient-micm-execute sub-command args)))
    (message "Launched `%s' on %s"
             (car (s-split " " sub-command))
             (s-join ", " (--map (format "%s/%s" (car (car it)) (cdr (car it))) targets)))
    (dolist (m targets)
      (when-let* ((entry (--first (equal (car it) (car m))
                                  dg-pulumi-stacks--all-entries)))
        (aset (cadr entry) 0 " ")))
    (run-with-timer 2 nil
                    (lambda ()
                      (when-let* ((buf (get-buffer "*pulumi-stacks*")))
                        (with-current-buffer buf
                          (dg-pulumi-stacks--refresh)))))))

(defun dg-pulumi-stacks-execute ()
  (interactive)
  (dg-pulumi-stacks--run-on-marked "preview --diff --show-secrets"))

(defun dg-pulumi-stacks-execute-up ()
  (interactive)
  (let* ((targets (dg-pulumi-stacks--target-entries))
         (names (--map (format "%s/%s" (car (car it)) (cdr (car it))) targets)))
    (unless targets
      (user-error "No stacks marked and no stack at point"))
    (when (yes-or-no-p (format "Run `pulumi up` on: %s?" (s-join ", " names)))
      (dg-pulumi-stacks--run-on-marked "up --yes --skip-preview"))))

(defun dg-pulumi-stacks-kill ()
  (interactive)
  (when-let* ((id (tabulated-list-get-id))
              (buf (dg-pulumi-stacks--get-buffer (car id) (cdr id))))
    (let ((active (equal "running" (dg-pulumi-stacks--process-status buf))))
      (when (or (not active)
                (yes-or-no-p (format "Pulumi appears to be running in %s/%s. Kill anyway? "
                                     (car id) (cdr id))))
        (let ((kill-buffer-query-functions nil))
          (kill-buffer buf))
        (dg-pulumi-stacks--refresh)))))

(defun dg-pulumi-stacks-set-worktree ()
  (interactive)
  (dg-transient-micm-read-worktree "Worktree (empty to clear): " nil nil)
  (force-mode-line-update))

(defun dg-pulumi-stacks-quit ()
  (interactive)
  (jump-to-register ?Z))

(defun dg-pulumi-stacks ()
  (interactive)
  (let* ((buf (get-buffer-create "*pulumi-stacks*"))
         (frame (or dg-pulumi-stacks--origin-frame (selected-frame))))
    (select-frame-set-input-focus frame)
    (delete-other-windows)
    (with-current-buffer buf
      (dg-pulumi-stacks-mode)
      (setq dg-pulumi-stacks--filter nil)
      (dg-pulumi-stacks--refresh))
    (switch-to-buffer buf)
    (goto-char (point-min))
    (dg-pulumi-stacks--follow)))

(provide 'dg-pulumi-stacks)
