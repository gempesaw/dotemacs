(require 'generic-x)

;; TODO set these as local variables instead of global
(defun feature-compile-shortcut ()
  (setq compilation-read-command nil)
  (setq compile-command "/opt/honeydew/bin/honeydew.pl -isMine")
  (local-set-key (kbd "C-c C-c") 'compile)
)

(define-generic-mode 'feature-mode
  '("#")                      ;; comment characters
  '("Feature" "Scenario")     ;; keywords to font-lock
  nil                         ;; additional expressions to font-lock
  '("\\.feature$")            ;; placed in auto-mode-alist
  '(feature-compile-shortcut) ;; list of functions to call
  "A mode for editing automation .feature files."

  )
