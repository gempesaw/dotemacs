(defun dg-httprepl-format-json (buffer)
  (httprepl-response-middleware
   (shell-command-on-region (httprepl-find-headers-end buffer) (point-max) "jq '.'" buffer t)))

(setq httprepl-response-middleware
      '(httprepl-apply-content-type-middleware
        httprepl-comment-headers
        dg-httprepl-format-json
        ))

(provide 'dg-httprepl)
