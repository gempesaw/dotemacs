(require 'generic-x)

(define-generic-mode 'feature-mode
  '("# ")                     ;; comment characters
  '("Feature"                 ;; keywords to font-lock
    "Scenario"
    "Hostname"
    "Tags"
    "Subtitle"
    "Version"
    "Email"
    "Given"
    "When"
    "Then")
  '(())                 ;; additional expressions to font-lock
  '("\\.feature$")            ;; placed in auto-mode-alist
  '(feature-mode-hook) ;; list of functions to call)
  "A mode for editing automation .feature files."
  )

(defun feature-mode-hook ()
    "feature major mode

\\{feature-mode-map}"
  (setq major-mode 'feature-mode
        mode-name "Feature"
        mode-line-process nil)
  (use-local-map feature-mode-map)
  (run-mode-hooks 'feature-mode-hook))

(defvar feature-mode-map
    (let ((map (make-keymap)))
      (define-key map (kbd "<f5>") 'execute-feature)
      map))
