(defvar *emacs-load-start* (current-time))

(add-to-list 'load-path "~/.emacs.d/")

(load "alias.el" 'noerror)
(load "customize.el" 'noerror)
(load "defun.el" 'noerror)
(load "emacs-custom.el" 'noerror)
(load "kbd.el" 'noerror)
(load "hooks.el" 'noerror)
(load "my-macros.el" 'noerror)
(load "tabs.el" 'noerror)
(load "themes.el" 'noerror)
(load "selenium-start.el" 'noerror)

;; load all the necessary packages
(load "load-my-packages.el" 'noerror)
;; and then tweak their settings them
(load "modes.el" 'noerror)

(message "My .emacs loaded in %ds"
         (destructuring-bind (hi lo ms) (current-time)
           (- (+ hi lo) (+ (first *emacs-load-start*)
                           (second *emacs-load-start*)))))
