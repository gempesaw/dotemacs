(defun offlineimap-rudely-restart ()
  (interactive)
  (shell-command "pkill -u dgempesaw -s 9 -f offlineimap")
  (offlineimap-quit)
  (offlineimap))

(provide 'dg-offlineimap)
