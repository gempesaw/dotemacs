(mapc (lambda (it)
        (wrap-region-add-wrapper it it))
      '("`" "*" "_"))

(provide 'dg-wrap-region)
