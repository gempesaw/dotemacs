(defun offlineimap-rudely-restart ()
  (interactive)
  (shell-command "pkill -u dgempesaw -s 9 -f offlineimap")
  (kill-buffer "*OfflineIMAP*")
  (offlineimap-quit)
  (sit-for 0)
  (offlineimap))

(provide 'dg-offlineimap)
