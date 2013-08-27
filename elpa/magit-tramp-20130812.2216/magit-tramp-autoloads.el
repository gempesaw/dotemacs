;;; magit-tramp-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (or (file-name-directory #$) (car load-path)))

;;;### (autoloads nil "magit-tramp" "magit-tramp.el" (21004 61418
;;;;;;  0 0))
;;; Generated autoloads from magit-tramp.el

(defconst magit-tramp-method "git" "\
TRAMP method for browsing git repositories.")

(defsubst magit-tramp-file-name-p (filename) (let ((v (tramp-dissect-file-name filename))) (string= (tramp-file-name-method v) magit-tramp-method)))

(autoload 'magit-tramp-file-name-handler "magit-tramp" "\


\(fn OPERATION &rest ARGS)" nil nil)

(eval-after-load 'tramp '(progn (add-to-list 'tramp-methods (cons magit-tramp-method nil)) (add-to-list 'tramp-foreign-file-name-handler-alist '(magit-tramp-file-name-p . magit-tramp-file-name-handler))))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; magit-tramp-autoloads.el ends here
