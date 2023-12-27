;; (define-transient-command dg-help-transient ()
;;   "Help commands that I use. A subset of C-h with others thrown in."
;;   ["Help Commands"
;;    ["Mode & Bindings"
;;     ("m" "Mode" describe-mode)
;;     ("b" "Major Bindings" which-key-show-full-major-mode)
;;     ("B" "Minor Bindings" which-key-show-full-minor-mode-keymap)
;;     ("t" "Top Bindings  " which-key-show-top-level)
;;     ]
;;    ["Info on"
;;     ("C-c" "Emacs Command" Info-goto-emacs-command-node)
;;     ("C-k" "Emacs Key" Info-goto-emacs-key-command-node)
;;     ]
;;    ["Goto Source"
;;     ("L" "Library" find-library-other-frame)
;;     ("F" "Function" find-function-other-frame)
;;     ("V" "Variable" find-variable-other-frame)
;;     ("K" "Key" find-function-on-key-other-frame)
;;     ]
;;    ]
;;   [
;;    ["Internals"
;;     ("I" "Input Method" describe-input-method)
;;     ("G" "Language Env" describe-language-environment)
;;     ("S" "Syntax" describe-syntax)
;;     ("O" "Coding System" describe-coding-system)
;;     ("C-o" "Coding Brief" describe-current-coding-system-briefly)
;;     ("T" "Display Table" describe-current-display-table)
;;     ("e" "Echo Messages" view-echo-area-messages)
;;     ("l" "Lossage" view-lossage)
;;     ]
;;    ["Describe"
;;     ("w" "Where Is" where-is)
;;     ("=" "Position" what-cursor-position)
;;     ]
;;    ]
;;   )

;(require 'transient-posframe)
;(transient-posframe-mode -1)
;(setq transient-posframe-poshandler 'posframe-poshandler-frame-top-center
;      transient-posframe-min-width 120
;      transient-posframe-border-width 1)

(progn


  ;; (transient-define-prefix transient-jira ()
  ;;   "interactive jira CLI"
  ;;   [("b" "board" "Board manages Jira boards in a project" transient--jira-board)
  ;;    ("e" "epic" "Epic manage epics in a project" transient--jira-epic)
  ;;    ("i" "issue" "Issue manage issues in a project" transient--jira-issue)
  ;;    ("o" "open" "Open issue in a browser" transient--jira-open)
  ;;    ("p" "project" "Project manages Jira projects" transient--jira-project)
  ;;    ("s" "sprint" "Sprint manage sprints in a project board" transient--jira-sprint)]
  ;;   )

  ;; (transient-define-prefix transient--jira-issue ()
  ;;   "manage issues in a given project"
  ;;   [("a" "assign" "Assign issue to a user" transient--jira-issue-assign)
  ;;    ("c" "clone" "Clone duplicates an issue" transient--jira-issue-clone)
  ;;    ("c" "comment" "Manage issue comments" transient--jira-issue-comment)
  ;;    ("c" "create" "Create an issue in a project" transient--jira-issue-create)
  ;;    ("d" "delete" "Delete an issue" transient--jira-issue-delete)
  ;;    ("e" "edit" "Edit an issue in a project" transient--jira-issue-edit)
  ;;    ("l" "link" "Link connects two issues" transient--jira-issue-link)
  ;;    ("l" "list" "List lists issues in a project" transient--jira-issue-list)
  ;;    ("m" "move" "Transition an issue to a given state" transient--jira-issue-move)
  ;;    ("u" "unlink" "Unlink disconnects two issues from each other" transient--jira-issue-unlink)
  ;;    ("v" "view" "View displays contents of an issue" transient--jira-issue-view)])

  (transient-define-prefix transient--jira-issue-create ()
    "create an issue in a given project with minimal information"
    ["Flags"
     (jira--set-type)
     (jira--set-parent)
     (jira--set-project)
     (jira--set-summary)
     (jira--set-assignee)]

    ["Action"
     ("c" "Create" jira-issue-create)]
    )
  )

(defun jira-issue-create (&optional _args)
  (interactive (list (transient-args 'transient--jira-issue-create)))
  (let* ((base-command "jira issue create")
         (type (format "--type %s" jira-type))
         (parent (format "--parent %s" jira-parent))
         (project (format "--project %s" jira-project))
         (summary (format "--summary '%s'" jira-summary))
         (assignee (if jira-assignee "--assignee 'dgempesaw@pagerduty.com'" ""))
         (custom "--custom 'type-of-work=Planned - Engineering Roadmap'")
         (input "--no-input")
         (command-string (format "%s %s %s %s %s %s %s" base-command type parent summary assignee custom input project))
         (response nil)
         (ticket nil))
    (setq cs command-string)
    (setq response (jira-confirm-shell-command-to-string command-string))
    (setq ticket (s-trim-right (cadr (s-split "/browse/" response))))
    (when jira-assignee
      (shell-command-to-string (format "jira issue move %s 'In Progress'" ticket))
      (message (format "issue %s created and assigned to you" ticket)))
    (message (format "issue %s created in backlog" ticket))
    (kill-new ticket)))

(defun jira-confirm-shell-command-to-string (command)
  (interactive)
  (let ((confirm (y-or-n-p (format "Are you sure you want to run this command?\n\n%s" command))))
    (when confirm
      (shell-command-to-string command))))


(defmacro jira--define-infix (key name description type default
                                  &rest reader)
  "Define infix with KEY, NAME, DESCRIPTION, TYPE, DEFAULT and READER as arguments."
  `(progn
     (defcustom ,(intern (concat "jira-" name)) ,default
       ,description
       :type ,type
       :group 'jira)
     (transient-define-infix ,(intern (concat "jira--set-" name)) ()
       "Set `jira--theme' from a popup buffer."
       :class 'transient-lisp-variable
       :variable ',(intern (concat "jira-" name))
       :key ,key
       :description ,description
       :argument ,(concat "--" name)
       :reader (lambda (&rest _) ,@reader))))

(jira--define-infix "t" "type" "Issue type" 'string
                    "Story"
                    (completing-read "Issue type: " '("Task" "Sub-task" "Story" "Bug") nil t))

(setq jira-parent-issues (s-split "\n" (shell-command-to-string "jira epic list --table --plain --no-headers --columns key,summary")))
;; (--map (insert (format "\"%s\"\n" it)) jira-parent-issues)
;; (setq jira-parent-issues '("SRP-588  backstage migration docs refresh"
;;                            "SRP-537  Kubernetes tickets that don't belong to a specific project. This epic is separate from Misc Work so tickets here can be capitalized/jellyfished."
;;                            "SRP-508  External-secrets is dead. Long live external-secrets. https://pagerduty.atlassian.net/wiki/spaces/SREP/pages/2846654673/External+Secrets+Operator+1-Pager"
;;                            "SRP-507  cluster-sentinel analog for k8s"
;;                            "SRP-506  One off tickets of varying priority that do not belong to any specific project or initiative. The difference between this epic and "Server Room on Fire" is that this work is planned."
;;                            "SRP-477  EKS 1.23 upgrade"
;;                            "SRP-476  Improvements to the way we sync services with Consul"
;;                            "SRP-457  Golden path for new workloads"
;;                            "SRP-456  doc, tooling, helm chart improvements for service owners"
;;                            "SRP-455  k"
;;                            "SRP-454  Creation of DR clusters"
;;                            "SRP-443  Server Room on Fire"
;;                            "SRP-394  eks 1.22 upgrade"
;;                            "SRP-356  M6.1: Infrastructure Refinement"
;;                            "SRP-301  Security sprint 2"
;;                            "SRP-275  M5.5 Production Push"
;;                            "SRP-259  Service Owner Migration: Sustainability Team (Alpha)"
;;                            "SRP-208  Security sprint 1"
;;                            "SRP-76   M6: Cleanup and Polish"
;;                            "SRP-62   M1: Discovery"
;;                            "SRP-61   M7: Testing and Validation"
;;                            "SRP-10   M8: Migration"
;;                            "SRP-9    M3: Networking"
;;                            "SRP-8    M5: Productionization"
;;                            "SRP-7    M4: Service Prototype"
;;                            "SRP-4    M2: Infrastructure Automation"
;;                            ))

(jira--define-infix "p" "parent" "Parent issue key can be used to attach epic to an issue." 'string
                    nil
                    (car (s-split "\s" (completing-read "Parent: " jira-parent-issues nil t))))

;; (setq jira-project-list (cdr (s-split "\n" (shell-command-to-string "jira project list | cat"))))
(jira--define-infix "r" "project" "project in which to create the issue" 'string
                    "SRP"
                    (car (s-split "\s\s+" (completing-read "Project: " jira-project-list nil t))))

(jira--define-infix "s" "summary" "Issue summary or title" 'string
                    ""
                    (read-string "Title of JIRA issue to create: "))

(jira--define-infix "s" "summary" "Issue summary or title" 'string
                    ""
                    (read-string "Title of JIRA issue to create: "))

(jira--define-infix "a" "assignee" "assignee to me" 'boolean
                    t
                    (not jira-assignee))

(defmacro jira--define-infix (key name description type default
                                  &rest reader)
  "Define infix with KEY, NAME, DESCRIPTION, TYPE, DEFAULT and READER as arguments."
  `(progn
     (defcustom ,(intern (concat "jira-" name)) ,default
       ,description
       :type ,type
       :group 'jira)
     (transient-define-infix ,(intern (concat "jira--set-" name)) ()
       "Set `jira--theme' from a popup buffer."
       :class 'transient-lisp-variable
       :variable ',(intern (concat "jira-" name))
       :key ,key
       :description ,description
       :argument ,(concat "--" name)
       :reader (lambda (&rest _) ,@reader))))

(progn
  (require 'dash)



  (defun create-transient-prefix-vectors-from-shell-command (shell-command command-start-delimiter command-end-delimiter)
    (interactive)
    (->> (shell-command-to-string shell-command)
         (s-split "\n")
         (--drop-while (not (s-contains? command-start-delimiter it)))
         (cdr)
         (--take-while (not (s-equals? command-end-delimiter it)))
         (--map (s-trim it))
         (--map (s-split "\s\s+" it))
         (--map (let* ((command (car it))
                       (key (s-left 1 command))
                       (description (cadr it))
                       (shell-command-as-fn (s-replace-regexp "\\W+" "-" shell-command)))
                  (format "(\"%s\" \"%s\" \"%s\" %s)"
                          key command description (format "transient--%s-%s" shell-command-as-fn command))
                  ))))

  (defun insert-transient-prefixes (command)
    (interactive "scommand to parse: ")
    (insert (s-join "\n" (create-transient-vectors-from-shell-command command "MAIN COMMANDS" "")))))




(provide 'dg-transient)

(setq jira-project-list '("CHAN     ChangeDuty                      classic     Oriana Lemme" "EDLR     EMEA DE Lead Routing                    next-gen    Vince Ko" "SIMTT        Simulation: Tool Team                   classic     GJ Van Der Werken" "MOON        Moonshot                        classic     Sean Steacy" "SOC2      SOC2                            classic     Simon Darken" "LP       Learncore PO                        next-gen    Loni Harris" "LEAR      learncore PO                        next-gen    Loni Harris" "IAPCT     Incident Alert Pipeline Cross Team          classic     Sean Steacy" "PEN       Pendo Content Review                    classic     Aaron Levisohn" "MOF        Big Bucks, No Whammies                  classic     Lisa Thompson" "PDT     pdt-shiggins                        next-gen    Sean Higgins" "EPP      ES Partner Portal                   next-gen    Vasavi Bollaram" "DIIT      Digital Insights - Internal Tasks           next-gen    Vasavi Bollaram" "DECO      Developer Ecosystem                 classic     Brett Willemsen" "EMM       EM Mothership                       classic     Sean Steacy" "OMS       OMS                         next-gen    Vasavi Bollaram" "DKP       Dataduty-NextGen Business Analytics Data Platform   next-gen    Manuraj Rajasekharan" "LMNDW        Looker Migration to New DataWarehouse1          next-gen    Manuraj Rajasekharan" "ENGREQ       Eng Requests                        classic     Boryana Kalinova" "TT       Tiffany-TEST                        next-gen    Tiffany Chang" "MOCO        Mobile Core                     classic     Jacob Han" "TS      Test Sri                        classic     Srilatha Samala" "MAURY     Community                       classic     Rachel English" "PDU        PDUniversity                        classic     Roma Shah" "RT      Realtime TEST                       classic     Roman Shekhtmeyster" "SRI       Testingproject                      classic     Srilatha Samala" "BA        Bon-Ami                         next-gen    Reg Braithwaite-Lee" "PROV      Provisioning Framework                  next-gen    Vasavi Bollaram" "ATP       Ajit's Test Project                 next-gen    Ajit Dipak" "VIS        Visibility                      classic     Ryan Bateman" "MW       z-ARCHIVED-Marketing Website                classic     Mark Smith" "IMS        Incident Management - Systems               classic     Derek Ralston" "MOCP        MOCO - Shipping                     next-gen    Sarah Chandler" "LMTNDW     Looker Migration to New DataWarehouse           classic     Carl Ghoreichi" "BC     be-cause                        next-gen    Reg Braithwaite-Lee" "EST       ES Tools                        classic     Vasavi Bollaram" "OH        Operations Health - old                 classic     Vasavi Bollaram" "EF        Enterprise Foundations                  classic     Chelsea Vandermeer" "FEAT       Feature Requests                    classic     Dave Shackelford" "PG       Growth Product                      classic     Oriana Lemme" "CCM      Content & Customer Marketing                classic     Lauren Wang" "TSTSR1        Testsri1                        next-gen    Srilatha Samala" "RYAN      Ryan-Demo                       classic     Ryan Hoskin" "CHN       Chandler                        classic     Sarah Chandler" "RYAN2      Ryan-Demo-2                     classic     Ryan Hoskin" "SP9       Status Page                     next-gen    Katie Reiter" "CUE      Core User Experience                    classic     Katie Reiter" "MOARC        MOCO-Archive-2                      next-gen    Leena Mansour" "BOA     Biz Ops Analytics                   classic     Heather Holyoake" "REC      Recruiting                      classic     Kimberly Palmer" "AD        Analytics Dashboard                 next-gen    Ricky Ng" "IP       Integrations Pilot                  next-gen    Wilson Phan" "OP        3rd Party Projects                  classic     Sean Steacy" "PIPE      Pipeline Mothership                 classic     Ryan Bateman" "EM       Event Management                    classic     Ophir Ronen" "EXP       Expert Services Tooling                 next-gen    Srilatha Samala" "BET       Betelgeuse                      classic     Sarah Hoffman" "OHMSDATA    OHMS Datascience                    next-gen    Vasavi Bollaram" "BRAND     Brand Design                        classic     Erica Forte" "TM        Technical Marketing                 next-gen    Vera Chan" "MLP     Machine Learning Platform               classic     Zane Magnus" "ONC       The Oncalls                     classic     Anton Van Oosbree" "SIG     Signal                          classic     Andrew Stutz" "ORCA     Event Orchestration                 classic     Frank Emery" "CHAOS     Chaos                           classic     Richard Burnison" "TA       Trade App                       next-gen    Joe Calcada" "COP       Commercial Ops Project Pipeline             classic     Rachael Byrne" "REX     Response Experience                 classic     Fernando Callender" "AI     Analytics Icebox                    classic     A.J. Vittorio" "TCUE        Test - Core User Experience             classic     Katie Reiter" "FPA      FP&A                            classic     Hien Phan" "CO      Collections                     classic     Srilatha Samala" "BI        Business Insights                   classic     Carl Ghoreichi" "TB     test busines                        classic     Srilatha Samala" "DSC       Data Science                        classic     Edward Chang" "DBRE     Database Reliability Engineering            classic     Stevenson Jean-Pierre" "MCUE        Metrics - Core User Experience              next-gen    Katie Reiter" "DST      DST                         classic     Ophir Ronen" "SBEVE     Project Sbeve                       next-gen    Spencer Edgecombe" "SRV     Services and Dependencies               classic     Jim Lindley" "CAD       Community & Advocacy                    classic     Rachel English" "CORE       Core                            classic     Bill Barksdale" "CLM2       Customer Lifecycle Marketing                classic     Minami Coirin" "GD      GSuite disabled                     next-gen    Christina Andersen" "TLD        Thought Leadership Docs                 next-gen    Julie Gunderson" "BR        BRAND REFRESH                       classic     Srilatha Samala" "STOCK     Stock Admin Ticketing System                classic     Minh Trang Cannon" "UN      Unlock                          classic     Sean Steacy" "AR        Accounts Receivable                 classic     Lauren Workman" "UR     User Research                       classic     Aaron Levisohn" "SRR        SRE Roadmap                     next-gen    Simon Darken" "APPS     App Submission Review                   classic     John Baldo" "CT     CUE Testing                     next-gen    Sarah Chandler" "SB     Sandbox                         classic     Matt Spring" "DEVI      Developer Foundations                   classic     Nakul Bhagat" "SECQ     Customer Security Inquiries             classic     Kathleen Arnold" "EXPS      Experience Story                    classic     Srilatha Samala" "ATK       Andrea Test K                       classic     Andrea Roberts" "EXPP       Experience Planning                 classic     Srilatha Samala" "SST       Sustainability Team                 classic     Jonathan Cheatham" "SDV     SRE Delivery                        classic     Dave Bresci" "SCL       SRE Cloud Infrastructure                classic     Dave Bresci" "DM        Delivery Management                 classic     Sean Steacy" "GRPCP     Group - Core Product                    classic     Roma Shah" "GRPDV       Group - Developer Experience / Integrations     classic     Roma Shah" "BS2     BS2 Split                       classic     Derek Ralston" "TST     Test                            next-gen    Roma Shah" "FEX     Front-End Platform                  classic     Margo Baxter" "EMDS     OLD DataLabs                        classic     Ophir Ronen" "EDC       EU Data Residency                   classic     Alex Patreau" "CMRES        Crisis Management - Resilience              classic     Roma Shah" "AP      Alex Project                        classic     Alex Solomon" "RPB      Resource Promotion Board                classic     Tram Nguyen" "SPAM      Stakeholder Priority Alert Messaging            classic     Brett Willemsen" "ZENQ      Support Dashboard                   classic     Elle Rykener" "DE       Data Ecosystem                      classic     Zane Magnus" "GA        Marketing Analytics                 classic     Dave Hsu" "ISLA     Isla                            classic     Chelsea Vandermeer" "COL        CollabOps                       classic     Mya King" "SE       SpringCM tickets                    classic     Vasavi Bollaram" "CSE       Customer Success Engineer               classic     Joe Calcada" "PF        Platform ARCHIVED                   classic     James Tyack" "RLO       Platform UX                     classic     Ro Lo" "EWS     Early Warning System                    classic     Srilatha Samala" "K8S       Pagerduty Migrates to Kubernetes            classic     Adam Panzer" "CCC       Customer Credit Checks.                 classic     Maxelia Vargas-Morillo" "EIDS       EI Data Science                     classic     Vijay Venkataraman" "DMT        Delivery Management Test                classic     Sean Steacy" "TEST      Urgent Issues (demo)                    classic     David Hayes" "MOCA      Mobile Core Archive                 classic     Sarah Chandler" "DM3        Delivery Management Test3               classic     Sean Steacy" "DFD       Digital Foundations Design              classic     Aaron Lee" "FBI     Field Built Integrations                classic     Mythili Gopalakrishnan" "RGP        Response Group Planning                 classic     Sarah Chandler" "DSM        Design System                       classic     Ash Ramos" "ENA     Sales CSG Enablement                    classic     Timothy Peterson" "FPAS     Sales Finance                       classic     Hien Phan" "UEX     UX                          classic     Ruta Srinivasaraju" "CS     Customer Service Ops                    classic     Ola Adewumi" "RDC       Cloud Automation Team                   classic     Sean Noble" "PROD       Product                         classic     David Hayes" "NEXT      Notifications Experience Team               classic     Girish Shankarraman" "ING       Ingestion Team                      classic     Priyam Chawla" "DEVREQ      DevTools Requests                   classic     Eric Sigler" "AF        App Foundations                     classic     Rajeev Thiruvengadam" "STK      Sean Test Kanban                    classic     Sean Steacy" "SEPT      Schedules and Escalations               classic     Arnold Cano" "BZR       Business Response                   classic     Matt Spring" "SRP       SRE-Platform                        classic     Jonathan Cheatham" "SIMDT       Simulation: Delivery Team               classic     Derek Ralston" "SIMICT      Simulation: Ice Cream Team              classic     GJ Van Der Werken" "BAED        BAE Duty                        classic     Madison Fox" "CMT       Chris mcg Test                      classic     Chris McCarroll-Gilbert" "RUN       Rundeck Core                        classic     Dileshni Jayasinghe" "SF2021        SF Office 2021                      classic     Jonathan Ascencio" "RDSYS       Rundeck Business Systems                classic     David Bricca" "AST      Architecture Strategy Team              classic     Philip Jacob" "ST       Sean Test Scrum                     classic     Sean Steacy" "CSGI      CSG Innovations                     classic     Doug Mcclure" "IDF      Patent Program                      classic     Anthony Rouhier" "GCM       Global Campaign Marketing               classic     Nisha Prajapati" "FLOW      Flexible Workflows Team                 classic     Girish Shankarraman" "CSGFR     CSG Innovation Feature Requests             classic     Turner Hancock" "RCLOUD     Rundeck Cloud                       classic     Dileshni Jayasinghe" "SFPSX     Super FPS Experience                    classic     Zane Magnus" "INC       Incident Review (Retired)               next-gen    Rich Lafferty" "SIQ     Strategic Integration Questions             classic     Mya King" "IA       Incidents & Alerting                    classic     Kanwal Ahuja" "ITSEC        IT Security                     classic     Srilatha Samala" "MOL       Marketing Operations & Lifecycle            classic     Shannon Renz" "AWOO     AmyWood                         classic     Amy Wood" "DL       Data Experience                     classic     Lilia Gutnik" "WORKS        Flexible Work Objects Team              classic     Girish Shankarraman" "PM        Product Management                  classic     Shekhar Patkar" "INCIDENTS  Flexible IR: Incidents                  classic     Jim Lindley" "SCHEDULES Flexible IR: Schedules team             classic     Arnold Cano" "SERVICES  Flexible IR: Services team              classic     Leeor Engel" "SONIC     Program Sonic                       classic     Derek Ralston" "T2D2        Tier 2 Support                      classic     Josef Goodyear" "SLO        Service Level Objectives                classic     Lyon Lay" "PLG      EI Product Led Growth                   classic     Derek Ralston" "ACME        Account Merge                       classic     Edith Katona" "FED      FedRAMP                         classic     Heidi Newell" "ZAP      Zuora Admin Project                 classic     Rachel Cass" "CHELS     Chelsea's board                     classic     Chelsea Vandermeer" "CHEL       chelsea                         classic     Chelsea Vandermeer" "SHAF       Shared Foundations                  classic     Srilatha Samala" "LEEORTEST Leeortest                       next-gen    Leeor Engel" "LEEORTEST3    LeeorTest3                      classic     Leeor Engel" "DEV       DevTools                        classic     Eric Sigler" "BB8       Tier 1 Support                      classic     Annette Fuller" "RLTEST1        RLTEST1                         classic     Rich Lafferty" "RLTEST2     RLTEST2                         classic     Rich Lafferty" "FACTS       Flexible Actions                    classic     Srilatha Samala" "BUILD     Flexible Workflows Builder UI               classic     Nathaniel Meierpolys" "IM       Incident Management Tribe               classic     Andrea Roberts" "IR     Incident Review                     classic     Rich Lafferty" "CCS     Catalytic-CS                        classic     Sarah Ryan" "WDHRIS     Workday                         classic     Mona Duval" "LG     Legal                           classic     Judy Hover" "SRCH       Search                          classic     Sofia Perdigão" "ZR     Zuora Revenue                       classic     Rachel Cass" "PRODTEST  Product Test                        classic     Dave Shackelford" "TFPROVDEV    Terraform Provider Support and Dev          classic     José Antonio Reyes Ruiz" "FED2      FedRAMP V2                      classic     Heidi Newell" "CSOSP        CSOps Status Page                   classic     João Freitas" "SK       Steacy Kanban                       classic     Sean Steacy" "ON        Onboarding                      classic     Stephanie Moy" "SEC     Security                        classic     Christine Chalmers" "SALESOPS   SALESOPS                        classic     Hillary Duan" "HD       Helpdesk                        classic     Gary Dowler" "RTIA      RT IA                           classic     Sean Steacy" "PLATARCH  Platform Archives                   classic     Sean Steacy" "JS        Jobscience                      classic     Ali Witte" "DOGE        Developer, On-boarding, and General Enablement      classic     Kat Gaines" "IN     Platform (Intelligence)                 classic     David Hayes" "JOY       Joy                         classic     Nick Russell" "ALT      Agile Leadership                    classic     Roma Shah" "BS      Business Systems                    classic     Carla Richards" "BD     Partnerships & Business Developement            classic     David Hayes" "GSD       G$D                         classic     Alisa Liebowitz" "RX        Realtime Cross-team                 classic     Kanwal Ahuja" "FOSS     Free Open-Source Software               classic     Tristan Chong" "PS      Public Security Reports                 classic     Andra Burck" "ATEST     Andrea Test                     classic     Andrea Roberts" "WEB        Web Tech Debt                       classic     Sweta Ackerman" "DATA       DataDuty                        classic     Manuraj Rajasekharan" "OPS      Operations Engineering Team             classic     Kenrick Thomas" "VIBE       Vibe Team                       classic     Alexandra Broudy" "BAE      Business Applications & Enablement          classic     Alisa Liebowitz" "MAR       Marketing                       classic     Nisha Ahluwalia" "SUP       Support                         classic     Ryan Hoskin" "WB        Workstation Build                   classic     Drew Bruton" "SN        ServiceNow                      classic     Divya Balasubramanian" "TOM     Tomster                         classic     Sweta Ackerman" "IG     Integration Guides                  classic     Kat Gaines" "WF     WorkFlow                        classic     Andrea Roberts" "IBM        IBM Whitewater Scaling                  classic     John Laban" "SRE        Site Reliability Engineering                classic     Dave Bresci" "API       API                         classic     Steve Rice" "LCR        Live Call Routing                   classic     sofia perdigão" "EO     Everynine Operations                    classic     Liz Harrison" "FE       Front-End Core                      classic     Andrew Zamojc" "INS     Insights                        classic     Chris Gagne" "REDACT        Incident Redaction Requests             classic     Iulia Cosman" "DES      Design                          classic     Erica Forte" "IMP       Incident Management - People                classic     Ajit Dipak" "CATS       Knowledge Base                      classic     Hadley Hadley" "INFRA       Infrastructure                      classic     Arup Chakrabarti" "SLS      Sales                           classic     Brett Skale" "AGILE     OLD- Agile Leadership Team              classic     Sean Steacy" "HACK      HackWeek                        classic     Baskar Puvanathasan" "EV        Evangelism                      classic     Sean Steacy" "IPMT      Integrated Portfolio Management Team            classic     David Saffren" "GP      Growth Website                      classic     Mark Smith" "OM     Order Management                    classic     Edith Katona" "MT       madison - test                      classic     Madison Fox" "STSTK     Simon Test Scrum to Kanban              classic     Simon Darken" "BREAK        Breakathon                      classic     Eric Sigler" "AN        Analytics                       classic     Sandhya Ramachandran" "FINS     Financial Systems (FINS)                classic     Steve Cahill" "BRH      Big Rock Hopper                     classic     Sean Steacy" "ITS       Integrations for Ticketing Systems          classic     Vadim Yanushkevich" "PAP        Pricing and Packaging                   classic     Hooman Tehrani" "FAC        Facilities                      classic     Trevor Steeves" "PROC       Procurement                     classic     Kwame Covington" "NAR       Narwhals                        classic     Justin Lazaro" "MWEB        Marketing Website                   classic     Mark Smith" "UX     User Experience                     classic     Corinna Sherman" "DX        Data Xperience                      classic     Sean Steacy" "OT        Open Tickets                        next-gen    Ali Reyes" "EIP     Engineering Initiative Pipeline             classic     David Saffren" "ENT     Enterprise                      classic     Derek Ralston" "PDA     Product Intelligence                    classic     Scott Bastek" "MKT      Marketing Ops                       classic     Nikki Webber" "ND       Narwhals Design                     classic     Elliot Onn" "TRAIN      Training & Development                  classic     Abi Morris" ""))
