(use-package agent-recall
  :ensure t
  :hook (agent-shell-mode . agent-recall-track-sessions)
  :config
  (setq agent-recall-search-paths '("~/opt/")
        agent-recall-search-function 'ag
        agent-recall-browse-sort 'modified-desc))
