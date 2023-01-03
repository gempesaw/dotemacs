(use-package wrap-region
  :ensure t
  :config

  (wrap-region-global-mode -1)

  (mapc (lambda (it)
          (wrap-region-add-wrapper it it))
	'("`" "*" "_" " "))

  ;; (wrap-region-remove-wrapper "{")
  ;; (wrap-region-remove-wrapper "[")

  (wrap-region-global-mode 1))

