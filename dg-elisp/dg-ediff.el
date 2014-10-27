;;; courtesy of trey jackson! http://stackoverflow.com/a/9846938/1156644
;;;
;;; setup 'd' to accept code from both sides of the diff in ediff-mode


(require 'ediff-init)           ;ensure the macro is defined, so we can override it

(defmacro ediff-char-to-buftype (arg)
  `(cond ((memq ,arg '(?a ?A)) 'A)
     ((memq ,arg '(?b ?B)) 'B)
     ((memq ,arg '(?c ?C)) 'C)
     ((memq ,arg '(?d ?D)) 'D)
     ))

(require 'ediff)

;; Literally copied from ediff-util
;; need to re-evaluate because it uses the macro defined above
;; and the compiled version needs to be re-compiled with the new definition
;; why a macro????
(defun ediff-diff-to-diff (arg &optional keys)
  "Copy buffer-X'th difference region to buffer Y \(X,Y are A, B, or C\).
If numerical prefix argument, copy the difference specified in the arg.
Otherwise, copy the difference given by `ediff-current-difference'.
This command assumes it is bound to a 2-character key sequence, `ab', `ba',
`ac', etc., which is used to determine the types of buffers to be used for
copying difference regions.  The first character in the sequence specifies
the source buffer and the second specifies the target.

If the second optional argument, a 2-character string, is given, use it to
determine the source and the target buffers instead of the command keys."
  (interactive "P")
  (ediff-barf-if-not-control-buffer)
  (or keys (setq keys (this-command-keys)))
  (if (eq arg '-) (setq arg -1)) ; translate neg arg to -1
  (if (numberp arg) (ediff-jump-to-difference arg))

  (let* ((key1 (aref keys 0))
     (key2 (aref keys 1))
     (char1 (ediff-event-key key1))
     (char2 (ediff-event-key key2))
     ediff-verbose-p)
(ediff-copy-diff ediff-current-difference
         (ediff-char-to-buftype char1)
         (ediff-char-to-buftype char2))
;; recenter with rehighlighting, but no messages
(ediff-recenter)))

(defun ediff-copy-D-to-C (arg)
  "Copy ARGth difference region from both buffers A and B to C.
ARG is a prefix argument.  If nil, copy the current difference region."
  (interactive "P")
  (ediff-diff-to-diff arg "dc"))

(defun ediff-copy-diff (n from-buf-type to-buf-type
              &optional batch-invocation reg-to-copy)
  (let* ((to-buf (ediff-get-buffer to-buf-type))
     ;;(from-buf (if (not reg-to-copy) (ediff-get-buffer from-buf-type)))
     (ctrl-buf ediff-control-buffer)
     (saved-p t)
     (three-way ediff-3way-job)
     messg
     ediff-verbose-p
     reg-to-delete reg-to-delete-beg reg-to-delete-end)

(setq reg-to-delete-beg
      (ediff-get-diff-posn to-buf-type 'beg n ctrl-buf))
(setq reg-to-delete-end
      (ediff-get-diff-posn to-buf-type 'end n ctrl-buf))

(if (eq from-buf-type 'D)
    ;; want to copy *both* A and B
    (if reg-to-copy
    (setq from-buf-type nil)
      (setq reg-to-copy (concat (ediff-get-region-contents n 'A ctrl-buf)
                (ediff-get-region-contents n 'B ctrl-buf))))
  ;; regular code
  (if reg-to-copy
      (setq from-buf-type nil)
    (setq reg-to-copy (ediff-get-region-contents n from-buf-type ctrl-buf))))

(setq reg-to-delete (ediff-get-region-contents
             n to-buf-type ctrl-buf
             reg-to-delete-beg reg-to-delete-end))

(if (string= reg-to-delete reg-to-copy)
    (setq saved-p nil) ; don't copy identical buffers
  ;; seems ok to copy
  (if (or batch-invocation (ediff-test-save-region n to-buf-type))
      (condition-case conds
      (progn
        (ediff-with-current-buffer to-buf
          ;; to prevent flags from interfering if buffer is writable
          (let ((inhibit-read-only (null buffer-read-only)))

        (goto-char reg-to-delete-end)
        (insert reg-to-copy)

        (if (> reg-to-delete-end reg-to-delete-beg)
            (kill-region reg-to-delete-beg reg-to-delete-end))
        ))
        (or batch-invocation
        (setq
         messg
         (ediff-save-diff-region n to-buf-type reg-to-delete))))
    (error (message "ediff-copy-diff: %s %s"
            (car conds)
            (mapconcat 'prin1-to-string (cdr conds) " "))
           (beep 1)
           (sit-for 2) ; let the user see the error msg
           (setq saved-p nil)
           )))
  )

;; adjust state of difference in case 3-way and diff was copied ok
(if (and saved-p three-way)
    (ediff-set-state-of-diff-in-all-buffers n ctrl-buf))

(if batch-invocation
    (ediff-clear-fine-differences n)
  ;; If diff3 job, we should recompute fine diffs so we clear them
  ;; before reinserting flags (and thus before ediff-recenter).
  (if (and saved-p three-way)
      (ediff-clear-fine-differences n))

  (ediff-refresh-mode-lines)

  ;; For diff2 jobs, don't recompute fine diffs, since we know there
  ;; aren't any.  So we clear diffs after ediff-recenter.
  (if (and saved-p (not three-way))
      (ediff-clear-fine-differences n))
  ;; Make sure that the message about saving and how to restore is seen
  ;; by the user
  (message "%s" messg))
))

;; add keybinding in a hook b/c the keymap isn't defined until the hook is run
(add-hook 'ediff-keymap-setup-hook 'add-d-to-ediff-mode-map)

(defun add-d-to-ediff-mode-map ()
  (define-key ediff-mode-map "d" 'ediff-copy-D-to-C))

(provide 'dg-ediff)
