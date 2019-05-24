(require 'web-mode)

(defvar dg-web-mode-indent 4
  "I like 4 spaces instead of 2.")

(defun web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-enable-auto-quoting nil
        web-mode-indent-style 2
        web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

(define-key web-mode-map (kbd "M-;") 'web-mode-comment-or-uncomment)

(add-hook 'web-mode-hook  'web-mode-hook)
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.php[s345t]?\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("Amkfile" . web-mode))
(add-to-list 'auto-mode-alist '("\\.amk$" . web-mode))

(setq web-mode-content-types-alist
  '(("jsx" . "\\.js[x]?\\'")))

(provide 'dg-web-mode)
