;; (eval-after-load 'popper-mode
;;   (progn
;;     (global-set-key (kbd "M-[") 'popper-toggle-latest)
;;     (global-set-key (kbd "M-]") 'popper-cycle)
;;     ;; (global-set-key (kbd "M-") 'popper-toggle-type)

;;     (setq popper-reference-buffers '("\\*Messages\\*"
;;                                      "^\\*shell.*\\*$"  shell-mode  ;shell as a popup
;;                                      compilation-mode
;;                                      ;; "^\\*kubectl\\*$"
;;                                      )
;;           popper-group-function #'popper-group-by-projectile
;;           popper-display-function #'popper-select-popup-at-bottom)

;;     (popper-mode +1)
;;     (popper-echo-mode +1))
;;   )

(provide 'dg-popper-mode)
