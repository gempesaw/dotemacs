(require 'ert)
(require 'dg-sc-defun)

(ert-deftest decide-what-to-restart ()
  (should (sc--box-in-restart-group-p "scqaschedulemaster2f" "all"))
  (should (not (sc--box-in-restart-group-p "scqaschedulemaster2f" "half")))
  (should (not (sc--box-in-restart-group-p "scqaschedulemaster2f" "pubs")))
  (should (sc--box-in-restart-group-p "scqawebauth2f" "all"))
  (should (sc--box-in-restart-group-p "scqawebauth2f" "half"))
  (should (not (sc--box-in-restart-group-p "scqawebauth2f" "pubs"))))

(provide 'dg-sc-ert)
