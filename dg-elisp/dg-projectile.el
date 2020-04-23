(global-set-key (kbd "s-p") 'projectile-switch-project)

(setq projectile-project-test-cmd "npm test")

(define-key projectile-mode-map [?\s-d] 'projectile-find-dir)
(define-key projectile-mode-map (kbd "C-c p p") 'projectile-test-project)
(define-key projectile-mode-map (kbd "C-c p c") 'projectile-compile-project)
(define-key projectile-mode-map [?\s-p] 'projectile-switch-project)
(key-chord-define-global "zp" 'projectile-switch-project)

(define-key projectile-mode-map [?\s-g] (lambda () (interactive)
                                          (setq current-prefix-arg '(4))
                                          (call-interactively 'projectile-ag)))

(define-key projectile-mode-map [?\s-b] 'projectile-switch-to-buffer)
(key-chord-define-global "zb"
                         (lambda ()
                           (interactive)
                           (let ((projectile-switch-project-action 'projectile-switch-to-buffer))
                             (projectile-switch-project))))

(define-key projectile-mode-map [?\s-f] 'projectile-find-file)
(key-chord-define-global "zf"
                         (lambda ()
                           (interactive)
                           (let ((projectile-switch-project-action 'projectile-find-file))
                             (projectile-switch-project))))

(setq projectile-switch-project-action 'projectile-vc)

(defvar projectile-sc-honeydew '("honeydew"))
(defvar projectile-perl-dzil '("dist.ini lib t"))
;; (setq projectile-test-files-suffices (cddr projectile-test-files-suffices))
;; (add-to-list 'projectile-test-files-suffices "\\.t")

;; (defun projectile-project-type ()
;;   "Determine the project's type based on its structure."
;;   (cond
;;    ((projectile-verify-files projectile-sc-honeydew) 'perl)
;;    ((projectile-verify-files projectile-perl-dzil) 'perl)
;;    (t 'generic)))

;; (defun projectile-test-suffix (project-type)
;;   "Find default test files suffix based on PROJECT-TYPE."
;;   (cond
;;    ((member project-type '(rails-rspec ruby-rspec)) "_spec")
;;    ((member project-type '(rails-test ruby-test lein go)) "_test")
;;    ((member project-type '(scons)) "test")
;;    ((member project-type '(maven symfony)) "Test")
;;    ((member project-type '(gradle grails)) "Spec")
;;    ((member project-type '(perl)) ".t")))

(projectile-global-mode 1)

;;; open a shell at the root of the directory
(progn
  (defun dg-projectile-open-shell-in-root ()
         (interactive)
         (projectile-with-default-dir (projectile-project-root)
           (call-interactively 'switch-to-shell-or-create)))

  (define-key projectile-mode-map (kbd "C-c p /") 'dg-projectile-open-shell-in-root))

;;; open dired at the root of the directory
(setq projectile-find-dir-includes-top-level t)
(when (and
       (fboundp 'projectile-discover-projects-in-directory)
       (file-exists-p "/opt"))
      (projectile-discover-projects-in-directory "/opt"))

(provide 'dg-projectile)
