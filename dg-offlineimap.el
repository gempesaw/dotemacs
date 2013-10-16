(defun offlineimap-rudely-restart ()
  (interactive)
  (shell-command "pkill -u dgempesaw -s 9 -f offlineimap")
  (kill-buffer "*OfflineIMAP*")
  (offlineimap-quit)
  (sit-for 0)
  (offlineimap))

;; offlineimappppy
(setq offlineimap-buffer-maximum-size 256
      offlineimap-command "offlineimap -u machineui"
      offlineimap-enable-mode-line-p (member major-mode
                                             '(offlineimap-mode
                                               gnus-group-mode
                                               mu4e-headers-mode
                                               mu4e-view-mode)))

(provide 'dg-offlineimap)
