(require 'calendar)

(calendar-set-date-style 'iso)
(global-set-key (kbd "C-s-d") (lambda () (interactive)
                                (toggle-app-and-home
                                 "Calendar"
                                 (lambda ()
                                   (window-configuration-to-register 6245)
                                   (calendar)
                                   (delete-other-windows)
                                   (text-scale-adjust 3)
                                   (execute-kbd-macro [?m ?. ?i ?d])
                                   (text-scale-adjust 0)
                                   (text-scale-adjust 2)
                                   (recenter-top-bottom)))))

(provide 'dg-diary)