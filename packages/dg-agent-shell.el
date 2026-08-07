;;; dg-agent-shell.el --- Agent shell base configuration -*- lexical-binding: t; -*-

;; Configures the upstream `agent-shell' package: MCP servers, model
;; and session defaults, the auth-source helper used by the Linear
;; MCP entry, and a small corfu adjustment for agent-shell buffers.
;;
;; Everything dashboard-related — the magit-style row UI, summary
;; tracking, the personal transient, key-chord bindings,
;; execute-with-context commands — lives in
;; `dg-agent-shell-dashboard'.

(use-package shell-maker
  :ensure t
  :demand t)

(defun dg/auth-source-get-password (host)
  "Get password for HOST from auth-source (e.g., ~/.authinfo.gpg).
Returns empty string if not found."
  (require 'auth-source)
  (if-let* ((auth-info (auth-source-search :host host :max 1))
            (secret (plist-get (car auth-info) :secret)))
      (if (functionp secret)
          (funcall secret)
        secret)
    ""))

(use-package agent-shell
  :demand t
  :ensure t
  :custom
  (agent-shell-highlight-blocks t)
  (agent-shell-anthropic-default-model-id "claude-opus-5")
  (agent-shell-anthropic-default-session-mode-id "bypassPermissions")
  :config
  (setq agent-shell-prefer-viewport-interaction nil
        agent-shell-session-strategy 'new
        agent-shell-header-style nil
        agent-shell-show-welcome-message nil)
  (setq agent-shell-mcp-servers
        `(((name . "linear")
           (type . "http")
           (url . "https://mcp.linear.app/mcp")
           (headers . (((name . "Authorization")
                        (value . ,(concat "Bearer "
                                          (dg/auth-source-get-password
                                           "linear.app")))))))
          ;; ((name . "notion")
          ;;  (type . "http")
          ;;  (headers . [])
          ;;  (url . "https://mcp.notion.com/mcp"))
          )))

;; corfu's auto-popup is noisy while composing prompts to the agent — too
;; many false-positive completions on prose.  Disable auto-popup here;
;; corfu still works manually via M-TAB.  We also yank the
;; post-command-hook in case global-corfu-mode's corfu-mode activated
;; before this hook ran (its auto-trigger is installed at corfu-mode
;; startup, not read live).
(add-hook 'agent-shell-mode-hook
          (lambda ()
            (setq-local corfu-auto nil)
            (remove-hook 'post-command-hook #'corfu--auto-post-command t)))

(provide 'dg-agent-shell)
;;; dg-agent-shell.el ends here
