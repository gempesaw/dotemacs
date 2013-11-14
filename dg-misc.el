(defun dg-test-dotemacs ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /Applications/Emacs.app/Contents/MacOS/Emacs -batch -L ./ -L ./elpa/ -L ./ert-tests/ -l ert -l ./ert-tests/dg-init-ert.el -f ert-run-tests-batch-and-exit"))

(defun dg-test-dotemacs-interactively ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /Applications/Emacs.app/Contents/MacOS/Emacs"))

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

(provide 'dg-misc)
