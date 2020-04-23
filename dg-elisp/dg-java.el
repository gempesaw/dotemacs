(require 'lsp-java)
(add-hook 'java-mode-hook #'lsp)
(setenv "JAVA_HOME" "/Users/dgempesaw/.asdf/installs/java/azul-zulu-8.0.212")

;; (require 'lsp-kotlin)
;; (add-hook 'kotlin-mode-hook #'lsp-kotlin-enable)

(provide 'dg-java)
