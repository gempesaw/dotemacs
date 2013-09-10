;; enable desktop saving for buffer restore
(desktop-save-mode 1)

;; winner mode
(when (fboundp 'winner-mode)
  (winner-mode 1))

;; delete the selection with a keypress
(delete-selection-mode t)

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; smart pairing for all
;; (electric-pair-mode t)

;; clean up obsolete buffers automatically
;; (require 'midnight)

;; the blinking cursor is nothing, but an annoyance
(blink-cursor-mode -1)

(global-subword-mode t)

(yas-global-mode 1)

(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

(autoload 'js2-mode "js2-mode" nil t)

(wrap-region-global-mode t)
