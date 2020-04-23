(eval-after-load 'git-link
  '(progn
     (setq git-link-open-in-browser t)
     (global-set-key (kbd "C-c l") 'git-link)))

(provide 'dg-git-link)
