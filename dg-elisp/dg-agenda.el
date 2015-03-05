(require 'calfw-org)
(require 'org-agenda)

(defun dg-open-agenda ()
  (interactive)
  (org-agenda-redo t)
  (delete-other-windows)
  (split-window-horizontally)
  (cfw:open-org-calendar)
  (org-agenda-list))

(global-set-key (kbd "s-a")
                (lambda ()
                  (interactive)
                  (toggle-app-and-home "cfw-calendar" 'dg-open-agenda)))

(provide 'dg-agenda)
