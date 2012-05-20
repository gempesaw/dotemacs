(setq el-get-sources
      '((:name bbdb
               :type git
               :url "git://github.com/barak/BBDB.git"
               :load-path ("./lisp" "./bits")
               :info "texinfo"
               :build ("./configure" "make"))

        (:name magit
               :type git
               :url "http://github.com/philjackson/magit.git"
               :info "."
               :build ("./autogen.sh" "./configure" "make"))

      (:name vkill
             :type http
             :url "http://www.splode.com/~friedman/software/emacs-lisp/src/vkill.el"
             :features vkill)

      (:name yasnippet
             :type git-svn
             :url "http://yasnippet.googlecode.com/svn/trunk/"))

(setq el-get-recipe-path-emacswiki t)
(el-get-emacswiki-refresh)
