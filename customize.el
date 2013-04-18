;; Turn off mouse interface early in startup to avoid momentary display
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen please ... jeez
(setq inhibit-startup-message t)

;; disable mouse scrolling
(setq mouse-wheel-scroll-amount '(1))
(setq mouse-wheel-progressive-speed nil)

;; make OS X command button meta
(setq mac-option-key-is-meta nil)
(setq mac-command-key-is-meta t)
(setq mac-command-modifier 'meta)

;; oh cool we get a super button!
(setq mac-option-modifier 'super)

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
(setq display-time-day-and-date t)

;; Small fringes
(set-fringe-mode '(1 . 1))

;; Explicitly show the end of a buffer
(set-default 'indicate-empty-lines t)

;; Make sure all backup files only live in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

;; Gotta see matching parens
(show-paren-mode t)

;; Various superfluous white-space. Just say no.
(add-hook 'before-save-hook 'cleanup-buffer-safe)

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
     (add-to-list 'smart-compile-alist '("\\.php\\'" . "php %F") )
     (add-to-list 'smart-compile-alist '("\\.md\\'" . (markdown-preview-with-syntax-highlighting)))))

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

(setenv "PATH" (concat (getenv "PATH") ":/usr/local/bin"))
(setenv "NODE_PATH" (concat (getenv "NODE_PATH") "/Usr/Local/lib/node_modules"))
(setq exec-path (append exec-path '("/usr/local/bin")))

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

(eval-after-load "regex-tool"
  '(progn
     (setq regex-tool-backend "perl")))

;; switch windows using home row keys
(setq switch-window-shortcut-style 'qwerty)

;; automatically save buffers when finishing a wgrep session
(setq wgrep-auto-save-buffer t)

(eval-after-load 'magit
  '(progn
     (set-face-foreground 'magit-diff-add "green3")
     (set-face-foreground 'magit-diff-del "red3")
     (set-face-background 'magit-item-highlight "gray17")
     ;; quit magit smartly
     (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)
     ;; magit whitespace
     (define-key magit-status-mode-map (kbd "W") 'magit-toggle-whitespace)))

(add-hook 'w3m-display-hook 'my-w3m-rename-buffer)

(add-hook 'w3m-display-hook
          (lambda (url)
            (let ((buffer-read-only nil))
              (delete-trailing-whitespace))))

;; use the cool js2-mode from yegge and mooz
(autoload 'js2-mode "js2-mode" nil t)

;; explicitly state bookmarks
(setq bookmarks-default-file "~/.emacs.d/bookmarks")

;; jabby wabby - http://stackoverflow.com/a/5731090/1156644
(setq jabber-account-list '(("dgempesaw@sharecare.com"
                             (:connection-type . starttls))))
(setq jabber-alert-presence-hooks nil
      jabber-avatar-verbose nil
      jabber-vcard-avatars-retrieve nil
      jabber-chat-buffer-format "*-jabber-%n-*"
      jabber-history-enabled nil
      jabber-mode-line-mode t
      jabber-roster-buffqer "*-jabber-*"
      jabber-roster-line-format " %c %-25n %u %-8s (%r)"
      jabber-show-offline-contacts nil
      jabber-muc-autojoin '("qa@conference.sharecare.com")
      jabber-muc-default-nicknames '(("qa@conference.sharecare.com" . "Daniel Gempesaw")))
(setq starttls-extra-arguments '("--insecure"))
(setq starttls-use-gnutls t)

;; tumblesocks
(setq tumblesocks-blog "eval-defun.tumblr.com")
(setq tumblesocks-post-default-state 'queue)
(if (require 'sasl nil t)
      (setq oauth-nonce-function #'sasl-unique-id)
    (setq oauth-nonce-function #'oauth-internal-make-nonce))

;; Make dired less verbose
(eval-after-load "dired-details"
  '(progn
     (setq-default dired-details-hidden-string "--- ")
     (dired-details-install)))

;; Auto refresh buffers
(global-auto-revert-mode 1)

;; Also auto refresh dired, but be quiet about it
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)

;; elisp slime nav mode
;; (autoload 'elisp-slime-nav-mode "elisp-slime-nav")
;; (add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t)))

(setq ssh-config-path "~/.ssh/config")

(setq ace-jump-mode-scope 'frame)

(setq circe-network-options
      `(("Freenode"
         :nick "dgempesaw"
         :channels ("#emacs" "#selenium")
         :nickserv-password ,freenode-password
         )))

(put 'narrow-to-region 'disabled nil)

(setq markdown-css-path "/opt/highlight.js/src/styles/ir_black.css")
(setq markdown-script-path "/opt/highlight.js/build/highlight.pack.js")

(setq mu4e-get-mail-command "true"
      mu4e-update-interval 180
      mu4e-view-prefer-html nil
      mu4e-headers-results-limit 100
      mu4e-use-fancy-chars nil
      mu4e-view-show-images t
      mu4e-html2text-command "html2text -utf8 -nobs -style pretty | sed 's/&quot;/\"/g'"
      mu4e-bookmarks '(("'maildir:/INBOX.JIRA' and date:today" "Today's JIRA" ?1)
                       ("'maildir:/INBOX.JIRA' and flag:unread" "Unread JIRA" ?j)
                       ("'maildir:/INBOX.JIRA'" "All JIRA" ?h)
                       ("'QA Build Request' AND date:today..now AND NOT from:dgempesaw@sharecare.com" "QA Builds" ?q)
                       ("flag:unread AND NOT flag:trashed AND NOT subject:JIRA" "Unread messages" ?u)
                       ("date:today..now AND NOT subject:JIRA AND NOT subject:confluence" "Today's messages" ?r)
                       ("subject:mentioned you (JIRA) OR assigned*Daniel Gempesaw" "Tagged in JIRA" ?J)
                       ("maildir:/INBOX AND date:today..now" "Inbox" ?i)
                       ("maildir:/INBOX" "All Inbox" ?I)
;; mu find SC2 QA Build Request from:vsatam@sharecare.com unread
                       ("from:dgempesaw@sharecare.com" "Sent" ?t)
                       ("date:7d..now" "Last 7 days" ?l)))

(setq user-mail-address "dgempesaw@sharecare.com"
      user-full-name  "Daniel Gempesaw"
      message-signature (concat
"Daniel Gempesaw | QA Architect\n"
"M 302.754.1231\n"
"\n"
"Sharecare, Inc.\n"
"Sharecare.com | DoctorOz.com | DailyStrength.org | the little blue book\n"
))

;; with Emacs 23.1, you have to set this explicitly (in MS Windows)
;; otherwise it tries to send through OS associated mail client
(setq message-send-mail-function 'message-send-mail-with-sendmail
      message-send-mail-function 'smtpmail-send-it
      smtpmail-stream-type 'starttls
      smtpmail-default-smtp-server "pod51019.outlook.com"
      smtpmail-smtp-server "pod51019.outlook.com"
      smtpmail-smtp-user "dgempesaw@sharecare.com"
      smtpmail-smtp-service 587)

(setq split-height-threshold nil
      split-width-threshold nil)


;; Use cperl-mode instead of the default perl-mode
(defalias 'perl-mode 'cperl-mode)
(setq cperl-invalid-face (quote off))
(setq cperl-electric-keywords t)
(setq cperl-indent-level 4)
(setq cperl-continued-statement-offset 0)
(setq cperl-extra-newline-before-brace t)
(setq cperl-indent-parens-as-block t)


;; personal snippets
(setq yas/snippet-dirs
      '("~/.emacs.d/snippets"                      ;; personal snippets
        "~/.emacs.d/el-get/yasnippet/snippets/"    ;; the default collection
        ))

(eval-after-load "paredit"
  '(progn
     (put 'paredit-forward-delete 'delete-selection 'supersede)
     (put 'paredit-backward-delete 'delete-selection 'supersede)
     (put 'paredit-open-round 'delete-selection t)
     (put 'paredit-open-square 'delete-selection t)
     (put 'paredit-doublequote 'delete-selection t)
     (put 'paredit-newline 'delete-selection t)
     ))

(delete '("\\.js\\'" . javascript-generic-mode) auto-mode-alist)
(delete '("\\.js\\'" . js-mode) auto-mode-alist)
(delete '("\\.t$'" . cperl-mode) auto-mode-alist)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.t$" . cperl-mode))
(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
(setq auto-mode-alist (cons '("\\.tag$" . html-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.out$" . auto-revert-tail-mode) auto-mode-alist))

;; dired - reuse current buffer by pressing 'a'
(put 'dired-find-alternate-file 'disabled nil)

;; term face settings
(setq term-default-bg-color nil)

;; alert settings
(setq alert-default-style 'growl)

;; offlineimappppy
(setq offlineimap-buffer-maximum-size 256
      offlineimap-command "offlineimap -u machineui"
      offlineimap-enable-mode-line-p (member major-mode
                                             '(offlineimap-mode
                                               gnus-group-mode
                                               mu4e-headers-mode
                                               mu4e-view-mode
                                               )))
