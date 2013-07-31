(add-to-list 'load-path "~/.emacs.d/")

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)

;; consolidated settings files
(load "elisp-macros.el" 'noerror)
(load "passwords.el" 'noerror)
(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "defadvice.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "feature-mode.el")
(load "hooks.el" 'noerror)
(load "kbd.el" 'noerror)
(load "modes.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)

(if (eq system-type 'darwin)
    (progn
      (add-to-list 'load-path "/usr/local/Cellar/mu/HEAD/share/emacs/site-lisp/mu4e")
      (require 'mu4e)))

(sc-start-selenium-server)
