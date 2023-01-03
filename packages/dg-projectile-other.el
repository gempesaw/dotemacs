;; -*- lexical-binding: t -*-
(require 'transient)

(defun dg-projectile-other-repo (fn)
  (interactive)
  (let ((projectile-switch-project-action fn))
    (projectile-switch-project)))

(defun dg-browse-git-link-with-suffix (suffix)
  (interactive)
  (let* ((git-link-open-in-browser nil)
         (_ (git-link-homepage (git-link--select-remote)))
         (base-url (substring-no-properties (car kill-ring))))
    (message (format "%s/%s" base-url suffix))
    (browse-url (format "%s/%s" base-url suffix))))

(transient-define-prefix dg-transient-projectile-open ()
  "Choose action to perform"
  ["This Repo"
   ["Open in browser"
    ("o" "pull requests list" forge-browse-pullreqs)
    ("p" "open specific pull request" dg-maybe-forge-browse-pullreq)
    ("l" "open repo homepage" git-link-homepage)
    ("r" "releases" (lambda (&optional args) (interactive) (dg-browse-git-link-with-suffix "releases")))
    ("c" "create release" (lambda (&optional args) (interactive) (dg-browse-git-link-with-suffix "releases/new")))
    ]

   ["In Emacs"
    ("f" "find file" projectile-find-file)
    ("g" "ag" projectile-ag)
    ("n" "forge" forge-dispatch)]
   ]

  ["Switch Repo"
   ("m" "switch repo first" dg-transient-projectile-switch-open)
   ]
  )

(transient-define-prefix dg-transient-projectile-switch-open ()
  "Switch Repo and perform action"
  ["Choose action"
   ["Open in browser"
    ("o" "pull requests list" (lambda (&optional args) (interactive) (dg-projectile-other-repo 'forge-browse-pullreqs)))
    ("p" "open specific pull request" (lambda (&optional args) (interactive) (dg-projectile-other-repo 'dg-maybe-forge-browse-pullreq)))
    ("l" "open repo homepage" (lambda (&optional args) (interactive) (dg-projectile-other-repo (apply-partially 'git-link-homepage 'origin))))
    ("r" "releases" (lambda (&optional args) (interactive) (dg-projectile-other-repo (apply-partially 'dg-browse-git-link-with-suffix "releases"))))
    ("c" "create release" (lambda (&optional args) (interactive) (dg-projectile-other-repo (apply-partially 'dg-browse-git-link-with-suffix "releases/new"))))
    ]

   ["In Emacs"
    ("f" "find file"(lambda (&optional args) (interactive) (dg-projectile-other-repo 'projectile-find-file)))
    ("g" "ag" (lambda (&optional args) (interactive) (dg-projectile-other-repo (apply-partially 'call-interactively 'projectile-ag))))]
   ])

(key-chord-define-global "qp" 'dg-transient-projectile-open)
(key-chord-define-global "qm" 'dg-transient-projectile-switch-open)

(global-set-key (kbd "C-c C-o") 'dg-transient-projectile-open)

(provide 'dg-projectile-other)
