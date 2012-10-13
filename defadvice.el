(defadvice kill-this-buffer (around let-me-kill-this-buffer activate compile)
  "let me kill the current buffer without whining, but let 'q'
still function in special-mode"
  (progn
    (setq menu-updating-frame nil)
    ad-do-it
    (setq menu-updating-frame t)))
