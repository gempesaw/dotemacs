(grep-apply-setting 'grep-find-command (cons "find . \\! -path \"*git*\" \\! -path \"*elpa*\" \\! -path \"*backups*\" -exec grep -nH -e  {} +" 82))

(provide 'dg-grep)
