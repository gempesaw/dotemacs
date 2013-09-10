(require 'flx-ido)

;; ido mode
(ido-mode t) ; enable ido for buffer/file switching
(ido-everywhere t) ;enable ido everywhere

;; Use ido everywhere
(ido-ubiquitous 1)

(flx-ido-mode 1)

;; auto-completion in minibuffer
(icomplete-mode 1)

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-c C-b") 'ibuffer)
(global-set-key (kbd "C-x C-b") 'ido-switch-buffer)

;; for vertical ido, C-n/p is more intuitive
(defun ido-my-keys ()
  "Add my keybindings for ido."
  (define-key ido-completion-map (kbd "C-n") 'ido-next-match)
  (define-key ido-completion-map (kbd "C-p") 'ido-prev-match)
  (define-key ido-file-completion-map
              (kbd "~")
              (lambda ()
                (interactive)
                (insert "~/")
                ;; (if (looking-back "/")
                ;;     (insert "~/")
                ;;   (call-interactively 'self-insert-command))
                )))

(add-hook 'ido-setup-hook 'ido-my-keys)

;; turn up gc threshold to speed up flx
(setq gc-cons-threshold 20000000
      ;; disable ido faces to see flx highlights.
      ido-use-faces nil

      ido-enable-prefix nil
      ido-enable-flex-matching t ; fuzzy matching is a must have
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10
      ido-default-file-method 'selected-window)

;; ignore list http://www.masteringemacs.org/articles/2010/10/10/introduction-to-ido-mode/
;; (add-to-list 'ido-ignore-buffers "buffers")
;; (add-to-list 'ido-ignore-files "files")
(eval-after-load "ido-mode"
  '(progn
     (add-to-list 'ido-ignore-directories "target")
     (add-to-list 'ido-ignore-directories "svn_HDEW")
     (add-to-list 'ido-ignore-directories "node_modules")))

;; Display ido results vertically, rather than horizontally
(setq ido-decorations '("\n-> "
                        ""
                        "\n   "
                        "\n   ..."
                        "[" "]"
                        " [No match]"
                        " [Matched]"
                        " [Not readable]"
                        " [Too big]"
                        " [Confirm]"))
(defun ido-disable-line-trucation () (set (make-local-variable 'truncate-lines) nil))
(add-hook 'ido-minibuffer-setup-hook 'ido-disable-line-trucation)

(provide 'dg-minibuffer)
