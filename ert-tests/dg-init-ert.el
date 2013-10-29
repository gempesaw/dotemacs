(require 'ert)

(package-initialize)
(load "init.el")

;; (message (mapconcat (lambda (it) (symbol-name (car it))) package-alist "\n"))

(ert-deftest my-files-are-loaded ()
  (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))

;; run other tests
(require 'dg-sc-ert)
