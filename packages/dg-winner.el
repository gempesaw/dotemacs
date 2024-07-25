(use-package winner
  :ensure t
  :config
  (winner-mode 1)
  :bind ((:map winner-mode-map
               ("C-c M-<left>" . #'winner-undo)
               ("C-c M-<right>" . #'winner-redo)
               )
         (:map winner-repeat-map
               ("M-<left>" . #'winner-undo)
               ("M-<right>" . #'winner-redo)
               ))

  )
