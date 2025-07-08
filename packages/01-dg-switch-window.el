(use-package switch-window
  :ensure t

  :config
  (setq switch-window-shortcut-style 'qwerty
        switch-window-configuration-change-hook-inhibit t
        switch-window-shortcut-appearance 'text
        switch-window-multiple-frames t)

  (defun dg-switch-window-then-kill-buffer ()
    (interactive)
    "PROMPT a question and let use select or create a window to run FUNCTION."
    (switch-window--then
     "Window to kill: "
     #'kill-buffer-and-window
     #'kill-buffer-and-window
     t
     0))

  :bind (:map my-keys-minor-mode-map
              ("M-j" . switch-window)
              ("C-c j" . switch-window-then-delete)
              ("C-c k" . dg-switch-window-then-kill-buffer))
  )
