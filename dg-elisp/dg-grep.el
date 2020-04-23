(grep-apply-setting 'grep-find-command (cons "find . -type f \\! -name \"ido.last*\" \\! -path \"*git*\" \\! -path \"*elpa*\" \\! -path \"*backups*\" \\! -path \"*bower_components*\" -exec grep -nH -E \"\" {} +" 142))

(setq grep-find-ignored-directories '("app/bower_components"
                                      "node_modules"
                                      "target"
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
