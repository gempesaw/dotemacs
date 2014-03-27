(defun offlineimap-kill ()
  (interactive)
  (shell-command "kill -9 $(ps aux | awk '/[o]fflineimap/ {print $2}');ps aux | grep [o]ffline"))

(defun offlineimap-show-or-start ()
  (interactive)
  (if (switch-between-buffers "*OfflineIMAP*")
      (if (get-buffer-process (current-buffer))
          (goto-char (point-max))
        (offlineimap))))

;; offlineimappppy
(setq offlineimap-buffer-maximum-size 256
      offlineimap-command "offlineimap -u machineui"
      offlineimap-enable-mode-line-p (member major-mode
                                             '(offlineimap-mode
                                               gnus-group-mode
                                               mu4e-headers-mode
                                               mu4e-view-mode)))


(global-unset-key (kbd "s-o"))
(global-set-key (kbd "s-o") 'offlineimap-show-or-start)
(global-set-key (kbd "s-0") 'offlineimap-kill)

(provide 'dg-offlineimap)
