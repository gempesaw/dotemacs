(package-initialize)

(eval-when-compile
  (require 'use-package))

(require 'package)
(require 'cl-lib)

(setq custom-file "~/.emacs.d/emacs-custom.el"
      package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")
                         ("melpa-stable" . "http://stable.melpa.org/packages/")))

(use-package dash :ensure t)
(use-package f :ensure t)
(use-package ht :ensure t)
(use-package loop :ensure t)
(use-package s :ensure t)
(use-package bpr :ensure t)
(use-package duplicate-thing :ensure t)
(use-package transient :ensure t)


(->> "~/.emacs.d/packages"
     (f-files)
     (--filter (not (or (s-contains-p "#" it)
                        (s-contains-p "~" it))))
     (funcall (lambda (files) (--each files
                                (progn
                                  (load it)
                                  (load it))))))
