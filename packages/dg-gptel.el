(use-package gptel
  :config

  ;; (gptel-make-gemini "Gemini"
  ;;   :stream t
  ;;   :key 'gptel-api-key-from-auth-source)
  (gptel-make-anthropic "Claude"
    :stream t
    :key 'gptel-api-key-from-auth-source)
  )
