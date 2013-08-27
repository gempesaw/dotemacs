(defun dg-test-dotemacs ()
  (interactive)
  (compile "cd ~/.emacs.d/ && which emacs && emacs -batch -L ./ -L ./elpa/ -L ./ert-tests/ -l ert -l ./ert-tests/dg-init-ert.el -f ert-run-tests-batch-and-exit"))

(provide 'dg-misc)
