(defvar dg-transient-atlantis--project nil)
(defvar dg-transient-atlantis--target nil)

(defun dg-transient-atlantis--get-atlantis-projects ()
  (let ((atlantis-yaml (format "%s%s" (locate-dominating-file default-directory "atlantis.yaml") "atlantis.yaml")))
    (with-temp-buffer
      (insert-file-contents atlantis-yaml)
      (--> (buffer-string)
           (s-split "\n" it)
           (--filter (s-match "^ *- name:" it) it)
           (--map (s-split ": " it) it)
           (--map (cadr it) it)))))

(defun dg-transient-atlantis-enumerate-resources ()
  (--> "ag --nofilename --file-search-regex %s '(resource|module) \"'"
       (format it dg-transient-atlantis--project)
       (shell-command-to-string it)
       (s-split "\n" it)
       (--filter (not (s-equals-p "" it)) it)
       (--map (s-replace "resource\." "" (s-replace " " "." (s-replace "\"" "" (s-chop-suffix " {" it)))) it)))

(defun dg-transient-atlantis-read-target (prompt initial-input history)
  (let ((target (completing-read prompt (dg-transient-atlantis-enumerate-resources) nil nil initial-input history)))
    (if target
        (setq dg-transient-atlantis--target target)
      (setq dg-transient-atlantis--target ""))))

(defun dg-transient-atlantis-read-project (prompt initial-input history)
  (let ((project (completing-read prompt (dg-transient-atlantis--get-atlantis-projects) nil nil initial-input history)))
    (when project
      (setq dg-transient-atlantis--project project))))

(transient-define-argument dg-transient-atlantis-target ()
  :description "target a specific resource"
  :class 'transient-option
  :key "t"
  :argument "--target="
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-atlantis--target))
  :reader #'dg-transient-atlantis-read-target)

(transient-define-argument dg-transient-atlantis-project ()
  :description "which atlantis project to operate on"
  :class 'transient-option
  :key "p"
  :always-read t
  :argument ""
  :init-value (lambda (ob)
                (setf (slot-value ob 'value) dg-transient-atlantis--project))
  :reader #'dg-transient-atlantis-read-project)

(transient-define-prefix dg-transient-atlantis ()
  "Choose cluster and AWS profile alias"

  ["Options"
   (dg-transient-atlantis-project)
   ("d" "destroy" "--destroy")
   (dg-transient-atlantis-target)
   ]
  ["Actions"
   [("a p" "plan"
     (lambda (&optional args)
       (interactive (list (transient-args transient-current-command)))
       (let ((project (car args))
             (options (if (eq nil (cdr args))
                          ""
                        (format "-- %s" (s-join " " (cdr args))))))
         (setq dg-transient-atlantis--project project)
         (if (not (s-matches-p "--target" options))
             (setq dg-transient-atlantis--target nil))
         (insert (format "ap %s %s" project options)))))

    ("a g" "Get"
     (lambda (&optional args)
       (interactive (list (transient-args transient-current-command)))
       (let ((project (car args)))
         (setq dg-transient-atlantis--project project)
         (insert (format "aget %s" project)))))

    ("a a" "apply"
     (lambda (&optional args)
       (interactive (list (transient-args transient-current-command)))
       (let ((project (car args))
             (options (if (eq nil (cdr args))
                          ""
                        (format "-- %s" (s-join " " (cdr args))))))
         (setq dg-transient-atlantis--project project)
         (insert (format "aa %s %s" project options)))))]])

(key-chord-define-global "zp" 'dg-transient-atlantis)

(provide 'dg-transient-atlantis)
