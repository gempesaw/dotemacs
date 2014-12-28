(require 'dired)
(require 'dired-x)
(require 'dired-aux)

(eval-after-load "dired-aux"
   '(add-to-list 'dired-compress-file-suffixes
                 '("\\.zip\\'" ".zip" "unzip")))

;; Make dired less verbose
(eval-after-load "dired-details"
  '(progn
     (setq-default dired-details-hidden-string "--- ")
     (dired-details-install)))

;; make dired-find-file faster
;; http://www.masteringemacs.org/articles/2011/03/25/working-multiple-files-dired/
(eval-after-load "find-dired"
  '(progn
     (setq find-ls-option '("-print0 | xargs -0 ls -ld" . "-ld"))
     ))

(provide 'dg-dired)
