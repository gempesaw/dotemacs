(setq js2-global-externs '(
                           "angular"
                           "CodeMirror"
                           "describe"
                           "it"
                           "iit"
                           ))

(add-to-list 'auto-mode-alist '("\\.es6\\'" . js2-mode))

(provide 'dg-js2-mode)
