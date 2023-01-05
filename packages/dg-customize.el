(use-package emacs
  :config

  ;; split vertically all the time
  (setq split-width-threshold 1)
  (setq split-height-threshold nil)

  ;; No splash screen please ... jeez
  (setq inhibit-startup-message t)

  (add-hook 'before-save-hook 'cleanup-buffer-safe)

  ;; disable mouse scrolling
  (setq mouse-wheel-scroll-amount '(1))
  (setq mouse-wheel-progressive-speed nil)

  ;; I never use downcase-region
  (put 'upcase-region 'disabled nil)
  (put 'downcase-region 'disabled nil)

  ;; "y or n" instead of "yes or no"
  (fset 'yes-or-no-p 'y-or-n-p)

  ;; Explicitly show the end of a buffer
  (set-default 'indicateq-empty-lines t)

  ;; Make sure all backup files only live in one place
  (setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

  ;; dired - reuse current buffer by pressing 'a'
  (put 'dired-find-alternate-file 'disabled nil)

  ;; term face settings
  (setq term-default-bg-color nil)

  ;; something turned iedit on, but we don't want it
  (setq iedit-toggle-key-default nil)

  ;; todo: add default fonts for windows and linux
  (set-face-attribute 'default nil :family "Comic Code" :height 130 :weight 'normal)

  ;; ignore undo-too-big warning
  (push '(undo discard-info) warning-suppress-types)

  (setq dired-recursive-copies 'top)
  (setq dired-recursive-deletes 'top)

  ;; http://mixandgo.com/blog/how-i-ve-convinced-emacs-to-dance-with-ruby
  (progn
    (defun dg-create-non-existent-directory ()
      (let ((parent-directory (file-name-directory buffer-file-name)))
        (when (and (not (file-exists-p parent-directory))
                   (y-or-n-p (format "Directory `%s' does not exist! Create it?" parent-directory)))
          (make-directory parent-directory t))))
    (add-to-list 'find-file-not-found-functions #'dg-create-non-existent-directory))

  (setq-default fill-column 80)
  (set-frame-parameter (selected-frame) 'alpha '(100 . 100))
  )
