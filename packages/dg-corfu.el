(use-package corfu
  :ensure t
  :init
  (setq corfu-auto t
        corfu-auto-prefix 2
        corfu-auto-delay 0.1)
  (global-corfu-mode)
  :config
  (require 'corfu-popupinfo)
  (setq corfu-popupinfo-delay '(0.4 . 0.2))
  (corfu-popupinfo-mode 1))

(use-package emacs
  :init
  ;; TAB cycle if there are only few candidates
  (setq completion-cycle-threshold 2)

  ;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
  ;; Corfu commands are hidden, since they are not supposed to be used via M-x.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (setq tab-always-indent 'complete))

;; Add extensions
(use-package cape
  :ensure t
  :init
  ;; Global capfs. add-to-list prepends, so list these in reverse priority
  ;; order; final order is cape-file -> cape-dabbrev -> cape-keyword.
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)

  ;; Mode-specific capfs added buffer-locally so they only fire where useful.
  (add-hook 'emacs-lisp-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-elisp-symbol nil t)))
  (add-hook 'text-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-dict nil t)))
  (add-hook 'tex-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-tex nil t)))
  (add-hook 'sgml-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-sgml nil t))))

