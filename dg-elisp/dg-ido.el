

;; ido mode
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere

;;; use vertical mode
(ido-vertical-mode 1)

;; ido everywhere, but really
(ido-ubiquitous-mode 1)

;; auto-completion in minibuffer
(icomplete-mode 1)

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-c C-b") 'ibuffer)
(global-set-key (kbd "C-x C-b") 'ido-switch-buffer)

;; for vertical ido, C-n/p is more intuitive
(defun ido-my-keys ()
  "Add my keybindings for ido."
  (define-key ido-file-completion-map (kbd "~") (lambda () (interactive) (insert "~/")))
  (define-key ido-completion-map (kbd "?") (lambda ()
                                             (interactive)
                                             (create-new-shell-here)
                                             (execute-kbd-macro "\C-g" 1))))

(add-hook 'ido-setup-hook 'ido-my-keys)

(setq ido-enable-prefix nil
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10
      ido-default-file-method 'selected-window)

;; ignore list http://www.masteringemacs.org/articles/2010/10/10/introduction-to-ido-mode/
;; (add-to-list 'ido-ignore-buffers "buffers")
;; (add-to-list 'ido-ignore-files "files")
(eval-after-load "ido-mode"
  '(progn
     (add-to-list 'ido-ignore-directories ".git")
     (add-to-list 'ido-ignore-directories "target")
     (add-to-list 'ido-ignore-directories "svn_HDEW")
     (add-to-list 'ido-ignore-directories "node_modules")))

(provide 'dg-minibuffer)
