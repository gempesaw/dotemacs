(use-package org-jira
  :ensure t
  :config 

  (make-directory "~/.org-jira" t)
  (setq jiralib-url "https://pagerduty.atlassian.net"))
