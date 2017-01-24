(require 'dired)
(require 'dired+)
(require 'dired-x)
(require 'dired-aux)

(eval-after-load "dired-aux"
   '(add-to-list 'dired-compress-file-suffixes
                 '("\\.zip\\'" ".zip" "unzip")))

(define-key dired-mode-map "\M-g" nil)

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

;;; handle hiding .js and .map files in dired mode. toggle the filter
;;; mode with "hh" keychord
(progn
  (add-to-list 'dired-omit-extensions ".js")
  (add-to-list 'dired-omit-extensions ".map")

  (key-chord-define dired-mode-map "hh" 'dired-filter-mode))

(setq dired-filter-verbose nil)

(defun dg-dired-browse-file-at-point ()
  (interactive)
  (let ((path (dired-copy-filename-as-kill 0)))
    (unless (string-match "html$" path)
      (setq path (concat path "/index.html")))
    (browse-url path)))

(defun dg-tabulate-gatling-results ()
  (interactive)
  (let* ((gatling-result-folder (dired-copy-filename-as-kill 0))
         (results (mapcar (lambda (it) (s-replace "\n" "" it))
                          (s-split " "
                                   (shell-command-to-string
                                    (format "echo 'console.log(stats.stats.meanNumberOfRequestsPerSecond.total, stats.stats.percentiles3.total, stats.stats.meanResponseTime.total)' | cat %s/js/stats.js - | node"
                                            gatling-result-folder)))))
         (mean-rps (car results))
         (95th-per (cadr results))
         (mean-response (caddr results))
         (url (format "http://10.10.2.233:8001/provider-server/build/reports/gatling/%s/" gatling-result-folder)))
    (with-current-buffer "results"
      (end-of-buffer)
      (newline)
      (insert (format  "| %s | %s | %s | [link|%s] |" mean-rps mean-response 95th-per url)))
    (next-line)))

(defun dg-upload-to-s3 ()
  (interactive)
  (let* ((base-path "s.qa.origin.sharecare.com/honeydew")
         (folder-name (thing-at-point 'symbol t))
         (args (format "put --recursive %s/ s3://%s/%s/"
                       folder-name base-path folder-name))
         (url (format "http://%s/%s" base-path folder-name)))
    (apply 'start-process (append '("s3-upload" "*test*" "s3cmd") (s-split " " args)))
    url))


(define-key dired-mode-map "b" 'dg-dired-browse-file-at-point)

(provide 'dg-dired)

(progn
  (let ((list '("a" "b" "c")))
    (caddr list)))
