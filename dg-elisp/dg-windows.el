;;; nifty we can get sooome access to super as well. Unfortunately, we
;;; don't get everything - things like s-p and s-f are shadowed by
;;; core windows bindings. Haven't figured out how to get around them
;;; yet.
(setq w32-pass-lwindow-to-system nil)
(setq w32-lwindow-modifier 'super)

(provide 'dg-windows)
