;; disable menu and toolbar
(menu-bar-mode 0)
(tool-bar-mode 0)

;; disable mouse scrolling
(setq mouse-wheel-scroll-amount '(1))
(setq mouse-wheel-progressive-speed nil)

;; make OS X command button meta
(setq mac-option-key-is-meta nil)
(setq mac-command-key-is-meta t)
(setq mac-command-modifier 'meta)
(setq mac-option-modifier nil)

;; I never use downcase-region
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

;; Don't show the startup screen
(setq inhibit-startup-message t)

;; "y or n" instead of "yes or no"
(fset 'yes-or-no-p 'y-or-n-p)

;; Display line and column numbers
(setq line-number-mode    t)
(setq column-number-mode  t)

;; Modeline info
(display-time-mode 1)

;; battery mode might not work for desktops
;; (display-battery-mode 1)

;; Small fringes
(set-fringe-mode '(1 . 1))

;; Emacs gurus don't need no stinking scroll bars
(when (fboundp 'toggle-scroll-bar)
  (toggle-scroll-bar -1))
(toggle-scroll-bar -1)

;; Explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; Make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Gotta see matching parens
(show-paren-mode t)

;; Trailing whitespace is unnecessary
(add-hook 'before-save-hook (lambda () (whitespace-cleanup)))

;; Trash can support
(setq delete-by-moving-to-trash t)

;; tramp settings
(eval-after-load "tramp"
  '(progn
     (setq tramp-default-method "ssh")
     (setq tramp-auto-save-directory "~/tmp/tramp/")
     (setq tramp-chunksize 2000)
     ))

;; get gpg into the path
(add-to-list 'exec-path "/usr/bin")
(add-to-list 'exec-path "/usr/local/bin")
(setq epg-gpg-program "/usr/local/bin/gpg")

;; smart compile
(eval-after-load "smart-compile"
  '(progn
     (setq compilation-read-command nil)
     (add-to-list 'smart-compile-alist '("\\.feature\\'" . "perl -w /opt/honeydew/bin/honeydew.pl -isMine -feature=%F") )
     (add-to-list 'smart-compile-alist '("\\.t\\'" . "perl -w %F") )
     (add-to-list 'smart-compile-alist '("\\.pl\\'" . "perl -w %F") )
     (add-to-list 'smart-compile-alist '("\\.php\\'" . "php %F") )
     ))

;; don't ask about files
(setq compilation-ask-about-save nil)

;; don't compile based on last buffer
(setq compilation-last-buffer nil)

;; ido customization
(setq ido-enable-prefix nil
      ido-enable-flex-matching t ; fuzzy matching is a must have
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10
      ido-default-file-method 'selected-window
      ;; ido-file-extensions-order '(".org" ".txt" ".py" ".emacs" ".xml" ".el" ".ini" ".cfg" ".cnf")
      )

;; ignore list http://www.masteringemacs.org/articles/2010/10/10/introduction-to-ido-mode/
;; (add-to-list 'ido-ignore-buffers "buffers")
;; (add-to-list 'ido-ignore-files "files")
(eval-after-load "ido-mode"
  '(progn
     (add-to-list 'ido-ignore-directories "target")
     (add-to-list 'ido-ignore-directories "svn_HDEW")
     (add-to-list 'ido-ignore-directories "node_modules")))

;; Display ido results vertically, rather than horizontally
(setq ido-decorations (quote ("\n-> " "" "\n   " "\n   ..." "[" "]" " [No match]" " [Matched]" " [Not readable]" " [Too big]" " [Confirm]")))
(defun ido-disable-line-trucation () (set (make-local-variable 'truncate-lines) nil))
(add-hook 'ido-minibuffer-setup-hook 'ido-disable-line-trucation)


;; make dired-find-file faster
;; http://www.masteringemacs.org/articles/2011/03/25/working-multiple-files-dired/
(eval-after-load "find-dired"
  '(progn
     (setq find-ls-option '("-print0 | xargs -0 ls -ld" . "-ld"))
     ))

;; uniquify options
(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward-angle-brackets)
(setq uniquify-strip-common-suffix 'nil)

(setq custom-file "~/.emacs.d/emacs-custom.el")

(setq win-switch-idle-time 0.5)

(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setenv "NODE_PATH" (concat (getenv "NODE_PATH") "/Usr/Local/lib/node_modules"))
(setq exec-path (append exec-path '("/usr/local/bin")))

;; erc setup
(eval-after-load "erc-match"
  '(progn
     (setq erc-track-enable-keybindings nil)))
     (setq erc-keywords '("resolve" "dgempesaw"))

(eval-after-load "saveplace"
  '(progn
     ;; saveplace remembers your location in a file when saving files
     (setq save-place-file (concat user-emacs-directory "saveplace"))
     ;; activate it for all buffers
     (setq-default save-place t)))

(defvar my-keys-minor-mode-map (make-keymap) "my-keys-minor-mode keymap.")

(define-minor-mode my-keys-minor-mode
  "A minor mode so that my key settings override annoying major modes."
  t " my-keys" 'my-keys-minor-mode-map)

(eval-after-load "autopair"
  '(progn
     (autopair-global-mode)))

(eval-after-load "regex-tool"
  '(progn
     (setq regex-tool-backend "perl")))

(eval-after-load "multiple-cursors"
  '(progn
     (setq multiple-cursors-mode-enabled-hook nil)
     (setq multiple-cursors-mode-disabled-hook nil)
     (add-hook 'multiple-cursors-mode-enabled-hook  (lambda () (autopair-mode 0)))
     (add-hook 'multiple-cursors-mode-disabled-hook (lambda () (autopair-mode 1)))
     ))

(eval-after-load "powerline"
  '(progn
     (custom-set-faces
      '(mode-line ((t (:foreground "#030303" :background "cyan" :box nil))))
      '(mode-line-inactive ((t (:foreground "#f9f9f9" :background "#666666" :box nil)))))

     (setq powerline-arrow-shape 'arrow)
     (setq powerline-color1 "grey22")
     (setq powerline-color2 "grey40")))

;; switch windows using home row keys
(setq switch-window-shortcut-style 'qwerty)

;; automatically save buffers when finishing a wgrep session
(setq wgrep-auto-save-buffer t)

(eval-after-load 'magit
  '(progn
     (set-face-foreground 'magit-diff-add "green3")
     (set-face-foreground 'magit-diff-del "red3")
     (set-face-background 'magit-item-highlight "gray17")))

(add-hook 'w3m-display-hook 'my-w3m-rename-buffer)

(add-hook 'w3m-display-hook
          (lambda (url)
            (let ((buffer-read-only nil))
              (delete-trailing-whitespace))))

;; use the cool js2-mode from yegge and mooz
(autoload 'js2-mode "js2-mode" nil t)
(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.js$'" . js2-mode))

;; explicitly state bookmarks
(setq bookmarks-default-file "~/.emacs.d/bookmarks")

;; jabby wabby
(setq jabber-account-list '(("gempesaw@gmail.com"
                              (:network-server . "talk.google.com")
                              (:connection-type . ssl))
                              (:port . 443)))
(setq jabber-alert-presence-hooks nil)

;; tumblesocks
(setq tumblesocks-blog "danzorx.tumblr.com")
(setq tumblesocks-post-default-state 'queue)
(if (require 'sasl nil t)
      (setq oauth-nonce-function #'sasl-unique-id)
    (setq oauth-nonce-function #'oauth-internal-make-nonce))
