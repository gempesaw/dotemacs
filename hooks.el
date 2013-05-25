(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

(add-hook 'ido-setup-hook
          (lambda ()
            ;; Go straight home
            (define-key ido-file-completion-map
              (kbd "~")
              (lambda ()
                (interactive)
                (if (looking-back "/")
                    (insert "~/")
                  (call-interactively 'self-insert-command))))))

(add-hook 'latex-mode-hook
          (lambda ()
            (define-key latex-mode-map (kbd "C-c C-f")
              (lambda ()
                (interactive)
                (save-buffer)
                (save-window-excursion
                  (tex-file))))))

(add-hook 'scala-mode-hook 'ensime-scala-mode-hook)

(add-hook 'cperl-mode-hook
          (lambda()
            (local-set-key (kbd "C-c C-s C-k") 'hs-show-block)
            (local-set-key (kbd "C-c C-s C-j") 'hs-hide-block)
            (local-set-key (kbd "C-c C-s C-p") 'hs-hide-all)
            (local-set-key (kbd "C-c C-s C-n") 'hs-show-all)
            (local-set-key (kbd "<f5>") 'execute-perl)
            (hs-minor-mode t)))

(eval-after-load 'paredit-mode
  (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode))

(eval-after-load "elisp-slime-nav-mode"
  '(progn
     (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t)))))

(eval-after-load 'eldoc
  '(progn
    (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
    (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
    (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)))
