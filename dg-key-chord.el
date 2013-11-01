(eval-after-load 'key-chord
  (progn
    (key-chord-mode t)
    (key-chord-define-global "xw" 'ido-write-file)
    (key-chord-define-global "xg" 'magit-status)
    (key-chord-define-global "qq" 'window-configuration-to-register)
    (key-chord-define-global "xj" 'jump-to-register)
    (key-chord-define-global "xf" 'find-file)
    (key-chord-define-global "xr" 'find-file-as-root)
    (key-chord-define-global "xd" '[?\C-x ?d return])
    (key-chord-define-global "xb" 'ido-switch-buffer)
    (key-chord-define-global "xv" 'switch-to-other-buffer)
    (key-chord-define-global "xh" 'mark-whole-buffer)
    (key-chord-define-global "jk" 'eval-defun)
    (key-chord-define-global "jl" 'jabber-activity-switch-to)
    (key-chord-define-global "bj" (lambda ()
                                    (interactive)
                                    (bookmark-jump
                                     (ido-completing-read
                                      "Jump to bookmark: "
                                      (bookmark-all-names)))))
    nil))

(provide 'dg-key-chord)
