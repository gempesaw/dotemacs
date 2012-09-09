(add-to-list 'load-path "~/.emacs.d/")
(load "customize.el")

;; load the child files
(load "alias.el")
(load "defun.el")
(load "kbd.el")
(load "modes.el")
(load "tabs.el")
(load "themes.el")
(setq custom-file "emacs-custom.el")
(load custom-file 'noerror)

;; TODO: refactor into a function?
;; start up selenium if possible.
(if (eq nil (get-buffer "selenium"))
    (when (file-exists-p "/opt/selenium-server-standalone-2.25.0.jar")
      (shell-command "java -jar /opt/selenium-server-standalone-2.25.0.jar -Dwebdriver.chrome.driver=/opt/chromedriver &")
      (set-buffer "*Async Shell Command*")
      (rename-buffer "selenium")
      (toggle-read-only)))
