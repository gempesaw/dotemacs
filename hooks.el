(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

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

(eval-after-load 'paredit
  (autoload 'enable-paredit-mode "paredit"
    "Turn on pseudo-structural editing of Lisp code."
    t))

(eval-after-load "elisp-slime-nav"
  '(progn
     (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t)))))

(eval-after-load "eldoc"
  '(progn
     (add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
     (add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
     (add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)))

;; (setq mu4e-index-updated-hook nil)
(add-hook 'mu4e-index-updated-hook
          (lambda ()
            (interactive)
            (progn
              (start-process "check-mail" " *temp-mail-check*" "sh" "/opt/dotemacs/checkmail.sh")
              (display-time-update))))



(setq jabber-alert-message-hooks '(jabber-message-echo jabber-message-scroll jabber-alert-message-say))
