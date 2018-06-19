(eval-after-load "find-dired"
    '(progn
       (setq find-ls-option '("-print0 | xargs -0 ls -ld" . "-ld"))
       ))

(eval-after-load "dired"
  '(progn
     ;; (define-key dired-mode-map "\M-g" nil)
     ;; (define-key dired-mode-map "\M-b" nil)

     ;; ;; Make dired less verbose
     ;; (eval-after-load "dired-details"
     ;;   '(progn
     ;;      (setq-default dired-details-hidden-string "--- ")
     ;;      (dired-details-install)))

     ;; make dired-find-file faster
     ;; http://www.masteringemacs.org/articles/2011/03/25/working-multiple-files-dired/

     (defun dg-dired-browse-file-at-point ()
       (interactive)
       (let ((path (dired-copy-filename-as-kill 0)))
         (unless (string-match "html$" path)
           (setq path (concat path "/index.html")))
         (browse-url path)))

     (defun dg-tabulate-gatling-results ()
       (interactive)
       (let* ((folder (dired-get-filename 'relative))
              (abs-path (dired-get-filename))
              (url (s-concat "http://zebra.local:8080/" (cadr (s-split "zebra/opt/" abs-path))))
              (source (format "%s/js/stats.json" folder))
              (stats "/tmp/stats.json")
              (jq-binary (executable-find "jq"))
              (jq-filter "'.stats.meanNumberOfRequestsPerSecond.total, .stats.percentiles3.total, .stats.meanResponseTime.total'"))
         (copy-file source stats t)
         (let* ((default-directory "/tmp")
                (results (-filter 's-present?
                                  (s-split "\n"
                                           (shell-command-to-string (format "%s %s %s" jq-binary jq-filter stats)))))
                (mean-rps (string-to-number (car results)))
                (95th-per (cadr results))
                (mean-response (caddr results)))
           (with-current-buffer "results"
             (end-of-buffer)
             (newline)
             (insert (format  "| %.2f | %s | %s | [link|%s]" mean-rps mean-response 95th-per url)))
           (next-line))))

     (defun dg-upload-to-s3 ()
       (interactive)
       (let* ((base-path "s.qa.origin.sharecare.com/honeydew")
              (folder-name (thing-at-point 'symbol t))
              (args (format "put --recursive %s/ s3://%s/%s/"
                            folder-name base-path folder-name))
              (url (format "http://%s/%s" base-path folder-name)))
         (apply 'start-process (append '("s3-upload" "*test*" "s3cmd") (s-split " " args)))
         url))

     (define-key dired-mode-map "b" 'dg-dired-browse-file-at-point)))

(provide 'dg-dired)
