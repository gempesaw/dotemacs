(require 'go-eldoc)
(require 'go-mode)

;; go get -u golang.org/x/tools/cmd/... github.com/rogpeppe/godef github.com/nsf/gocode

(add-hook 'go-mode-hook 'go-eldoc-setup)
(add-hook 'go-mode-hook (lambda ()
                          (add-hook 'before-save-hook 'gofmt-before-save)
                          (local-set-key (kbd "M-.") 'godef-jump)
                          (local-set-key (kbd "M-,") 'pop-tag-mark)))

(provide 'dg-go)
