(defadvice kill-this-buffer (around let-me-kill-this-buffer activate compile)
  "let me kill the current buffer without whining, but let 'q'
still function in special-mode"
  (progn
    (setq menu-updating-frame nil)
    ad-do-it
    (setq menu-updating-frame t)))


;; automatically save buffers associated with files on buffer switch
;; and on windows switch
(defadvice switch-to-buffer (before save-buffer-now activate)
  (when buffer-file-name (save-buffer)))
(defadvice other-window (before other-window-now activate)
  (when buffer-file-name (save-buffer)))
(defadvice windmove-do-window-select (before save-buffer-now activate)
  (when buffer-file-name (save-buffer)))

(defadvice bookmark-set (after save-bookmarks activate)
  (bookmark-save))


;; full screen magit-status
(defadvice magit-status (around magit-fullscreen activate)
  (window-configuration-to-register :magit-fullscreen)
  ad-do-it
  (delete-other-windows))
