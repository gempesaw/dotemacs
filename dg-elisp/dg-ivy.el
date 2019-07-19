(require 'ivy)

(ivy-mode 1)
(setq ivy-use-virtual-buffers t
      ivy-count-format "(%d/%d) "
      enable-recursive-minibuffers t
      ivy-virtual-abbreviate 'full
      ivy-re-builders-alist '((t . ivy--regex-fuzzy)))

;; (global-set-key (kbd "C-c C-r") 'ivy-resume)
;; (global-set-key (kbd "<f6>") 'ivy-resume)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
;; (global-set-key (kbd "<f1> f") 'counsel-describe-function)
;; (global-set-key (kbd "<f1> v") 'counsel-describe-variable)
;; (global-set-key (kbd "<f1> l") 'counsel-find-library)
;; (global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
;; (global-set-key (kbd "<f2> u") 'counsel-unicode-char)
;; (global-set-key (kbd "C-c g") 'counsel-git)
;; (global-set-key (kbd "C-c j") 'counsel-git-grep)
;; (global-set-key (kbd "C-c k") 'counsel-ag)
(global-set-key (kbd "C-x l") 'counsel-locate)
;; (global-set-key (kbd "C-S-o") 'counsel-rhythmbox)

(define-key minibuffer-local-map (kbd "C-r") 'counsel-minibuffer-history)
(define-key minibuffer-local-map (kbd "C-s") 'next-line-or-history-element)

(provide 'dg-ivy)
