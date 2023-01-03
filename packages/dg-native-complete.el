;; (with-eval-after-load 'company-native-complete
;;   (with-eval-after-load 'native-complete
;;     ;; (add-to-list 'company-backends 'company-native-complete)

;;     (setq shell-mode-hook nil)
;;     (add-hook 'shell-mode-hook (lambda () (setq comint-prompt-regexp "^.+[$] ")))

;;     (with-eval-after-load 'shell (native-complete-setup-bash))
;;     ))



(provide 'dg-native-complete)
