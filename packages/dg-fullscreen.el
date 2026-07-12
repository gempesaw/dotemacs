;;; -*- lexical-binding: t; -*-
(defun dg-fullscreen--nuke-popups ()
  (when (and (boundp 'corfu--auto-timer) (timerp corfu--auto-timer))
    (ignore-errors (cancel-timer corfu--auto-timer)))
  (when (fboundp 'corfu-quit) (ignore-errors (corfu-quit)))
  (when (and (boundp 'corfu--frame) (frame-live-p corfu--frame))
    (ignore-errors (make-frame-invisible corfu--frame)))
  (when (and (boundp 'corfu-popupinfo--frame) (frame-live-p corfu-popupinfo--frame))
    (ignore-errors (make-frame-invisible corfu-popupinfo--frame)))
  (when (fboundp 'posframe-delete-all) (ignore-errors (posframe-delete-all))))

(defvar dg-fullscreen--corfu-was-on nil)

(defun dg-fullscreen--before-toggle (&rest _)
  (setq dg-fullscreen--corfu-was-on (bound-and-true-p global-corfu-mode))
  (when dg-fullscreen--corfu-was-on (global-corfu-mode -1))
  (dg-fullscreen--nuke-popups))

(defun dg-fullscreen--after-toggle (&rest _)
  (dg-fullscreen--nuke-popups)
  (dolist (delay '(0.05 0.2 0.5 0.9 1.4 2.0))
    (run-with-timer delay nil #'dg-fullscreen--nuke-popups))
  (when dg-fullscreen--corfu-was-on
    (run-with-timer 2.2 nil (lambda () (global-corfu-mode 1)))
    (setq dg-fullscreen--corfu-was-on nil)))

(advice-add 'toggle-frame-fullscreen :before #'dg-fullscreen--before-toggle)
(advice-add 'toggle-frame-fullscreen :after #'dg-fullscreen--after-toggle)

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

(toggle-frame-fullscreen)

;;; don't use the os x horrible fullscreen method
(setq ns-use-native-fullscreen nil)
