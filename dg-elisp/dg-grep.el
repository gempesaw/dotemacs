(grep-apply-setting 'grep-find-command (cons "find . -type f \\! -name \"ido.last*\" \\! -path \"*git*\" \\! -path \"*elpa*\" \\! -path \"*backups*\" -exec grep -nH -e  {} +" 111))

(provide 'dg-grep)
