;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)

(setq cperl-invalid-face 'underline
      cperl-electric-keywords t
      cperl-indent-level 4
      cperl-continued-statement-offset 0

      ;; `if () { <-- bracket on the same line as if
      cperl-extra-newline-before-brace nil
      ;; }
      ;; else { <-- uncuddled elses!
      cperl-merge-trailing-else nil

      cperl-indent-parens-as-block t
      cperl-close-paren-offset -4
      cperl-lazy-help-time 1)

(cperl-lazy-install)

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

(provide 'dg-cperl-mode)
