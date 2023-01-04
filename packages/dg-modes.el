(use-package emacs
  :config

  ;; Turn off mouse interface early in startup to avoid momentary display
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)

  ;; Display line and column numbers
  (setq line-number-mode    t)
  (setq column-number-mode  t)

  ;; Modeline info
  (display-time-mode 1)
  (setq display-time-day-and-date t)

  ;; Gotta see matching parens
  (show-paren-mode t)

  ;; Auto refresh buffers
  (global-auto-revert-mode 1)

  ;; delete the selection with a keypress
  (delete-selection-mode t)

  ;; the blinking cursor is nothing, but an annoyance
  (blink-cursor-mode -1)

  (global-subword-mode t)

  (electric-pair-mode t))
