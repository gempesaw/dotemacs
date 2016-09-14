(defadvice kill-this-buffer (around let-me-kill-this-buffer activate compile)
  "let me kill the current buffer without whining, but let 'q'
still function in special-mode"
  (progn
    (setq menu-updating-frame nil)
    ad-do-it
    (setq menu-updating-frame t)))


;; automatically save buffers associated with files on buffer switch
;; and on windows switch
(advise-commands "auto-save"
                 (switch-to-buffer other-window switch-window)
                 (prelude-auto-save-command))

;;; save everything when we focus another frame (even potentially
;;; another emacs frame)
(add-hook 'focus-out-hook 'prelude-auto-save-command)


(defadvice split-window-below (after restore-balanace-below activate)
  (balance-windows))

(defadvice split-window-right (after restore-balance-right activate)
  (balance-windows))

(defadvice delete-window (after restore-balance activate)
  (balance-windows))

(defadvice bookmark-set (after save-bookmarks-automatically activate)
  (bookmark-save))

;; full screen magit-status
(defadvice magit-status (around magit-fullscreen activate)
  ;; µ is 265
  (window-configuration-to-register 265)
  ad-do-it
  (delete-other-windows))



(defun let-compile-use-other-frame (orig-fun &rest args)
  (let ((display-buffer-overriding-action
         '((display-buffer-reuse-window
            display-buffer-use-some-frame
            display-buffer-pop-up-window)
           (inhibit-switch-frame . t)
           (inhibit-same-window . t)
           (reusable-frames . t))))
    (apply orig-fun args)))

(progn
  (advice-add 'compile :around #'let-compile-use-other-frame)
  (advice-add 'compile-again :around #'let-compile-use-other-frame)
  (advice-add 'ensime-sbt-do-test-only-dwim :around #'let-compile-use-other-frame)
  (advice-add 'safjave-buffer :around #'let-compile-use-other-frame))

(progn
  (defun inhibit-auto-balance (orig-fun &rest args)
    (noflet ((balance-windows () nil))
      (apply orig-fun args)))

  (advice-add 'magit-ediff-dwim :around #'inhibit-auto-balance))
