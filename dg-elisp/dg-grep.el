(grep-apply-setting 'grep-find-command (cons "find . -type f \\! -name \"ido.last*\" \\! -path \"*git*\" \\! -path \"*elpa*\" \\! -path \"*backups*\" -exec grep -nH -e  {} +" 111))

(setq grep-find-ignored-directories '("app/bower_components"
                                      "node_modules"
                                      "SCCS"
                                      "RCS"
                                      "CVS"
                                      "MCVS"
                                      ".svn"
                                      ".git"
                                      ".hg"
                                      ".bzr"
                                      "_MTN"
                                      "_darcs"
                                      "{arch}"))


(provide 'dg-grep)
