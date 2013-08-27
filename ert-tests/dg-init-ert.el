(require 'ert)

xfcjdev(ert-deftest macros-are-loaded ()
  (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))
