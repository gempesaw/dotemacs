(eval-after-load "dired"
  (eval-after-load "dired-subtree"
    '(progn
       (define-key dired-mode-map (kbd "i")
         (lambda ()
           (interactive)
           (dired-subtree-insert)))

       (define-key dired-mode-map (kbd "k")
         (lambda ()
           (interactive)
           (dired-subtree-remove))))))

(provide 'dg-dired-subtree)
