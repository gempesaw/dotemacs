(defvar my-keys-minor-mode-map (make-keymap) "my-keys-minor-mode keymap.")

(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  t "" 'my-keys-minor-mode-map)

(defun my-minibuffer-setup-hook ()
  (my-keys-minor-mode 0))

;; activate my minor mode to override keybindings
(my-keys-minor-mode 1)

(defun get-next-quote (q)
  (cond
   ((s-equals-p q "\"") "'")
   ((s-equals-p q "'") "`")
   ((s-equals-p q "`") "\"")))

(defun toggle-quotes ()
  (interactive)
  (save-excursion
    (let* ((opening (progn (beginning-of-line)
                           (re-search-forward "[`'\"]")))
           (quote-type (string (char-before)))
           (closing (progn (end-of-line)
                           (re-search-backward quote-type)))
           (replacement (get-next-quote quote-type)))
      (goto-char opening)
      (delete-char -1)
      (insert replacement)
      (goto-char closing)
      (delete-char 1)
      (insert replacement))))

(define-key my-keys-minor-mode-map (kbd "C-c '") 'toggle-quotes)
(define-key my-keys-minor-mode-map (kbd "C-c C-'") 'toggle-quotes)

(provide 'dg-override-keys)
