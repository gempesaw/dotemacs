(use-package key-chord
  :ensure t
  :config
  (key-chord-mode 1)

  (setq key-chord-two-keys-delay .1
        key-chord-one-key-delay .2)

  (add-hook 'minibuffer-setup-hook (lambda ()
                                     (interactive)
                                     (let ((inhibit-message t))
                                       (key-chord-mode -1))))

  (add-hook 'minibuffer-exit-hook (lambda ()
                                    (interactive)
                                    (let ((inhibit-message t))
                                      (key-chord-mode t))))

  ;; movement, shells, smex
  (key-chord-define-global "fj" 'avy-goto-char)
  (key-chord-define-global ",/" 'smex)

  ;; expanding region
  (key-chord-define-global "qk" 'er/expand-region)

  (key-chord-define-global "xg" 'magit-status)
  ;; registers

  (key-chord-define-global "qq" 'window-configuration-to-register)
  (key-chord-define-global "xj" 'jump-to-register)
  (key-chord-define-global "jj" (lambda ()
                                  (interactive)
                                  (bookmark-jump
                                   (ido-completing-read
                                    "Jump to bookmark: "
                                    (bookmark-all-names)))))

  (key-chord-define-global "zk" (lambda () (interactive (kubectl 4))))
  (key-chord-define-global "xk" 'kubectl)

  ;; windows
  (key-chord-define-global "1q" 'delete-other-windows)
  (key-chord-define-global "2w" 'dg-vsplit-last-buffer)
  (key-chord-define-global "3e" 'dg-hsplit-last-buffer)

  ;; files
  (key-chord-define-global "xw" 'ido-write-file)
  (key-chord-define-global "xf" 'find-file)
  (key-chord-define-global "xr" 'find-file-as-root)
  (key-chord-define-global "xd" '[?\C-x ?d return])

  ;; buffers
  (key-chord-define-global "bf" 'eval-buffer)
  (key-chord-define-global "xb" 'ido-switch-buffer)
  (key-chord-define-global "xv" 'switch-to-other-buffer)
  (key-chord-define-global "xh" 'mark-whole-buffer)
  (key-chord-define-global "vv" (lambda () (interactive) (switch-to-buffer "*compilation*")))
  (key-chord-define-global "zs" (lambda () (interactive) (switch-between-buffers "*scratch*")))

  ;; elisp
  (key-chord-define emacs-lisp-mode-map "jk" 'eval-defun)
  (key-chord-define lisp-interaction-mode-map "jk" 'eval-defun)
  (key-chord-define emacs-lisp-mode-map "fd" 'edebug-defun)
  (key-chord-define lisp-interaction-mode-map "fd" 'edebug-defun)

  ;; let me press my yubikey
  (key-chord-define-global "uu" (lambda ()
                                  (interactive)
                                  (key-chord-mode -1)
                                  (run-with-timer 2 nil (lambda ()
                                                          (interactive)
                                                          (key-chord-mode t)))))
  )

(use-package use-package-chords
  :ensure t)
