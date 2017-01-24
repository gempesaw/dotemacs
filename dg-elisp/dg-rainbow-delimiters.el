;;; customizations from http://yoo2080.wordpress.com/2013/09/08/living-with-rainbow-delimiters-mode/
;;; saturate paren colors
(require 'cl-lib)
(require 'color)

(cl-loop
 for index from 1 to rainbow-delimiters-max-face-count
 do
 (let ((face (intern (format "rainbow-delimiters-depth-%d-face" index))))
   (cl-callf color-saturate-name (face-foreground face) 25)))

;;; unmatched parens stick out
(set-face-attribute 'rainbow-delimiters-unmatched-face nil
                    :foreground 'unspecified
                    :inherit 'error
                    :strike-through t)

;;; bold outermost parens
(set-face-attribute 'rainbow-delimiters-depth-1-face nil
                    :weight 'bold)

(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(provide 'dg-rainbow-delimiters)
