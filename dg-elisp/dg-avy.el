(setq avy-background t
      avy-keys '(
                  ?q ?w ?e ?r ?t ?y ?u ?i ?o ?p
                  ?z ?x ?c ?v ?b ?n ?m
                  ?a ?s ?d ?f ?g ?h ?j ?k ?l
                  ))

(setq avy-timeout-seconds 0.1)

(key-chord-define-global "fj" 'avy-goto-char-timer)

(provide 'dg-avy)
