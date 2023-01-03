;;; customizations from http://yoo2080.wordpress.com/2013/09/08/living-with-rainbow-delimiters-mode/
;;; saturate paren colors

(use-package rainbow-delimiters
  :ensure t
  :requires (cl-lib color)
  :config 
  (set-face-attribute 'rainbow-delimiters-unmatched-face nil
                      :foreground 'unspecified
                      :inherit 'error
                      :strike-through t)
  
  ;;; bold outermost parens
  (set-face-attribute 'rainbow-delimiters-depth-1-face nil
                      :weight 'bold)

  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))

