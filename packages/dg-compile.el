(use-package compile
  :ensure t
  :config
  ;; don't ask about files
  (setq compilation-ask-about-save nil
        compilation-scroll-output t
        compilation-last-buffer nil)
  )
