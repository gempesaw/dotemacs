(use-package avy
  :ensure t
  :after (key-chord)

  :bind (("M-s-j" . avy-goto-char))
  :config
  (setq avy-background t
        avy-keys '(
                   ?q ?w ?e ?r ?t ?y ?u ?i ?o ?p
                   ?z ?x ?c ?v ?b ?n ?m
                   ?a ?s ?d ?f ?g ?h ?j ?k ?l
                   )
        avy-timeout-seconds 0.1))
