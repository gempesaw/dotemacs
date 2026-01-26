(use-package ag
  :ensure t
  :config
  (setq ag-arguments '("--smart-case" "--column" "--stats" "--ignore-dir" ".git" "--hidden" "--width" "1000")
        ag-reuse-buffers t
        ag-reuse-window t
        ag-highlight-search t
        ag-ignore-list '(".terraform" ".agent-shell"))

  (set-face-attribute 'ag-match-face nil
                      :weight 'ultra-bold
                      :background "#9d62fd"
                      :inherit nil))
