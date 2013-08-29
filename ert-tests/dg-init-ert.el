(add-to-list 'load-path "~/.emacs.d/")
(add-to-list 'load-path "~/.emacs.d/elpa/")
(package-initialize)

(message (mapconcat (lambda (it) (symbol-name (car it))) package-alist " "))

(require 'ert)

(ert-deftest my-files-are-loaded ()
  (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))

;; run other tests
(require 'dg-sc-ert)
