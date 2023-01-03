(use-package custom
  :config
  (->> (f-this-file)
       (f-dirname)
       (funcall (lambda (dir) (f-join dir "../fairyfloss-theme.el")))
       (load))
  
  ;; Small fringes
  (set-fringe-mode '(1 . 1))

  (setq custom-safe-themes t)
  (load-theme 'fairyfloss))


(use-package smart-mode-line
  :ensure t
  :config
  (sml/setup)
  (sml/apply-theme 'dark))



