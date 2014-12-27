(define-key projectile-mode-map [?\s-d] 'projectile-find-dir)
(define-key projectile-mode-map [?\s-p] 'projectile-switch-project)

(define-key projectile-mode-map [?\s-g] 'projectile-grep)


(define-key projectile-mode-map [?\s-b] 'projectile-switch-to-buffer)
(key-chord-define-global "[b"
                         (lambda ()
                           (interactive)
                           (let ((projectile-switch-project-action 'projectile-switch-to-buffer))
                             (projectile-switch-project))))

(define-key projectile-mode-map [?\s-f] 'projectile-find-file)
(key-chord-define-global "[f"
                         (lambda ()
                           (interactive)
                           (let ((projectile-switch-project-action 'projectile-find-file))
                             (projectile-switch-project))))

(setq projectile-switch-project-action 'projectile-vc)

(defvar projectile-sc-honeydew '("honeydew"))
(defvar projectile-perl-dzil '("dist.ini lib t"))
(setq projectile-test-files-suffices (cddr projectile-test-files-suffices))
(add-to-list 'projectile-test-files-suffices "\\.t")

(defun projectile-project-type ()
  "Determine the project's type based on its structure."
  (cond
   ((projectile-verify-files projectile-rails-rspec) 'rails-rspec)
   ((projectile-verify-files projectile-rails-test) 'rails-test)
   ((projectile-verify-files projectile-ruby-rspec) 'ruby-rspec)
   ((projectile-verify-files projectile-ruby-test) 'ruby-test)
   ((projectile-verify-files projectile-django) 'django)
   ((projectile-verify-files projectile-python-pip)'python)
   ((projectile-verify-files projectile-python-egg) 'python)
   ((projectile-verify-files projectile-symfony) 'symfony)
   ((projectile-verify-files projectile-lein) 'lein)
   ((projectile-verify-files projectile-scons) 'scons)
   ((projectile-verify-files projectile-maven) 'maven)
   ((projectile-verify-files projectile-gradle) 'gradle)
   ((projectile-verify-files projectile-grails) 'grails)
   ((projectile-verify-files projectile-rebar) 'rebar)
   ((projectile-verify-files projectile-sbt) 'sbt)
   ((projectile-verify-files projectile-make) 'make)
   ((projectile-verify-files projectile-gulp) 'gulp)
   ((projectile-verify-files projectile-grunt) 'grunt)
   ((projectile-verify-files projectile-haskell-cabal) 'haskell-cabal)
   ((projectile-verify-files projectile-rust-cargo) 'rust-cargo)
   ((projectile-verify-files projectile-sc-honeydew) 'perl)
   ((projectile-verify-files projectile-perl-dzil) 'perl)
   ((funcall projectile-go-function) 'go)
   (t 'generic)))

(defun projectile-test-suffix (project-type)
  "Find default test files suffix based on PROJECT-TYPE."
  (cond
   ((member project-type '(rails-rspec ruby-rspec)) "_spec")
   ((member project-type '(rails-test ruby-test lein go)) "_test")
   ((member project-type '(scons)) "test")
   ((member project-type '(maven symfony)) "Test")
   ((member project-type '(gradle grails)) "Spec")
   ((member project-type '(perl)) ".t")))

(projectile-global-mode 1)

(provide 'dg-projectile)
