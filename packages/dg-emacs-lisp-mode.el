(use-package paredit
  :ensure t
  :config
  (put 'paredit-forward-delete 'delete-selection 'supersede)
  (put 'paredit-backward-delete 'delete-selection 'supersede)
  (put 'paredit-open-round 'delete-selection t)
  (put 'paredit-open-square 'delete-selection t)
  (put 'paredit-doublequote 'delete-selection t)
  (put 'paredit-newline 'delete-selection t)
  
  (add-hook 'lisp-mode-hook 'enable-paredit-mode)
  (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
  (autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t))

(use-package elisp-slime-nav
  :ensure t
  :config
  (autoload 'elisp-slime-nav-mode "elisp-slime-nav")
  (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t))))

(use-package eldoc
  :ensure t
  :config
  (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
  (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode))

(use-package elisp-mode
  :requires (paredit elisp-slime-nav eldoc))
