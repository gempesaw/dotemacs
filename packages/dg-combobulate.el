(use-package combobulate
  :hook ((python-ts-mode . combobulate-mode)
         (js-ts-mode . combobulate-mode)
         (css-ts-mode . combobulate-mode)
         (yaml-ts-mode . combobulate-mode)
         (typescript-ts-mode . combobulate-mode)
         (tsx-ts-mode . combobulate-mode))
  :load-path "../combobulate/"
  :config
  (define-key combobulate-key-map (kbd "M") 'self-insert-command)
  (define-key combobulate-key-map (kbd "M-k") nil))
