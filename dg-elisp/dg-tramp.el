(require 'tramp)
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
     (setq ssh-config-path "~/.ssh/config")
     (setq tramp-ssh-controlmaster-options "")))

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

(defun get-remote-boxes ()
  (let ((ssh-config (get-file-as-string ssh-config-path)))
    (-map
     (lambda (line) (cadr (s-split " " line)))
     (-filter
      (lambda (line) (and (s-matches-p "^Host " line) (not (string-match-p "*" line))))
      ssh-config))))

(defun open-ssh-connection (&optional pfx)
  (interactive)
  (with-temp-buffer
    (let* ((box (ido-completing-read
                 "Which box: " (get-remote-boxes)))
           (buffer (concat "*shell<" box ">*"))
           (default-directory (concat "/ssh:" box ":/")))
      (cd default-directory)
      (with-current-buffer (get-buffer-create (format "*tramp/ssh %s*" box))
        (shell buffer))
      (set-process-query-on-exit-flag
       (get-buffer-process buffer) nil)
      (with-current-buffer buffer
        (insert "cd")
        (comint-send-input nil t)))))

(push
 (cons
  "docker"
  '((tramp-login-program "docker")
    (tramp-login-args (("exec" "-it") ("%h") ("/bin/bash")))
    (tramp-remote-shell "/bin/sh")
    (tramp-remote-shell-args ("-i") ("-c"))))
 tramp-methods)

(defadvice tramp-completion-handle-file-name-all-completions
  (around dotemacs-completion-docker activate)
  "(tramp-completion-handle-file-name-all-completions \"\" \"/docker:\" returns
    a list of active Docker container names, followed by colons."
  (if (equal (ad-get-arg 1) "/docker:")
      (let* ((dockernames-raw (shell-command-to-string "docker ps | awk '$NF != \"NAMES\" { print $NF \":\" }'"))
             (dockernames (cl-remove-if-not
                           #'(lambda (dockerline) (string-match ":$" dockerline))
                           (split-string dockernames-raw "\n"))))
        (setq ad-return-value dockernames))
    ad-do-it))



(provide 'dg-tramp)
