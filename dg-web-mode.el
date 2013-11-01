(defvar dg-web-mode-indent 4
  "I like 4 spaces instead of 2.")

(defun web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-indent-style 2
        web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 4
        web-mode-code-indent-offset 4))

(add-hook 'web-mode-hook  'web-mode-hook)

(provide 'dg-web-mode)
