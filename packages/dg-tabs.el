(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

(setq hippie-expand-try-functions-list '(
                                         yas/hippie-try-expand
                                         try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-expand-line
                                         try-expand-line-all-buffers
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-complete-lisp-symbol-partially
                                         try-complete-lisp-symbol
                                         ))

(eval-after-load "smart-tab"
  '(progn
     (setq smart-tab-using-hippie-expand t)
     (setq smart-tab-completion-functions-alist '())
     (define-key my-keys-minor-mode-map (kbd "<tab>") 'smart-tab)
     (global-set-key (kbd "<tab>") 'smart-tab)
     (global-smart-tab-mode 1)))

(defun smart-tab-default ()
  "Indent region if mark is active, or current line otherwise."
  (interactive)
  (if smart-tab-debug
      (message "default"))
  (if (s-equals-p major-mode "vterm-mode")
      (vterm-send-key "<tab>")
    (let* ((smart-tab-mode nil)
           (global-smart-tab-mode nil)
           (ev last-command-event)
           (triggering-key (cl-case (type-of ev)
                             (integer (char-to-string ev))
                             (symbol (vector ev))))
           (original-func (or 'indent-for-tab-command
                              (key-binding triggering-key)
                              (key-binding (lookup-key local-function-key-map
                                                       triggering-key)))))
      (call-interactively original-func))))

(provide 'dg-tabs)
