;;; -*- lexical-binding: t; -*-
;; (use-package claude-code
;;   :demand t
;;   :ensure t
;;   :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)
;;   :config
;;   (setq claude-code-read-only-mode-cursor-type '(hbar)
;;         claude-code-display-buffer-on-send nil)

;;   (add-hook 'claude-code-start-hook
;;             (lambda ()
;;               (setq-local eat-minimum-latency 0.08
;;                           eat-maximum-latency 0.2)))

;;   (claude-code-mode)
;;   :bind ("C-M-s-/" . claude-code-transient)
;;   )

;; (use-package eat
;;   :ensure t
;;   :config
;;   ;; Pass through additional keybindings to Emacs
;;   (add-to-list 'eat-semi-char-non-bound-keys '[?\e ?j]
;;                ;; M-j
;;                )
;;   (add-to-list 'eat-semi-char-non-bound-keys '[\e ?0]
;;                ;; M-0
;;                )
;;   (add-to-list 'eat-semi-char-non-bound-keys '[\e ?`]
;;                ;; M-`
;;                )
;;   (add-to-list 'eat-semi-char-non-bound-keys '[C-M-s-/])
;;   (eat-update-semi-char-mode-map)
;;   (eat-reload))
