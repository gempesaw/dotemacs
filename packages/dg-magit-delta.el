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
;;;
;;; See `dg-magit-delta-background' for where the added/removed background
;;; comes from; M-x dg-magit-delta-cycle-background to compare them by eye.

(defvar dg-magit-delta-background 'magit
  "Who paints the added/removed background in delta-rendered diffs.

`delta'  delta's own, from the syntax theme: near-black #002800 green
         and #3F0001 red.  Sized to the text, so every line ends in a
         ragged edge partway across the window.
`magit'  delta contributes syntax colors only; `magit-diff-added' and
         friends supply the background.  Those faces are :extend t, so
         they run clean to the window edge.
`none'   no background at all.  The +/- markers stay visible to carry
         the added/removed distinction on their own.")

(defconst dg-magit-delta--overridden-faces
  '(magit-diff-context-highlight
    magit-diff-added magit-diff-added-highlight
    magit-diff-removed magit-diff-removed-highlight)
  "The faces `magit-delta-mode' remaps to `default' so delta can own them.")

(defconst dg-magit-delta--flat-style-args
  '("--plus-style" "syntax" "--minus-style" "syntax"
    "--plus-emph-style" "syntax" "--minus-emph-style" "syntax")
  "Strip every background out of delta's output, keeping the syntax colors.

Delta paints a line background as an SGR run followed by \\e[0K --
erase-to-end-of-line, which a terminal renders as \"fill to the right
margin\".  Emacs has no such concept and xterm-color drops it, which is
exactly why delta's blocks stop dead at the end of the text instead of
extending.  Emacs' own way to say this is a face with :extend t, so the
fix is to let magit's faces do the filling.")

(defvar dg-magit-delta--base-args nil
  "`magit-delta-delta-args' as the package shipped it, before our additions.")

(defvar dg-magit-delta-added-accent "#63C74D"
  "Hue the added background is tinted toward.
Deliberately yellow-green: fairyfloss's own mint is so blue that a wash
of it over a purple frame comes out teal rather than green.")

(defvar dg-magit-delta-removed-accent "#f84034"
  "Hue the removed background is tinted toward -- fairy-carrot-900.")

(defvar dg-magit-delta-background-alpha 0.30
  "How far the diff backgrounds are washed toward their accent, 0.0 to 1.0.
Emacs faces have no alpha channel, so this is composited by hand against
the frame background and stored as a flat color.  The -highlight faces,
which magit uses for the section under point, get half again as much.")

(defun dg-magit-delta--blend (accent alpha)
  "Composite ACCENT over the frame background at ALPHA, as a hex string."
  (let ((over (color-name-to-rgb accent))
        (under (color-name-to-rgb (face-attribute 'default :background nil t))))
    (apply #'color-rgb-to-hex
           (append (cl-mapcar (lambda (a b) (+ b (* alpha (- a b)))) over under)
                   (list 2)))))

(defun dg-magit-delta-apply-faces ()
  "Tint magit's diff backgrounds toward `dg-magit-delta-background-alpha'.
Magit's stock #335533 and #553333 were picked for a near-black frame;
against fairyfloss's #5A5475 they read as holes punched in the buffer."
  (let ((strong (min 1.0 (* 1.5 dg-magit-delta-background-alpha))))
    (set-face-attribute 'magit-diff-added nil :extend t
                        :background (dg-magit-delta--blend
                                     dg-magit-delta-added-accent
                                     dg-magit-delta-background-alpha))
    (set-face-attribute 'magit-diff-added-highlight nil :extend t
                        :background (dg-magit-delta--blend
                                     dg-magit-delta-added-accent strong))
    (set-face-attribute 'magit-diff-removed nil :extend t
                        :background (dg-magit-delta--blend
                                     dg-magit-delta-removed-accent
                                     dg-magit-delta-background-alpha))
    (set-face-attribute 'magit-diff-removed-highlight nil :extend t
                        :background (dg-magit-delta--blend
                                     dg-magit-delta-removed-accent strong))))

(defun dg-magit-delta-set-alpha (alpha)
  "Set `dg-magit-delta-background-alpha' to ALPHA and recolor immediately.
Called with no prefix it nudges by 0.05, so you can dial it in by eye."
  (interactive (list (read-number "Background alpha: "
                                  dg-magit-delta-background-alpha)))
  (setq dg-magit-delta-background-alpha (max 0.0 (min 1.0 alpha)))
  (dg-magit-delta-apply-faces)
  (message "delta background alpha: %.2f  (added %s, removed %s)"
           dg-magit-delta-background-alpha
           (dg-magit-delta--blend dg-magit-delta-added-accent
                                  dg-magit-delta-background-alpha)
           (dg-magit-delta--blend dg-magit-delta-removed-accent
                                  dg-magit-delta-background-alpha)))

(use-package magit-delta
  :ensure t
  :demand t
  :after magit
  :hook (magit-mode . dg-magit-delta-maybe-enable)
  :config
  (setq dg-magit-delta--base-args magit-delta-delta-args)
  (dg-magit-delta-refresh-settings)
  (dg-magit-delta-apply-faces))

(defun dg-magit-delta-refresh-settings ()
  "Push `dg-magit-delta-background' into the settings delta reads."
  (setq magit-delta-hide-plus-minus-markers
        (not (eq dg-magit-delta-background 'none)))
  (setq magit-delta-delta-args
        (append dg-magit-delta--base-args
                (unless (eq dg-magit-delta-background 'delta)
                  dg-magit-delta--flat-style-args))))

(defun dg-magit-delta-maybe-enable ()
  "Enable `magit-delta-mode' only when the delta binary is installed.
The mode shells out on every diff wash, so turning it on without delta
present breaks every magit buffer rather than degrading to plain magit."
  (when (and (fboundp 'magit-delta-mode)
             (executable-find magit-delta-delta-executable))
    (magit-delta-mode 1)

    ;; `magit-delta-mode' unconditionally remaps magit's diff faces to
    ;; `default' on the assumption delta brings its own background.  Under
    ;; `magit' it doesn't, so hand those faces back.
    (when (eq dg-magit-delta-background 'magit)
      (setq face-remapping-alist
            (seq-remove (lambda (entry)
                          (memq (car entry) dg-magit-delta--overridden-faces))
                        face-remapping-alist)))))

(defun dg-magit-delta-cycle-background ()
  "Cycle `dg-magit-delta-background' and re-render every magit buffer."
  (interactive)
  (setq dg-magit-delta-background
        (pcase dg-magit-delta-background
          ('delta 'magit)
          ('magit 'none)
          (_ 'delta)))
  (dg-magit-delta-refresh-settings)

  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (bound-and-true-p magit-delta-mode)
        (magit-delta-mode -1)
        (dg-magit-delta-maybe-enable))))

  (when (derived-mode-p 'magit-mode)
    (magit-refresh))
  (message "delta background: %s" dg-magit-delta-background))
