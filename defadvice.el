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
