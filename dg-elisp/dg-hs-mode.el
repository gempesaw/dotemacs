(mapcar (lambda (it) (add-hook it #'hs-minor-mode))
        '(cperl-mode-hook
          js2-mode-hook
          emacs-lisp-mode-hook
          objc-mode-hook))

(progn
  (key-chord-define-global "dk" nil)
  (key-chord-define-global
   "fk"
   (let ((map (make-sparse-keymap)))
     (define-key map (kbd "t") #'hs-toggle-hiding)
     (define-key map (kbd "j") #'hs-hide-block)
     (define-key map (kbd "l") #'hs-hide-level)
     (define-key map (kbd "k") #'hs-show-block)
     (define-key map (kbd "p") #'hs-hide-all)
     (define-key map (kbd "n") #'hs-show-all)
     map)))

(provide 'dg-hs-mode)
