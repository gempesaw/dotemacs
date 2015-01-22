(require 'perlbrew)
(perlbrew-switch "perl-5.14.4")

;;; manually set the PERL5LIB. This will mess things up; sure hope you
;;; remember that you did this.
(let* ((version "5.14.4")
       (prefix (format "/Users/dgempesaw/perl5/perlbrew/perls/perl-%s/lib/" version))
       (dirs `(,(format "site_perl/%s" version)
               ,(format "site_perl/%s/darwin-2level/" version)
               ,version
               ,(format "%s/darwin-2level" version)))
       (perl5lib (mapconcat (lambda (dir) (format "%s%s" prefix dir)) dirs ":")))
  (setenv "PERL5LIB" perl5lib))

(provide 'dg-perlbrew)
