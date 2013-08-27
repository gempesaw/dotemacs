(require 'ert)

(require 'dg-elisp-macros)

(ert-deftest should-pass ()
  (should (fboundp 'sc-qa-box-name-conditionals)))
