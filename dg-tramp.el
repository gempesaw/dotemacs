(require 'tramp)
;; Problem with TRAMP mode: Control Path too long error
;; TMPDIR variable is really large
;; http://lists.macosforge.org/pipermail/macports-tickets/2011-June/084295.html
;; https://github.com/gwtaylor/dotfiles/blob/master/.emacs.d/darwin.el
(setenv "TMPDIR" "/tmp/")

;; tramp settings
(eval-after-load "tramp"
  '(progn
     (setq tramp-default-method "ssh")
     (setq tramp-auto-save-directory "~/tmp/tramp/")
     (setq tramp-chunksize 2000)
     (setq ssh-config-path "~/.ssh/config")))

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
  (let* ((dir "~/.ssh/cm/")
         (cm-socket-files (directory-files dir nil nil t)))
    (while cm-socket-files
      (let ((filename (car cm-socket-files)))
        (if (not (or (string= "." filename)
                  (string= ".." filename)))
            (if (string-match "terminus" filename)
                (delete-file (concat dir filename))))
        (setq cm-socket-files (cdr cm-socket-files))))))

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

(defun get-user-for-remote-box ()
  (interactive)
  (let ((ssh-config (get-file-as-string ssh-config-path) )
        (ssh-remote-info)
        (ssh-user-remote-pairs))
    (while ssh-config
      (let ((host-line (car ssh-config))
            (user-line (caddr ssh-config)))
        (if (and (string-match-p "Host " host-line)
               (not (string-match-p "*" host-line))
               (not (string-match-p "*" user-line))
               (not (string-match-p "^# " host-line))
               (not (string-match-p "^# " user-line)))
            (add-to-list 'ssh-user-remote-pairs
                         `(,(car (last (split-string host-line " ")))
                           ,(car (last (split-string user-line " "))))))
        (setq ssh-config (cdr ssh-config))))
    ssh-user-remote-pairs))

(defun open-ssh-connection (&optional pfx)
  (interactive)
  (let ((remote-info (get-user-for-remote-box))
        (shell-file-name "/bin/bash")
        (buffer)
        (box))
    (if (eq nil pfx)
        (setq box (ido-completing-read "Which box: " (mapcar 'car remote-info)))
      (setq box pfx))
    (setq buffer (concat "*shell<" box ">*"))
    (let ((default-directory (concat "/" box ":/home/" (cadr (assoc box remote-info)) "/")))
      (shell buffer))
    (set-process-query-on-exit-flag (get-buffer-process buffer) nil)))

(provide 'dg-tramp)
