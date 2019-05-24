(require 'wrap-region)
(wrap-region-global-mode -1)

(mapc (lambda (it)
        (wrap-region-add-wrapper it it))
      '("`" "*" "_" " "))

(wrap-region-remove-wrapper "{")
(wrap-region-remove-wrapper "[")

(wrap-region-add-wrapper "{ " " }" "{" '(js2-mode rjsx-mode))
(wrap-region-add-wrapper "[ " " ]" "[" '(js2-mode rjsx-mode))

(wrap-region-global-mode 1)

(provide 'dg-wrap-region)
