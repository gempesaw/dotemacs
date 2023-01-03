(defun ensure-fullscreen-mode-is-on ()
  (interactive)
  (toggle-frame-fullscreen)
  (toggle-frame-fullscreen))

(defun x11-toggle-fullscreen ()
  "Toggle full screen on X11"
  (interactive)
  (when (eq window-system 'x)
    (set-frame-parameter
     nil 'fullscreen
     (when (not (frame-parameter nil 'fullscreen)) 'fullboth))))

(global-set-key (kbd "C-c \\") 'ensure-fullscreen-mode-is-on)

;;; don't use the os x horrible fullscreen method
(setq ns-use-native-fullscreen nil)

(toggle-frame-fullscreen)
