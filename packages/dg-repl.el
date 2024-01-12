(use-package repl-driven-development
  :demand t
  :ensure t
  :config
  ;; (repl-driven-development [C-x C-j] java)       ;; e“X”ecute “j”ava
  ;; (repl-driven-development [C-x C-n] javascript) ;; e“X”ecute “n”odejs
  (repl-driven-development [C-x C-p] "python3 -i")     ;; e“X”ecute “p”ython
  ;; (repl-driven-development [C-x C-t] terminal) ;; e“X”ecute “t”erminal

  )
