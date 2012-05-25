;;; azul-theme.el --- Custom face theme for Emacs

;; Copyright (C) 2010 Tony Garcia.

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see .

;;; Code:

(deftheme azul
  "")

(custom-theme-set-faces
 'azul
 '(default ((t (:background "#000000" :foreground "#40b3ff"))))
 '(cursor ((t (:background "#3360ff" :foreground "#e8d9ff"))))
 '(region ((t (:background "#a3e0ff" :foreground "#0020aa" :weight bold))))
 '(mode-line ((t (:background "#0c0b29" :foreground "#009cde"))))
 '(mode-line-inactive ((t (:background "#0d0d0d" :foreground "#0368ff"))))
 '(fringe ((t (:background "#082559"))))
 '(minibuffer-prompt ((t (:background "#bba6ff" :foreground "#0000e0"))))
 '(font-lock-builtin-face ((t (:foreground "#52dcff"))))
 '(font-lock-comment-face ((t (:foreground "#ff3535"))))
 '(font-lock-constant-face ((t (:foreground "#4060ff"))))
 '(font-lock-function-name-face ((t (:foreground "#09b325"))))
 '(font-lock-keyword-face ((t (:foreground "#997aff"))))
 '(font-lock-string-face ((t (:foreground "#a3ff99"))))
 '(font-lock-type-face ((t (:foreground "#e6ebff"))))
 '(font-lock-variable-name-face ((t (:foreground "#51fc95"))))
 '(font-lock-warning-face ((t (:foreground "#e34dd9" :weight bold))))
 '(isearch ((t (:background "#00a1db" :foreground "#0000ff"))))
 '(lazy-highlight ((t (:background "#6b2c7a"))))
 '(link ((t (:foreground "#66ff7a" :underline t))))
 '(link-visited ((t (:foreground "#449454" :underline t))))
 '(button ((t (:foreground "#cfc67e" :underline t))))
 '(header-line ((t (:background "#2a0a38" :foreground "#b48fff")))))

(provide-theme 'azul)

;; Local Variables:
;; no-byte-compile: t
;; End:

;;; azul-theme.el  ends here
