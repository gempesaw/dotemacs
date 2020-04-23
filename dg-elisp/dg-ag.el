;;; echo '/.git/' >> ~/.agignore
(setq ag-arguments '("--smart-case" "--column" "--stats" "--hidden")
      ag-reuse-buffers t)

(provide 'dg-ag)
