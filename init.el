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

(defvar dg-package-load-failures nil
  "Files under packages/ that would not load, as (FILE . ERROR).")

(defun dg-load-package-files (&optional directory)
  "Load every file in DIRECTORY, retrying the ones that error.
DIRECTORY defaults to the packages/ directory.

Each file used to be loaded twice, back to back.  That doubled startup
and quietly broke any top level that was not idempotent -- a `push', or
a `setq' that appends to its own variable -- while never fixing the
ordering problem it looked like it was for: a load running immediately
after the first still cannot see anything a later-sorted file defines.

Retrying only the failures, once the whole directory has been through,
does fix that.  It also keeps one bad file from truncating the rest of
startup, which is what an error mid-loop used to do -- silently, since
`inhibit-message' is bound here."
  (let ((inhibit-message t)
        (retry nil))
    (dolist (file (--filter (not (or (s-contains-p "#" it)
                                     (s-contains-p "~" it)))
                            (f-files (or directory "~/.emacs.d/packages"))))
      (condition-case nil
          (load file nil t)
        (error (push file retry))))

    (setq dg-package-load-failures nil)
    (dolist (file (nreverse retry))
      (condition-case err
          (load file nil t)
        (error (push (cons file err) dg-package-load-failures))))
    (setq dg-package-load-failures (nreverse dg-package-load-failures))))

(dg-load-package-files)

;; Deferred to startup for the same reason as the staleness warning above:
;; drawing to the echo area during the load phase can deadlock AppKit.
(add-hook 'emacs-startup-hook
          (lambda ()
            (when dg-package-load-failures
              (display-warning
               'dg-packages
               (concat "These files failed to load, twice:\n"
                       (mapconcat (lambda (failure)
                                    (format "  %s\n    %s"
                                            (f-filename (car failure))
                                            (error-message-string (cdr failure))))
                                  dg-package-load-failures
                                  "\n"))
               :error))))

(add-to-list 'load-path (f-expand "~/opt/kubectl.el"))
(add-to-list 'load-path (f-expand "~/opt/aws.el"))
(add-to-list 'load-path (f-expand "~/.emacs.d/combobulate"))
(put 'narrow-to-region 'disabled nil)
