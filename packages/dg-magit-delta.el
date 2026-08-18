;;; -*- lexical-binding: t; -*-
;;; Syntax highlighting inside magit's own diffs, rather than in a separate
;;; buffer the way `dg-magit-diff-syntax' (M-d) does it.  delta re-colors the
;;; raw git output before magit washes it, so the diff stays a real magit
;;; diff -- staging, discarding and visiting all still work on it.
;;;
;;; Needs the delta binary: brew install git-delta.  Toggle per buffer with
;;; M-x magit-delta-mode; M-d remains available either way.
;;;
;;; delta also reads the [delta] section of ~/.gitconfig.  Setting
;;; side-by-side there would break the magit integration, which assumes
;;; delta's --color-only single-column output.

(use-package magit-delta
  :ensure t
  :demand t
  :after magit
  :hook (magit-mode . dg-magit-delta-maybe-enable)
  :config
  ;; magit-delta remaps magit's own diff faces to `default' and lets delta
  ;; supply the color, so the flat green goes away entirely.
  (setq magit-delta-hide-plus-minus-markers t))

(defun dg-magit-delta-maybe-enable ()
  "Enable `magit-delta-mode' only when the delta binary is installed.
The mode shells out on every diff wash, so turning it on without delta
present breaks every magit buffer rather than degrading to plain magit."
  (when (and (fboundp 'magit-delta-mode)
             (executable-find magit-delta-delta-executable))
    (magit-delta-mode 1)))
