(use-package forge
  :ensure t
  :bind (("C-c p f" . dg-maybe-forge-browse-pullreq)
         ("C-c p F" . forge-browse-pullreqs)
         ("M-s-p" . forge-create-pullreq))
  :config

  (defun dg-maybe-forge-browse-pullreq ()
    (interactive)
    (if (forge-get-repository 'full)
        (call-interactively 'forge-browse-pullreq)
      (forge-browse-pullreqs)))

  (add-hook 'forge-post-mode-hook (lambda ()
                                    (setq-local auto-fill-function nil)))

  (defun dg-forge-open-pr-in-browser (pr)
    (message (format "%s" pr))
    (when-let ((url (forge-get-url pr)))
      (message (format "%s" url))
      (browse-url url)))

  (advice-add 'forge-create-pullreq :after
              (lambda (pr &rest _)
                (dg-forge-open-pr-in-browser pr))))
