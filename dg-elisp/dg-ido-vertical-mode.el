(setq ido-use-faces t
      ido-auto-merge-delay-time 1.4
      ido-vertical-show-count t
      ido-vertical-define-keys 'C-n-C-p-up-and-down)

(add-to-list 'ido-ignore-files "\\.DS_Store")

(provide 'dg-ido-vertical-mode)
