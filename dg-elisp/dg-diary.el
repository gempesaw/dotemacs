(require 'calendar)

(calendar-set-date-style 'iso)

(defun toggle-diary-windows ()
  (interactive)
  (toggle-app-and-home
   "Calendar"
   (lambda ()
     (window-configuration-to-register 6245)
     (calendar)
     (delete-other-windows)
     (text-scale-adjust 3)
     (execute-kbd-macro [?m ?. ?i ?d])
     (delete-duplicate-dates)
     (text-scale-adjust 0)
     (text-scale-adjust 2)
     (recenter-top-bottom))))

(defun delete-duplicate-dates ()
  (let ((date (s-trim
               (substring-no-properties
                (thing-at-point 'line)))))
    (while (and (string-match "[[:digit:]][[:digit:]][[:space:]]$"
                              (substring-no-properties (thing-at-point 'line)))
                (save-excursion  (search-backward date)
                                 (search-backward date)))
      (delete-region (line-beginning-position) (line-end-position))
      (forward-line -1)
      (end-of-line)
      (insert " "))))

(global-set-key (kbd "C-s-d") 'toggle-diary-windows)

(defun remind-me-daily (fn time)
  (when (and (boundp 'daily-reminder)
             (timerp daily-reminder))
    (cancel-timer daily-reminder))
  (let ((daily (* 60 60 24)))
    (setq daily-reminder
          (run-at-time time daily 'funcall fn))))

(remind-me-daily 'toggle-diary-windows "4:30pm")

(provide 'dg-diary)
