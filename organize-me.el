;; hm minibuffers in minibuffers!
(setq enable-recursive-minibuffers t)

(defun ido-goto-bookmark (bookmark)
  (interactive
   (list (bookmark-completing-read "Jump to bookmark"
                                   bookmark-current-bookmark)))
  (unless bookmark
    (error "No bookmark specified"))
  (let ((filename (bookmark-get-filename bookmark)))
    (if (file-directory-p filename)
        (progn
          (ido-set-current-directory filename)
          (setq ido-text ""))
      (progn
        (ido-set-current-directory (file-name-directory filename))))
    (setq ido-exit        'refresh
          ido-text-init   ido-text
          ido-rotate-temp t)
    (exit-minibuffer)))
