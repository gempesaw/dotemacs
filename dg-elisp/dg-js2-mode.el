(setq js2-global-externs '(
                           "angular"
                           "CodeMirror"
                           "describe"
                           "fdescribe"
                           "it"
                           "fit"
                           "expect"
                           "beforeEach"
                           "afterEach"
                           "module"
                           "inject"
                           ))

(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(delete '("\\.js\\'" . js-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.es6\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

(add-hook 'js2-mode-hook (lambda () (tern-mode t)))
(add-hook 'js2-mode-hook (lambda () (company-mode t)))
(eval-after-load 'tern
  '(require 'company-tern))

(fset 'dg-js2-anon-to-async
   [?\C-r ?\( ?\) return ?\C-  ?\C-f ?\C-f ?\C-f ?\C-f ?\C-f ?\C-w ?a ?s ?y ?n ?c ?  ?f ?u ?n ?c ?t ?i ?o ?n ?  ?\( ?\) ?\C-u ?\C-  ?\C-u ?\C- ])

(provide 'dg-js2-mode)
