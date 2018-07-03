(setq js2-global-externs '(
                           "angular"
                           "CodeMirror"
                           "describe"
                           "it"
                           "before"
                           "beforeEach"
                           "afterEach"
                           "after"
                           "module"
                           "inject"
                           "process"
                           "require"
                           "__dirname"
                           "setTimeout"
                           "setInterval"
                           ))
(setq js2-basic-offset 2)

(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(delete '("\\.js\\'" . js-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.es6\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

(eval-after-load 'tern-mode
  (add-hook 'js2-mode-hook (lambda () (tern-mode t))))
(eval-after-load 'company-mode
  (add-hook 'js2-mode-hook (lambda () (company-mode t))))
(eval-after-load 'js-align-mode
  (add-hook 'js2-mode-hook 'js-align-mode))

(eval-after-load 'tern
  '(require 'company-tern))

(fset 'dg-js2-anon-to-async
      [?\C-r ?\) ?. ?* ?= ?> return ?\C-f ?\C-\M-b ?a ?s ?y ?n ?c ?  ?\C-u ?\C- ])

(define-key js2-mode-map (kbd "<backtab>") #'js2-indent-bounce)

(defun dg-js2-smarter-find-definition ()
  (interactive)
  (unless (dg-js2--find-require)
    (unless (dumb-jump-go)
        (unless (js2-jump-to-definition)
          (tern-find-definition)))))

(defun dg-js2--find-require ()
  (when (s-match "require" (thing-at-point 'line t))
    (save-excursion
      (end-of-line)
      (backward-word)
      (let ((root (locate-dominating-file buffer-file-name ".git"))
            (needle (s-replace "'" "" (thing-at-point 'sexp t))))
        (dg-js2--try-open (if (s-starts-with-p "." needle)
                         needle
                       (format "%snode_modules/%s" root needle)))))))

(defun dg-js2--try-open (path)
  (let* ((indexJs (format "%s/index.js" path))
         (pathJs (format "%s.js" path))
         (file (car (-filter 'file-exists-p `(,indexJs ,pathJs ,path)))))
    (xref-push-marker-stack)
    (if file
        (find-file file)
      (dired directory))))

(defun dg-js2-toggle-only (type)
  (save-excursion
    (re-search-backward (format "%s\\(\.only\\)?('" type))
    (if (s-match (format "%s\.only" type) (thing-at-point 'line t))
        (progn
          (forward-char (length type))
          (delete-char 5))
      (delete-char (length type))
      (insert (format "%s.only" type)))))

(defun dg-js2-toggle-it-only ()
  (interactive)
  (dg-js2-toggle-only "it"))

(defun dg-js2-toggle-describe-only ()
  (interactive)
  (dg-js2-toggle-only "describe"))

;; https://github.com/mooz/js2-mode/issues/162#issuecomment-271995425
;; (advice-add 'js--multi-line-declaration-indentation :around (lambda (orig-fun &rest args) nil))

;; https://emacs.stackexchange.com/a/34534/672
(defun js--proper-indentation-custom (parse-status)
  "Return the proper indentation for the current line."
  (save-excursion
    (back-to-indentation)
    (cond ((nth 4 parse-status)    ; inside comment
           (js--get-c-offset 'c (nth 8 parse-status)))
          ((nth 3 parse-status) 0) ; inside string
          ((eq (char-after) ?#) 0)
          ((save-excursion (js--beginning-of-macro)) 4)
          ;; Indent array comprehension continuation lines specially.
          ((let ((bracket (nth 1 parse-status))
                 beg)
             (and bracket
                  (not (js--same-line bracket))
                  (setq beg (js--indent-in-array-comp bracket))
                  ;; At or after the first loop?
                  (>= (point) beg)
                  (js--array-comp-indentation bracket beg))))
          ((js--ctrl-statement-indentation))
          ((nth 1 parse-status)
           ;; A single closing paren/bracket should be indented at the
           ;; same level as the opening statement. Same goes for
           ;; "case" and "default".
           (let ((same-indent-p (looking-at "[]})]"))
                 (switch-keyword-p (looking-at "default\\_>\\|case\\_>[^:]"))
                 (continued-expr-p (js--continued-expression-p))
                 (original-point (point))
                 (open-symbol (nth 1 parse-status)))
             (goto-char (nth 1 parse-status)) ; go to the opening char
             (skip-syntax-backward " ")
             (when (eq (char-before) ?\)) (backward-list))
             (back-to-indentation)
             (js--maybe-goto-declaration-keyword-end parse-status)
             (let* ((in-switch-p (unless same-indent-p
                                   (looking-at "\\_<switch\\_>")))
                    (same-indent-p (or same-indent-p
                                       (and switch-keyword-p
                                            in-switch-p)))
                    (indent
                     (cond (same-indent-p
                            (current-column))
                           (continued-expr-p
                            (goto-char original-point)
                            ;; Go to beginning line of continued expression.
                            (while (js--continued-expression-p)
                              (forward-line -1))
                            ;; Go to the open symbol if it appears later.
                            (when (> open-symbol (point))
                              (goto-char open-symbol))
                            (back-to-indentation)
                            (+ (current-column)
                               js-indent-level
                               js-expr-indent-offset))
                           (t
                            (+ (current-column) js-indent-level
                               (pcase (char-after (nth 1 parse-status))
                                 (?\( js-paren-indent-offset)
                                 (?\[ js-square-indent-offset)
                                 (?\{ js-curly-indent-offset)))))))
               (if in-switch-p
                   (+ indent js-switch-indent-offset)
                 indent))))
          ((js--continued-expression-p)
           (+ js-indent-level js-expr-indent-offset))
          (t 0))))

(advice-add 'js--proper-indentation :override 'js--proper-indentation-custom)

(setq js-indent-align-list-continuation nil
      js-expr-indent-offset 0
      js-chain-indent nil)

(define-key my-keys-minor-mode-map (kbd "M-.") nil)

(define-key js2-mode-map (kbd "M-.") #'dg-js2-smarter-find-definition)
(define-key tern-mode-keymap (kbd "M-.") #'dg-js2-smarter-find-definition)
(define-key js2-mode-map (kbd "C-c t i") #'dg-js2-toggle-it-only)
(define-key js2-mode-map (kbd "C-c t d") #'dg-js2-toggle-describe-only)

(provide 'dg-js2-mode)
