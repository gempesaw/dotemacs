;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)

(setq cperl-invalid-face 'underline

      ;; autoinsert stuff via spacebar after if, elsif, foreach,
      cperl-electric-keywords t

      cperl-indent-level 4
      cperl-continued-statement-offset 2

      ;; don't automatically newline when semicoloning at the end of a
      ;; line
      cperl-auto-newline nil


      ;; `if () { <-- bracket on the same line as if
      cperl-extra-newline-before-brace nil
      ;; }
      ;; else { <-- uncuddled elses!
      cperl-merge-trailing-else nil

      cperl-indent-parens-as-block t
      cperl-close-paren-offset -4
      cperl-lazy-help-time 0.1)

(cperl-lazy-install)

(setenv "PERL5LIB" (concat (getenv "HOME") "/perl5/lib/perl5"))

(defun execute-perl (&optional arg)
  (interactive "p")
  (let* ((file-name (buffer-file-name (current-buffer)))
         (command (concat "w " file-name))
         (compile-command))
    (if (string-match-p "default.pm" file-name)
        (setq compile-command "perl /opt/honeydew/bin/makePod.pl")
      (if (string-match-p ".t$" file-name)
          (progn
            (setq command (concat "I\"./../lib\" -" command))))
      (when (eq arg 16)
        ;; debug on C-u C-u
        (setq command (concat "d" command)))
      (when (eq arg 4)
        ;; ask questions on C-u
        (setq command (read-from-minibuffer "Edit command: perl -" command )))
      (setq compile-command (concat "perl -" command)))
    (compile compile-command t)
    (if (eq arg 16)
        (progn
          (pop-to-buffer "*compilation*")
          (goto-char (point-max))
          (insert "c")))))

(add-hook 'cperl-mode-hook
          (lambda ()
            (local-set-key (kbd "<f5>") 'execute-perl)
            (local-set-key (kbd "M-.") 'dg-cperl-smarter-find-tag)))

(define-key cperl-mode-map (kbd "M-.") 'dg-cperl-smarter-find-tag)

(progn
  (defun dg-cperl-smarter-find-tag ()
    (interactive)
    (let ((thing (substring-no-properties (thing-at-point 'symbol))))
      (unless (dg-cperl-find-perldoc-tag thing)
        (message "finding tag")
        (find-tag thing))))

  (defun dg-cperl-find-perldoc-tag (arg)
    (let* ((file (substring (shell-command-to-string (concat "perldoc -l " arg)) 0 -1)))
      (message "%s" file)
      (when (file-exists-p file)
        (ring-insert find-tag-marker-ring (point-marker))
        (find-file file)))))

(add-hook 'cperl-mode-hook 'er/add-cperl-mode-expansions)

(provide 'dg-cperl-mode)
