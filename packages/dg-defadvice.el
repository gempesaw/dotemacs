(defmacro advise-commands (advice-name commands &rest body)
  "Apply advice named ADVICE-NAME to multiple COMMANDS.

The body of the advice is in BODY."
  `(progn
     ,@(mapcar (lambda (command)
                 `(defadvice ,command (before ,(intern (concat (symbol-name command) "-" advice-name)) activate)
                    ,@body))
               commands)))

(defmacro advise-around-commands (advice-name commands &rest body)
  "Apply advice named ADVICE-NAME to multiple COMMANDS.

The body of the advice is in BODY."
  `(progn
     ,@(mapcar (lambda (command)
                 `(defadvice ,command (around ,(intern (concat (symbol-name command) "-" advice-name)) activate)
                    ,@body))
               commands)))

;; automatically save buffers associated with files on buffer switch
;; and on windows switch
(advise-commands "auto-save"
                 (switch-to-buffer other-window switch-window next-error previous-error)
                 (prelude-auto-save-command))

;;; save everything when we focus another frame (even potentially
;;; another emacs frame)
(add-hook 'focus-out-hook 'prelude-auto-save-command)

(defadvice split-window-below (after restore-balanace-below activate)
  (balance-windows))

(defadvice split-window-right (after restore-balance-right activate)
  (balance-windows))

(defadvice delete-window (after restore-balance activate)
  (balance-windows))

(defadvice bookmark-set (after save-bookmarks-automatically activate)
  (bookmark-save))

;; full screen magit-status
(defadvice magit-status (around magit-fullscreen activate)
  ;; µ is 265
  (window-configuration-to-register 265)
  ad-do-it
  (delete-other-windows))

(progn
  (defun inhibit-auto-balance (orig-fun &rest args)
    (noflet ((balance-windows () nil))
            (apply orig-fun args)))

  (advice-add 'magit-ediff-dwim :around #'inhibit-auto-balance))
