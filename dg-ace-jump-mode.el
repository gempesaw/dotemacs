(setq ace-jump-mode-scope 'frame)
(define-key my-keys-minor-mode-map (kbd "C-.") 'ace-jump-mode)

(eval-after-load "tracking"
  '(progn
     (define-key tracking-mode-map (kbd "C-.") 'ace-jump-mode)))

(provide 'dg-ace-jump-mode)
