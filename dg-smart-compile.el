;; smart compile
(eval-after-load "smart-compile"
  '(progn
     (setq compilation-read-command nil)
     (add-to-list 'smart-compile-alist '("\\.php\\'" . "php %F") )
     (add-to-list 'smart-compile-alist '("\\.md\\'" . (markdown-preview-with-syntax-highlighting)))))

;; don't ask about files
(setq compilation-ask-about-save nil)

;; don't compile based on last buffer
(setq compilation-last-buffer nil)

(provide 'dg-smart-compile)
