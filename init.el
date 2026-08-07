(package-initialize)

(eval-when-compile
  (require 'use-package))

(require 'package)
(require 'cl-lib)

(setq custom-file "~/.emacs.d/emacs-custom.el"
      package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa-stable" . "http://stable.melpa.org/packages/")))


(use-package dash :ensure t)
(use-package f :ensure t)
(use-package ht :ensure t)
(use-package loop :ensure t)
(use-package s :ensure t)
(use-package bpr :ensure t)
(use-package duplicate-thing :ensure t)
(use-package transient :ensure t)


(defvar dg-elc-compiled-version nil)

(defun dg-elc-detect-compiled-version ()
  (let ((probe (or (car (file-expand-wildcards
                         (expand-file-name "dash-*/dash.elc" package-user-dir)))
                   (car (file-expand-wildcards
                         (expand-file-name "*/*.elc" package-user-dir))))))
    (when (and probe (file-readable-p probe))
      (with-temp-buffer
        (insert-file-contents probe nil 0 200)
        (goto-char (point-min))
        (when (re-search-forward "in Emacs version \\([0-9.]+\\)" nil t)
          (match-string 1))))))

(defun dg-recompile-packages ()
  (interactive)
  (package-recompile-all)
  (setq dg-elc-compiled-version emacs-version)
  (message "Recompiled packages with Emacs %s -- restart Emacs" emacs-version))

(setq dg-elc-compiled-version (dg-elc-detect-compiled-version))

(add-hook 'emacs-startup-hook
          (lambda ()
            (when (and dg-elc-compiled-version
                       (not (equal dg-elc-compiled-version emacs-version)))
              (display-warning
               'dg-packages
               (format (concat "PACKAGES ARE STALE\n"
                               "  .elc compiled by : %s\n"
                               "  running          : %s\n"
                               "Expect void-symbol errors.\n"
                               "Fix: M-x dg-recompile-packages")
                       dg-elc-compiled-version emacs-version)
               :error))))

(let ((inhibit-message t))
  (->> "~/.emacs.d/packages"
       (f-files)
       (--filter (not (or (s-contains-p "#" it)
                          (s-contains-p "~" it))))
       (funcall (lambda (files) (--each files
                                  (progn
                                    (load it nil t)
                                    (load it nil t)))))))

(add-to-list 'load-path (f-expand "~/opt/kubectl.el"))
(add-to-list 'load-path (f-expand "~/opt/aws.el"))
(add-to-list 'load-path (f-expand "~/.emacs.d/combobulate"))
(put 'narrow-to-region 'disabled nil)
