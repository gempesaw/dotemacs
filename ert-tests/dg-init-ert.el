(add-to-list 'load-path "~/dotemacs/")
(add-to-list 'load-path "./")
(package-initialize)

(message (mapconcat (lambda (it) (symbol-name (car it))) package-alist " "))

(message "%s" load-path)
(require 'ert)

;; (ert-deftest my-files-are-loaded ()
;;   (should (string= "dg-elisp-macros" (require 'dg-elisp-macros))))

;; ;; run other tests
;; (require 'dg-sc-ert)
