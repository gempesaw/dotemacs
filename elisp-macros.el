(defmacro advise-commands (advice-name commands &rest body)
  "Apply advice named ADVICE-NAME to multiple COMMANDS.

The body of the advice is in BODY."
  `(progn
     ,@(mapcar (lambda (command)
                 `(defadvice ,command (before ,(intern (concat (symbol-name command) "-" advice-name)) activate)
                    ,@body))
               commands)))


(defmacro sc-qa-box-name-conditionals ()
  (cond ((equal sc-restart-type "all") '(or (string= name "scqawebpub2f")
                                            (string= name "scqawebarmy2f")
                                            (string= name "scqadata2f")
                                            (string= name "scqaschedulemaster2f")
                                            (string= name "scqawebauth2f")))
        ((equal sc-restart-type "half") '(or (string= name "scqawebpub2f")
                                             (string= name "scqadata2f")
                                             (string= name "scqawebarmy2f")
                                             (string= name "scqawebauth2f")))))
