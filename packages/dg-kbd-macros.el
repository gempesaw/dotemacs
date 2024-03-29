(fset 'ps-aux-to-kill-list
   [?\C-  ?\C-r ?p ?s ?  ?\C-m ?\M-w ?\C-x ?b ?* ?s ?c ?r return ?\M-> return return ?\C-y ?\C-  ?\C-a ?\C-p ?\C-w ?\C-r ?a ?u ?x ?\C-m ?\C-a ?\C-k ?\C-n ?\C-  ?\M-f ?\C-f ?\C-> ?\C-* return ?\C-* ?\M-d ?k ?i ?l ?l ?\M-f ?\; ?\C-k ?\C-d return ?\C-a ?\C-k ?\C-x ?b return ?\M-> ?\C-y])

(fset 'paste-job-id-in-scratch-buffer
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([return 19 106 111 98 13 1 67108896 5 134217847 24 98 42 115 99 114 return 134217790 25 24 98 return 134217835 24 98 return 14] 0 "%d")) arg)))

(fset 'remote-feature-compile
   [?\C-x ?h ?\M-w ?\C-x ?b ?d ?a ?n return ?\C-x ?h backspace ?\C-y ?\M-s f5 ?\C-x ?b return])

(fset 'paste-ids-and-transform
   [?\C-x ?b ?* ?s ?c ?r ?a ?t ?c ?h ?* return ?\M-> return return return return return ?\C-x ?b return ?\M-4 ?\M-x ?p ?a ?s ?t ?e ?- ?j ?o ?b return ?\C-x ?b ?* ?s ?c ?r return ?\C-a ?\M-x ?t ?r ?a ?n ?s ?f ?o ?r ?m return])

(fset 'transform-job-to-urls
   [?\C-s ?j ?o ?b ?  ?i ?d ?\C-m ?\C-\' ?\M-b ?\C-> ?\C-> ?\C-> ?\C-  ?\C-q ?\C-j ?\M-d ?\M-d ?\C-d ?\C-d ?h ?t ?t ?p ?: ?/ ?/ ?s ?a ?u ?c ?e ?l ?a ?b ?s ?. ?c ?o ?m ?/ ?j ?o ?b ?s ?/ ?\C-a return ?c ?h ?r ?o ?m ?e ?  ?- ?  ?\C-n ?\C-a ?f ?f ?  ?- ?  ?\C-n ?\C-a ?i ?e ?  ?8 ?  ?- ?  ?\C-n ?\C-a ?i ?e ?  ?9 ?  ?- ?  ?\C-p ?\C-a ?\M-f ?\C-d ?\C-n ?\C-d ?\C-e return return])

(fset 'format-json
      [?\C-u ?\M-| ?j ?q ?  ?. return])

(fset 'dg-json-to-yaml
      [?\C-u ?\M-| ?n ?p ?x ? ?j ?s ?- ?y ?a ?m ?l return])

(fset 'dg-k2tf
      [?\C-u ?\M-| ?k ?2 ?t ?f return])

(fset 'collapse-json
      [?\C-u ?\M-| ?j ?q ?  ?- ?c ?  ?. return])

(fset 'delete-cmsocket
   [?\C-x ?1 ?\C-x ?b ?* ?s ?c ?r ?t backspace ?a ?t ?c ?h ?* return ?\C-c ?b ?j ?c ?m ?_ ?s ?o ?c ?k ?e ?t return ?t ?D ?y])

(fset 'find-perl-dependencies
   [?\C-y ?\C-  ?\C-p ?\C-p backspace ?\M-< ?\C-  ?\C-n ?\C-n ?\C-n ?\C-e ?\C-w ?\C-k ?\C-s ?u ?s ?e ?\C-m ?\C-\' ?\C-* ?\C-0 ?\C-k return ?\C-x ?h ?\C-u ?\M-| ?s ?o ?r ?t ?  ?| ?  ?u ?n ?i ?q return])

(fset 'tell-qa-about-restart
   [?\C-x ?b ?m ?u ?c backspace backspace backspace ?q ?a backspace backspace ?c ?o ?n ?f ?e ?r ?e ?n ?c ?e ?. ?s ?h ?a ?r ?e ?c ?a ?r ?e return ?\M-> ?r ?e ?s ?t ?a ?r ?t ?i ?n ?g ?  ?Q ?A return ?\C-x ?b return])

(fset 'mu4e-headers-open-jira-ticket
   [?\C-a ?\C-s ?\[ ?j ?i ?r ?a ?\] ?\C-m ?\C-f ?\C-f ?\C-\' ?\C-\' ?\M-w ?\M-x ?b ?r ?o ?w ?s ?e ?- ?u ?r ?l return ?h ?t ?t ?p ?s ?: ?/ ?/ ?a ?r ?n ?o ?l ?d ?m ?e ?d ?i ?a ?. ?j ?i ?r ?a ?. ?c ?o ?m ?/ ?b ?r ?o ?w ?s ?e ?/ ?\C-y ?\C-j ?!])


(fset 'mu4e-headers-open-jira-ticket
   [?\C-a ?\C-s ?\[ ?j ?i ?r ?a ?\] ?\C-m ?\C-f ?\C-f ?\C-\' ?\C-\' ?\M-w ?\M-x ?b ?r ?o ?w ?s ?e ?- ?u ?r ?l return ?h ?t ?t ?p ?s ?: ?/ ?/ ?a ?r ?n ?o ?l ?d ?m ?e ?d ?i ?a ?. ?j ?i ?r ?a ?. ?c ?o ?m ?/ ?b ?r ?o ?w ?s ?e ?/ ?\C-y ?\C-j ?!])

(fset 'mu4e-headers-mark-all-as-read
   [?\M-< ?S ?\M-m ?\C-  ?\C-e ?\M-w ?  ?a ?n ?d ?  ?u ?n ?r ?e ?a ?d return ?\C-x ?h ?! ?x ?y ?s ?\C-y return])

(fset 'mu4e-open-inbox
   [?\M-x ?m ?u ?4 ?e return ?b ?i])
