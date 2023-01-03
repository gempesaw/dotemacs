(setq markdown-css-paths '("/opt/highlight.js/src/styles/ir_black.css"))
(setq markdown-script-path "/opt/highlight.js/build/highlight.pack.js")

(add-hook 'markdown-mode-hook 'turn-on-auto-fill)

(provide 'dg-markdown-mode)
