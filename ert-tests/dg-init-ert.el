(add-to-list 'load-path "~/dotemacs/")
(add-to-list 'load-path "./")
(package-initialize)

(load "init.el")
(message (mapconcat (lambda (it) (symbol-name (car it))) package-alist " "))

(require 'ert)

;; (ert-deftest my-files-are-loaded ()
;;   (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))

;; ;; run other tests
;; (require 'dg-sc-ert)
