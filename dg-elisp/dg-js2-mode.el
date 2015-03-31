(setq js2-global-externs '(
                           "angular"
                           "CodeMirror"
                           "describe"
                           "it"
                           "iit"
                           ))

(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(delete '("\\.js\\'" . js-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.es6\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

(add-hook 'js2-mode-hook (lambda () (tern-mode t)))
(eval-after-load 'tern
  '(require 'company-tern))

(provide 'dg-js2-mode)
