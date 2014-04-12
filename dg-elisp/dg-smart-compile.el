;; smart compile
(eval-after-load "smart-compile"
  '(progn
     (setq compilation-read-command nil)
     (add-to-list 'smart-compile-alist '("\\.php\\'" . "php %F") )
     (add-to-list 'smart-compile-alist '("\\.md\\'" . (markdown-preview-with-syntax-highlighting)))))

;; don't ask about files
(setq compilation-ask-about-save nil)

;; don't compile based on last buffer
(setq compilation-last-buffer nil)

(setenv "PERL_LWP_SSL_VERIFY_HOSTNAME" "0")

(advise-around-commands "sc-hdew-set-testing-env"
                        (execute-perl compile compile-again sc-hdew-prove-all)
                        (progn (setenv "HDEW_TESTS" "1")
                               ad-do-it
                               (setenv "HDEW_TESTS" "0")))

(provide 'dg-smart-compile)
