(require 'generic-x)

(define-generic-mode 'feature-mode
  '("# ")                     ;; comment characters
  '("Feature" "Scenario"      ;; keywords to font-lock
    "Hostname" "Tags"
    "Subtitle")
  nil                         ;; additional expressions to font-lock
  '("\\.feature$")            ;; placed in auto-mode-alist
  ;; '(feature-compile-shortcut) ;; list of functions to call
  "A mode for editing automation .feature files."

  )
