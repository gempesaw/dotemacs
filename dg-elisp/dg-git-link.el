(eval-after-load 'git-link
  '(progn
     (setq git-link-open-in-browser t)
     (global-set-key (kbd "C-c l") 'git-link)
     (global-set-key (kbd "C-c C-l") 'git-link-homepage)))

(provide 'dg-git-link)
