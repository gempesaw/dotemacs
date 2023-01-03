(use-package git-link
  :ensure t
  :config
  (setq git-link-open-in-browser t)
  :bind (("C-c l" . git-link)
         ("C-c C-l" . git-link-homepage)))

