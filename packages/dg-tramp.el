;;; -*- lexical-binding: t; -*-
(use-package tramp
  :config
  ;; Problem with TRAMP mode: Control Path too long error
  ;; TMPDIR variable is really large
  ;; http://lists.macosforge.org/pipermail/macports-tickets/2011-June/084295.html
  ;; https://github.com/gwtaylor/dotfiles/blob/master/.emacs.d/darwin.el
  (setenv "TMPDIR" "/tmp/")

  (defun tramp-send-command-and-read (vec command &optional noerror)
    "Run COMMAND and return the output, which must be a Lisp expression.
In case there is no valid Lisp expression and NOERROR is nil, it
raises an error."
    (when (string= command "/usr/bin/id -gn | sed -e s/^/\\\"/ -e s/$/\\\"/")
      (setq command "which id"))
    (when (if noerror
              (tramp-send-command-and-check vec command)
            (tramp-barf-unless-okay
             vec command "`%s' returns with error" command))
      (with-current-buffer (tramp-get-connection-buffer vec)
        ;; Read the expression.
        (goto-char (point-min))
        (condition-case nil
            (prog1 (read (current-buffer))
              ;; Error handling.
              (when (re-search-forward "\\S-" (point-at-eol) t)
                (error nil)))
          (error (unless noerror
                   (tramp-error
                    vec 'file-error
                    "`%s' does not return a valid Lisp expression: `%s'"
                    command (buffer-string))))))))

  ;; tramp settings
  (eval-after-load "tramp"
    '(progn
       (setq tramp-default-method "ssh")
       (setq tramp-auto-save-directory "~/tmp/tramp/")
       (setq tramp-chunksize 2000)
       (setq tramp-default-user "dgempesaw")
       (setq ssh-config-path "~/.ssh/config")
       (setq auth-source-save-behavior nil)
       (setq tramp-ssh-controlmaster-options "")
       (setq vc-ignore-dir-regexp
             (format "\\(%s\\)\\|\\(%s\\)"
                     vc-ignore-dir-regexp
                     tramp-file-name-regexp))))

  (defun reset-ssh-connections ()
    (interactive)
    (tramp-cleanup-all-connections)
    (let ((tramp-buffers (-filter (lambda (item)
                                    (string-match "*tramp" (buffer-name item)))
                                  (buffer-list))))
      (while tramp-buffers
        (kill-buffer (car tramp-buffers))
        (setq tramp-buffers (cdr tramp-buffers))))
    (delete-hung-ssh-sessions))

  (defun delete-hung-ssh-sessions ()
    (interactive)
    (let* ((dir "~/.ssh/sockets/")
           (cm-socket-files (directory-files dir t "-" t)))
      (while cm-socket-files
        (delete-file (car cm-socket-files))
        (setq cm-socket-files (cdr cm-socket-files)))))

  (defun get-remote-names ()
    (interactive)
    (let ((ssh-config (get-file-as-string ssh-config-path) )
          (ssh-host-names))
      (while ssh-config
        (let ((line (car ssh-config)))
          (if (and (string-match-p "Host " line)
                   (not (string-match-p "*" line))
                   (not (string-match-p "^# " line)))
              (setq ssh-host-names (cons (cadr (split-string line " "))
                                         ssh-host-names))))
        (setq ssh-config (cdr ssh-config)))
      ssh-host-names))


  (defvar dg-tramp-micm-ssh-boxes '())
  (defun dg-tramp--parse-micm-output (output)
    (->> (s-split "\n" output t)
         (--map (car (split-string it)))
         ;; (--filter (s-contains-p "/" it))
         ))

  (defun get-remote-micm-boxes-sync ()
    (interactive)
    (let ((default-directory (expand-file-name "~/opt/infra/")))
      (setq dg-tramp-micm-ssh-boxes
            (dg-tramp--parse-micm-output
             (shell-command-to-string "uv run micm ssh --list 2>/dev/null")))))

  (defun get-remote-micm-boxes ()
    (interactive)
    (let ((default-directory (expand-file-name "~/opt/infra/"))
          (bpr-show-progress nil)
          (bpr-on-success (lambda (process)
                            (with-current-buffer (process-buffer process)
                              (setq dg-tramp-micm-ssh-boxes
                                    (dg-tramp--parse-micm-output
                                     (buffer-substring-no-properties (point-min) (point-max))))))))
      (bpr-spawn "uv run --directory ~/opt/infra micm ssh --list 2>/dev/null")))

  (defun get-remote-boxes ()
    (let ((ssh-config (get-file-as-string ssh-config-path)))
      (-concat (-map
                (lambda (line) (cadr (s-split " " line)))
                (-filter
                 (lambda (line) (and (s-matches-p "^Host " line) (not (string-match-p "*" line))))
                 ssh-config))
               dg-tramp-micm-ssh-boxes)))

  (defun open-ssh-connection (&optional pfx)
    (interactive)
    (when (null dg-tramp-micm-ssh-boxes)
      (get-remote-micm-boxes-sync))
    (get-remote-micm-boxes)
    (with-temp-buffer
      (let ((box (completing-read "Which box: " (get-remote-boxes))))
        (cond
         ((s-contains-p "/" box)
          (dg-maybe-ghostel-new-here)
          (dg-maybe-ghostel-submit (format "micm ssh %s" box)))
         (dg-use-ghostel
          (dg-ghostel-new-here)
          (dg-maybe-ghostel-submit (format "ssh %s" box)))
         (t
          (let* ((_ (shell-command-to-string (format "ssh %s ls -al" box)))
                 (buffer (concat "*shell<" box ">*"))
                 (default-directory (concat "/sshx:ubuntu@" box ":/")))
            (cd default-directory)
            (with-current-buffer (get-buffer-create (format "*tramp/ssh %s*" box))
              (shell buffer))
            (set-process-query-on-exit-flag
             (get-buffer-process buffer) nil)
            (with-current-buffer buffer
              (insert "cd")
              (comint-send-input nil t))))))))
  )
