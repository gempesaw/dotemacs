(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)
(setq-default indent-tabs-mode nil)

(setq hippie-expand-try-functions-list '(
                                         yas/hippie-try-expand
                                         try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-complete-lisp-symbol-partially
                                         try-complete-lisp-symbol))

(eval-after-load "smart-tab"
  '(progn
     ;; smart tab - do i need this? YES
     (define-key my-keys-minor-mode-map (kbd "<tab>") 'smart-tab)
     (global-set-key (kbd "<tab>") 'smart-tab)
     (global-smart-tab-mode 1)))

(provide 'dg-tabs)
