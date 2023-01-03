(defun dg-groovy-mode-hook ()
   (setq indent-tabs-mode nil
         c-basic-offset 4))

(add-hook 'groovy-mode-hook 'dg-groovy-mode-hook)

(provide 'dg-groovy)
