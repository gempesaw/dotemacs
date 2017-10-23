;;; timonier-autoloads.el --- automatically extracted autoloads
;;
;;; Code:
(add-to-list 'load-path (directory-file-name (or (file-name-directory #$) (car load-path))))

;;;### (autoloads nil "timonier-mode" "timonier-mode.el" t)
;;; Generated autoloads from timonier-mode.el

(autoload 'timonier-k8s "timonier-mode" "\
Display informations about the Kubernetes cluster.

\(fn)" t nil)

;;;***

;;;### (autoloads nil "timonier-version" "timonier-version.el" t)
;;; Generated autoloads from timonier-version.el

(autoload 'timonier-version "timonier-version" "\
Get the timonier version as string.
If called interactively or if SHOW-VERSION is non-nil, show the
version in the echo area and the messages buffer.
The returned string includes both, the version from package.el
and the library version, if both a present and different.
If the version number could not be determined, signal an error,
if called interactively, or if SHOW-VERSION is non-nil, otherwise
just return nil.

\(fn &optional SHOW-VERSION)" t nil)

;;;***

;;;### (autoloads nil nil ("timonier-custom.el" "timonier-io.el"
;;;;;;  "timonier-k8s.el" "timonier-pkg.el" "timonier-utils.el" "timonier.el")
;;;;;;  t)

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
;;; timonier-autoloads.el ends here
