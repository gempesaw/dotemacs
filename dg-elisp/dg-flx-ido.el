(require 'flx-ido)

;;; use flx sorting
(flx-ido-mode 1)

;; turn up gc threshold to speed up flx
(setq gc-cons-threshold 20000000
      ;; disable ido faces to see flx highlights.
      ido-use-faces nil)

;;; try to use flx-ido more often at the expense of speed
(setq flx-ido-threshhold 15000)

(provide 'dg-flx-ido)
