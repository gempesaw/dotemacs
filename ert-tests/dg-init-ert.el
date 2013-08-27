(require 'ert)

(ert-deftest my-files-are-loaded ()
  (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))
