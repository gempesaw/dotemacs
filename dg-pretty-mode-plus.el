(setq pretty-default-groups
  '(:function
    ;; :equality
    :nil
    ))

;; (setq pretty-supported-modes
;;   '(ruby-mode
;;     ess-mode java-mode octave-mode tuareg-mode
;;     python-mode sml-mode jess-mode clips-mode clojure-mode
;;     lisp-mode emacs-lisp-mode scheme-mode sh-mode
;;     perl-mode c++-mode c-mode haskell-mode
;;     javascript-mode coffee-mode groovy-mode))

(global-pretty-mode 1)

(provide 'dg-pretty-mode-plus)
