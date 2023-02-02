(use-package forge
  :ensure t
  :bind (("C-c p f" . dg-maybe-forge-browse-pullreq)
         ("C-c p F" . forge-browse-pullreqs))
  :config
  (defun dg-maybe-forge-browse-pullreq ()
    (interactive)
    (if (forge-get-repository 'full)
        (call-interactively 'forge-browse-pullreq)
      (forge-browse-pullreqs)))

  (add-hook 'forge-post-mode-hook (lambda ()
                                    (setq-local auto-fill-function nil))))
