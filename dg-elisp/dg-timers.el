(setq offline-reset-timer
      (run-with-timer 0 (* 60 60)
                      (lambda ()
                        (offlineimap-kill)
                        (sit-for 5)
                        (offlineimap))))

(provide 'dg-timers)
