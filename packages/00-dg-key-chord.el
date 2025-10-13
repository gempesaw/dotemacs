(use-package key-chord
  :demand t
  :ensure t
  :config
  (key-chord-mode 1)

  (setq key-chord-two-keys-delay .1
        key-chord-one-key-delay .2
        key-chord-safety-interval-forward .01
        key-chord-safety-interval-backward .1)


  (add-hook 'minibuffer-setup-hook (lambda ()
                                     (interactive)
                                     (let ((inhibit-message t))
                                       (key-chord-mode -1))))

  (add-hook 'minibuffer-exit-hook (lambda ()
                                    (interactive)
                                    (let ((inhibit-message t))
                                      (key-chord-mode t))))

  ;; movement, shells
  (key-chord-define-global "fj" 'avy-goto-char)

  ;; expanding region
  (key-chord-define-global "qk" 'er/expand-region)

  (key-chord-define-global "`=" (lambda () (interactive) (key-chord-mode -1)))

  (key-chord-define-global "xg" 'magit-status)
  ;; registers

  (key-chord-define-global "qq" 'window-configuration-to-register)
  (key-chord-define-global "xj" 'jump-to-register)
  (key-chord-define-global "jj" (lambda ()
                                  (interactive)
                                  (bookmark-jump
                                   (completing-read
                                    "Jump to bookmark: "
                                    (bookmark-all-names)))))

  ;; M-s-k
  (key-chord-define-global "zk" 'kubectl-prompt)
  (key-chord-define-global "xk" 'kubectl)

  ;; windows
  (key-chord-define-global "1q" 'delete-other-windows)
  (key-chord-define-global "2w" 'dg-vsplit-last-buffer)
  (key-chord-define-global "3e" 'dg-hsplit-last-buffer)
  (key-chord-define-global "1w" 'delete-other-windows)
  (key-chord-define-global "2e" 'dg-vsplit-last-buffer)
  (key-chord-define-global "3r" 'dg-hsplit-last-buffer)

  ;; files
  (key-chord-define-global "xw" 'ido-write-file)
  (key-chord-define-global "xf" 'find-file)
  (key-chord-define-global "xr" 'find-file-as-root)
  (key-chord-define-global "xd" '[?\C-x ?d return])

  ;; buffers
  (key-chord-define emacs-lisp-mode-map "bf" 'eval-buffer)
  (key-chord-define-global "xb" 'consult-buffer)
  (key-chord-define-global "xv" 'switch-to-other-buffer)
  (key-chord-define-global "xh" 'mark-whole-buffer)
  (key-chord-define-global "vv" 'vterm)
  ;; (key-chord-define-global "zs" (lambda () (interactive) (switch-between-buffers "*scratch*")))
  (key-chord-define-global "vc" nil)
  (key-chord-define-global "lv" (lambda () (interactive)
                                  (insert "lv")
                                  (message "disabling key chord mode because you typed lv")
                                  (dg-toggle-key-chord-mode)))



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

(use-package use-package-chords :ensure t)

(defun dg-toggle-key-chord-mode ()
  (interactive)
  (key-chord-mode -1)
  (when dg-toggle-key-chord-mode-timer
    (cancel-timer dg-toggle-key-chord-mode-timer))
  (setq dg-toggle-key-chord-mode-timer (run-at-time 10 nil (lambda ()
                                                             (message "re-enabling key-chord mode")
                                                             (key-chord-mode +1)))))

(defun dg-toggle-keychord-for-yubikey (string)
  (when (let ((case-fold-search nil)) ;; ignore case
          (string-match "Passcode"
                        (string-replace "\r" "" string)))
    ;; `run-at-time` so we don't hold up the shell interactivity
    (message "disabling keychord mode because we matched something in comint output ")
    (run-at-time 0 nil #'dg-toggle-keychord)
    nil))

(add-hook 'comint-output-filter-functions #'dg-toggle-keychord-for-yubikey)
