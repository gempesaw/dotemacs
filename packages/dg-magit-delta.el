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

(defun dg-magit-delta--pristine-args ()
  "The delta args magit-delta shipped with, read from the defcustom itself.

Never build on the live value of `magit-delta-delta-args'.  Doing so
appends the style args on top of themselves every time this file is
evaluated a second time, and delta refuses a repeated --plus-style
outright -- `call-process-region' then replaces the diff with delta's
usage message, which magit washes down to an empty buffer.  init.el used
to load every package file twice, which made that certain rather than
merely possible; re-evaluating the buffer by hand still would."
  (or (ignore-errors
        (eval (car (get 'magit-delta-delta-args 'standard-value)) t))
      magit-delta-delta-args))

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

(defun dg-magit-delta--frame-background (&optional frame)
  "FRAME's background as an RGB triple, or nil if it has no usable one."
  (color-name-to-rgb (face-attribute 'default :background frame t)))

(defun dg-magit-delta--blend (accent alpha &optional under)
  "Composite ACCENT over UNDER at ALPHA, as a hex string.
UNDER is an RGB triple, defaulting to the selected frame's background."
  (apply #'color-rgb-to-hex
         (append (color-blend (color-name-to-rgb accent)
                              (or under (dg-magit-delta--frame-background))
                              alpha)
                 (list 2))))

(defun dg-magit-delta-apply-faces (&optional frame)
  "Tint magit's diff backgrounds toward `dg-magit-delta-background-alpha'.
Magit's stock #335533 and #553333 were picked for a near-black frame;
against fairyfloss's #5A5475 they read as holes punched in the buffer.

Blending needs a background to blend against, and a daemon's initial
frame has none -- `face-attribute' answers `unspecified-bg', which is not
a color.  Wait for a real frame rather than signalling out of :config."
  (let ((under (dg-magit-delta--frame-background frame)))
    (if (not under)
        (add-hook 'after-make-frame-functions #'dg-magit-delta-apply-faces)
      (remove-hook 'after-make-frame-functions #'dg-magit-delta-apply-faces)
      (let ((weak dg-magit-delta-background-alpha)
            (strong (min 1.0 (* 1.5 dg-magit-delta-background-alpha))))
        (set-face-attribute 'magit-diff-added nil :extend t
                            :background (dg-magit-delta--blend
                                         dg-magit-delta-added-accent weak under))
        (set-face-attribute 'magit-diff-added-highlight nil :extend t
                            :background (dg-magit-delta--blend
                                         dg-magit-delta-added-accent strong under))
        (set-face-attribute 'magit-diff-removed nil :extend t
                            :background (dg-magit-delta--blend
                                         dg-magit-delta-removed-accent weak under))
        (set-face-attribute 'magit-diff-removed-highlight nil :extend t
                            :background (dg-magit-delta--blend
                                         dg-magit-delta-removed-accent strong under))))))

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

(defun dg-magit-delta-call-delta-safely ()
  "Pipe the diff through delta, keeping the raw diff if delta fails.

Same as the function it overrides, except it checks the exit status.
magit-delta pipes the buffer through `call-process-region' with REPLACE,
so a delta that rejects its arguments swaps the diff for its own usage
message, which magit then washes down to an empty buffer -- no error, no
diff, nothing to go on."
  (let* ((raw (buffer-string))
         (status (apply #'call-process-region
                        (point-min) (point-max)
                        magit-delta-delta-executable t t nil
                        (magit-delta--make-delta-args)))
         (buffer-read-only nil))
    (if (eq status 0)
        (progn
          (xterm-color-colorize-buffer 'use-overlays)
          (when magit-delta-hide-plus-minus-markers
            (magit-delta-hide-plus-minus-markers)))
      (let ((complaint (string-trim (buffer-string))))
        (erase-buffer)
        (insert raw)
        ;; `magit-diff-wash-diffs' picks up with a forward search from point,
        ;; so leaving it at end-of-buffer costs every section.  The success
        ;; path lands at point-min because that is where
        ;; `xterm-color-colorize-buffer' finishes.
        (goto-char (point-min))
        (message "delta exited %s, showing the plain diff: %s"
                 status (car (split-string complaint "\n")))))))

(defun dg-magit-delta-refresh-settings ()
  "Push `dg-magit-delta-background' into the settings delta reads."
  (setq magit-delta-hide-plus-minus-markers
        (not (eq dg-magit-delta-background 'none)))
  (setq magit-delta-delta-args
        (append (dg-magit-delta--pristine-args)
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

;; Last in the file on purpose: :config calls
;; `dg-magit-delta-refresh-settings' directly, and `:after magit' means that
;; runs the instant magit is already loaded.  Declared above the defuns, that
;; is a void-function on any startup where something pulled magit in first.
(use-package magit-delta
  :ensure t
  :demand t
  :after magit
  :hook (magit-mode . dg-magit-delta-maybe-enable)
  :config
  (dg-magit-delta-refresh-settings)
  (dg-magit-delta-apply-faces)
  (advice-add 'magit-delta-call-delta-and-convert-ansi-escape-sequences
              :override #'dg-magit-delta-call-delta-safely))
