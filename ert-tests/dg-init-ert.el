(require 'ert)
(require 'dg-init)

(ert-deftest dg-features-are-available ()
  (should (featurep 'flx-ido)))
