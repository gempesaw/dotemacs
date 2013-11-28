(defun offlineimap-rudely-restart ()
  (interactive)
  (offlineimap-quit)
  (shell-command "pkill -u dgempesaw -s 9 -f offlineimap")
  (kill-buffer "*OfflineIMAP*")
  (sit-for 1)
  (offlineimap))

;; offlineimappppy
(setq offlineimap-buffer-maximum-size 256
      offlineimap-command "offlineimap -u machineui"
      offlineimap-enable-mode-line-p (member major-mode
                                             '(offlineimap-mode
                                               gnus-group-mode
                                               mu4e-headers-mode
                                               mu4e-view-mode)))

(global-unset-key (kbd "s-o"))
(global-set-key (kbd "s-o") '(lambda () (interactive)
                               (if (switch-between-buffers "*OfflineIMAP*")
                                   (if (get-buffer-process (current-buffer))
                                       (progn
                                         (goto-char (point-max))
                                         (offlineimap-resync))
                                     (offlineimap)))))
(global-set-key (kbd "s-0") 'offlineimap-rudely-restart)

(provide 'dg-offlineimap)
