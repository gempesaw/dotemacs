(require 'ert)
(require 'dg-sc)

(ert-deftest decide-what-to-restart ()
  (should (sc--box-in-restart-group-p "scdwschedulemaster2f" "all"))
  (should (not (sc--box-in-restart-group-p "scdwschedulemaster2f" "half")))
  (should (not (sc--box-in-restart-group-p "scdwschedulemaster2f" "pubs")))
  (should (sc--box-in-restart-group-p "scdwwebauth2f" "all"))
  (should (sc--box-in-restart-group-p "scdwwebauth2f" "half"))
  (should (not (sc--box-in-restart-group-p "scdwwebauth2f" "pubs")))
  (should (not (sc--box-in-restart-group-p "scdwwebauth2f" "pub")))
  (should (sc--box-in-restart-group-p "scdwwebpub2f" "pub")))

(provide 'dg-sc-ert)
