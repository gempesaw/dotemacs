(use-package projectile
  :ensure t
  :bind (("s-p" . projectile-switch-project)
         :map projectile-mode-map
         ("s-p" . projectile-switch-project)
         ("s-d" . projectile-find-dir)
	     ("s-b" . projectile-switch-to-buffer)
	     ("s-f" . projectile-find-file)
         ("s-g" . (lambda () (interactive)
                    (setq current-prefix-arg '(4))
                    (call-interactively 'projectile-ag)))
         ("C-c p p" . projectile-test-project)
         ("C-c p c" . projectile-compile-project)
	     ("C-c p /" . dg-projectile-open-shell-in-root))

  :chords (("zb" . (lambda ()
                     (interactive)
                     (let ((projectile-switch-project-action 'projectile-switch-to-buffer))
                       (projectile-switch-project))))
	       ("zf" . (lambda ()
                     (interactive)
                     (let ((projectile-switch-project-action 'projectile-find-file))
                       (projectile-switch-project)))))
  :config
  (setq projectile-project-test-cmd "make test")
  (setq projectile-switch-project-action 'projectile-vc)
  
  ;;; open dired at the root of the directory
  (setq projectile-find-dir-includes-top-level t)
  
  (when (file-exists-p "/Users/dgempesaw/opt")
    (projectile-discover-projects-in-directory "/Users/dgempesaw/opt"))
  (projectile-mode 1)
  )
