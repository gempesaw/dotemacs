(defun dg-test-dotemacs ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /Applications/Emacs.app/Contents/MacOS/Emacs -batch -L ./ -L ./elpa/ -L ./ert-tests/ -l ert -l ./ert-tests/dg-init-ert.el -f ert-run-tests-batch-and-exit"))

(defun dg-test-dotemacs-interactively ()
  (interactive)
  (compile "cd ~/.emacs.d/ && /Applications/Emacs.app/Contents/MacOS/Emacs"))

(defun dg-start-emacs-q ()
  (interactive)
  (compile "/Applications/Emacs.app/Contents/MacOS/Emacs -Q"))

(provide 'dg-misc)
