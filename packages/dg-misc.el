(defun dg-test-dotemacs ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /Applications/Emacs.app/Contents/MacOS/Emacs -batch -L ./ -L ./elpa/ -L ./ert-tests/ -l ert -l ./ert-tests/dg-init-ert.el -f ert-run-tests-batch-and-exit"))

(defun dg-test-dotemacs-interactively ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /usr/local/bin/emacs"))

(defun dg-start-emacs-q ()
  (interactive)
  (compile "/Applications/Emacs.app/Contents/MacOS/Emacs -Q"))

(defun dg-test-current-project ()
  (interactive)
  (let* ((project-root-directory (s-chop-suffix "test/" (cwd)))
         (project-file-guess (car (file-expand-wildcards (concat project-root-directory "*.el") t)))
         (test-file-guess (car (file-expand-wildcards "*test.el" t)) )
         (executable "/Applications/Emacs.app/Contents/MacOS/Emacs -batch"))
    (compile (concat executable
                     " -L ~/.emacs.d/elpa/"
                     " -L " project-root-directory
                     " -l " project-file-guess
                     " -l " test-file-guess
                     " -l ert"
                     " -f ert-run-tests-batch-and-exit"))))

(defun dg-port-divert (in out)
  (with-current-buffer (get-buffer-create "*dg-port*")
    (cd "/sudo::/")
    (async-shell-command
     (format "ipfw add 100 fwd 127.0.0.1,%s tcp from any to me %s && ipfw show" in out)
     "*dg-port*"
     "*dg-port*"))
  (message (buffer-string)))

(defun dg-ipfw-webdriver-vm-redirect ()
  (interactive)
  (dg-port-divert 4443 4444))

(defun dg-ipfw-port-flush ()
  (interactive)
  (with-current-buffer (get-buffer-create "*dg-port*")
    (cd "/sudo::/")
    (async-shell-command "ipfw -f flush && ipfw show" "*dg-port*" "*dg-port*")
    (message (buffer-string))))

(defun dg-encode-uri-component ()
  (interactive)
  (if (not mark-active)
      (message "please highlight text to be encoded")
    (let ((replacement (url-hexify-string (if mark-active
                                              (buffer-substring-no-properties (region-beginning) (region-end))
                                            (read-string "String: ")))))
      (delete-region (region-beginning) (region-end))
      (insert replacement))))

(provide 'dg-misc)
