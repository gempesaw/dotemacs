(eval-after-load 'key-chord
  (progn

    (setq key-chord-two-keys-delay .1
          key-chord-one-key-delay .2)

    (key-chord-mode t)

    ;; movement, shells, smex
    (key-chord-define-global "fj" 'ace-jump-mode)
    (key-chord-define-global ",/" 'smex)

    ;; expanding region
    (key-chord-define-global "qk" 'er/expand-region)

    ;; registers
    (key-chord-define-global "xg" 'magit-status)
    (key-chord-define-global "qq" 'window-configuration-to-register)
    (key-chord-define-global "xj" 'jump-to-register)
    (key-chord-define-global "jj" (lambda ()
                                    (interactive)
                                    (bookmark-jump
                                     (ido-completing-read
                                      "Jump to bookmark: "
                                      (bookmark-all-names)))))

    ;; files
    (key-chord-define-global "xw" 'ido-write-file)
    (key-chord-define-global "xf" 'find-file)
    (key-chord-define-global "xr" 'find-file-as-root)
    (key-chord-define-global "xd" '[?\C-x ?d return])

    ;; buffers
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

    ;; jabber & activity
    (key-chord-define-global "jl" 'jabber-activity-switch-to)
    (key-chord-define-global "hk" 'tracking-next-buffer)
    (key-chord-define-global "zx" 'jabber-connect-all)
    (key-chord-define-global "zc" 'jabber-chat-with)

    (key-chord-define-global ",." (lambda () (interactive) (switch-to-buffer "*<appium>*")))

    (defun dg-key-chord-clear (key &optional map)
      (interactive "sKey to clear: ")
      (if map
          (key-chord-define map key nil)
        (key-chord-define-global key nil)))

    nil))

(provide 'dg-key-chord)
