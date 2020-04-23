(add-hook 'minibuffer-setup-hook 'my-minibuffer-setup-hook)

(add-hook 'latex-mode-hook
          (lambda ()
            (define-key latex-mode-map (kbd "C-c C-f")
              (lambda ()
                (interactive)
                (save-buffer)
                (save-window-excursion
                  (tex-file))))))

(add-hook 'scala-mode-hook #'lsp)
(add-hook 'ruby-mode-hook #'lsp)
(add-hook 'elixir-mode-hook #'lsp)


;; (setq mu4e-index-updated-hook nil)
(add-hook 'mu4e-index-updated-hook
          (lambda ()
            (interactive)
            (progn
              (start-process "check-mail" " *temp-mail-check*" "sh" "/opt/dotemacs/checkmail.sh")
              (display-time-update))))
