;;; -*- lexical-binding: t; -*-
(require 'consult-snapfile)

(defun dg-projectile-worktree-p (project-root)
  "Return non-nil when PROJECT-ROOT is a git worktree, not a real checkout.
Worktrees live at $REPO/.claude/worktrees/<name>, and every linked
worktree — wherever it sits — has a `.git' file instead of a `.git'
directory.  Projectile still works normally inside one; it just never
lands in `projectile-known-projects'."
  (let* ((dir (expand-file-name project-root))
         (dot-git (expand-file-name ".git" dir)))
    (or (string-match-p "/\\.claude/worktrees/" dir)
        (and (file-exists-p dot-git)
             (not (file-directory-p dot-git))))))

(defun dg-projectile-purge-worktrees ()
  "Drop worktrees that already made it into `projectile-known-projects'.
`projectile-ignored-project-function' only gates new additions, so the
ones already serialized to disk need evicting once."
  (interactive)
  (let ((keep (seq-remove #'dg-projectile-worktree-p projectile-known-projects)))
    (when (< (length keep) (length projectile-known-projects))
      (setq projectile-known-projects keep)
      (projectile-save-known-projects))))

(use-package projectile
  :ensure t
  :bind (("s-p" . projectile-switch-project)
         :map projectile-mode-map
         ("s-p" . projectile-switch-project)
         ("s-d" . projectile-find-dir)
         ("s-b" . projectile-switch-to-buffer)
         ("s-f" . consult-snapfile)
         ("s-g" . (lambda () (interactive)
                    (setq current-prefix-arg '(4))
                    (call-interactively 'projectile-ag)))
         ("C-c p p" . projectile-test-project)
         ("C-c p c" . projectile-compile-project)
         ("C-c p /" . dg-projectile-open-shell-in-root))

  :chords (("zb" . (lambda ()
                     (interactive)
                     (let ((projectile-switch-project-action 'projectile-switch-to-buffer))
                       (projectile-switch-project))))
           ("zf" . (lambda ()
                     (interactive)
                     (let ((projectile-switch-project-action 'consult-snapfile))
                       (projectile-switch-project)))))
  :init
  (setq projectile-project-test-cmd "make test")
  (setq projectile-switch-project-action 'projectile-vc)

  ;;; open dired at the root of the directory
  (setq projectile-find-dir-includes-top-level t)

  ;; Never let a worktree become a known project.  Only depth 1, so
  ;; discovery sees ~/opt/<repo> and never descends into .claude/worktrees.
  (setq projectile-ignored-project-function #'dg-projectile-worktree-p)
  (let ((opt (expand-file-name "~/opt")))
    (when (file-directory-p opt)
      (projectile-discover-projects-in-directory opt 1)))
  (projectile-mode 1)
  :config
  (setq projectile-indexing-method 'alien)
  (setq projectile-enable-caching t)

  ;; Forget worktrees whose directory has since been deleted, and evict the
  ;; ones that got recorded before the ignore function existed.
  (setq projectile-auto-cleanup-known-projects t)
  (add-to-list 'projectile-globally-ignored-directories ".claude")
  (dg-projectile-purge-worktrees)

  (setq compilation-read-command nil)

  )
