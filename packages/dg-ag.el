(use-package ag
  :ensure t
  :config
  (setq ag-arguments '("--smart-case" "--column" "--stats" "--hidden" "--width" "1000")
        ag-reuse-buffers t
        ag-reuse-window t
        ag-highlight-search t))
