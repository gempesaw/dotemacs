(eval-after-load 'paredit
  '(progn
     (add-hook 'lisp-mode-hook 'enable-paredit-mode)
     (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
     (autoload 'enable-paredit-mode "paredit"
       "Turn on pseudo-structural editing of Lisp code."
       t)
     ))

(eval-after-load "elisp-slime-nav"
  '(progn
     (autoload 'elisp-slime-nav-mode "elisp-slime-nav")
     (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t)))))

(eval-after-load "eldoc"
  '(progn
     (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
     (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
     (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)))

(provide 'dg-emacs-lisp-mode)
