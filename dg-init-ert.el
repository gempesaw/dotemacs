(require 'ert)
(require 'dg-init)

(ert-deftest dg-features-are-available ()
  (should (featurep 'flx-ido)))


;; (compile "emacs -batch -L ~/.emacs.d/ -L /.emacs.d/elpa/ -l ert -l dg-init-ert.el -f ert-run-tests-batch-and-exit")
