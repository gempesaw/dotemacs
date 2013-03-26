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
