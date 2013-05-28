(add-to-list 'load-path "~/.emacs.d/")

;; consolidated settings files
(load "passwords.el" 'noerror)
(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "kbd.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)

;; manually load some packages
(load "smart-compile.el" 'noerror)

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)
;; and then tweak their settings
(load "modes.el" 'noerror)

(if (eq system-type 'darwin)
    (progn
      (add-to-list 'load-path "/usr/local/Cellar/mu/HEAD/share/emacs/site-lisp/mu4e")
      (require 'mu4e)))

(add-to-list 'load-path "~/.emacs.d/ensime_2.9.2-0.9.8.1/elisp")
(require 'ensime)

(sc-start-selenium-server)
