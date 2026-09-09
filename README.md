# dotemacs

my .emacs.d folder with all of my customizations; should be completely
portable (in theory).

# Installation

You can do this any way you like; this is the way I like:

    git clone https://github.com/gempesaw/dotemacs ~/.emacs.d
    git submodule update --init

In Windows, you'll probably want to check out [Sacha Chua's helpful
guide](http://sachachua.com/blog/2012/06/making-gnu-emacs-play-well-on-microsoft-windows-7/). When
you clone this repo, put it in your %HOME% directory, whatever you
make that, since the option of symlinks is slightly less attractive.

## dependencies

- ag: `brew install ag`
- makeinfo (ubuntu?): `sudo apt-get install texinfo`

### sibling repos

Four files load elisp from outside this repo, by `:load-path` or
`load-file`. Everything in `packages/` is loaded defensively -- a file
that errors is retried once and then reported through a startup warning
rather than truncating the rest of init -- so a missing clone costs you
that one feature instead of a broken Emacs. Clone them into `~/opt` to
get the feature:

    git clone git@github.com:gempesaw/kubectl.el.git          ~/opt/kubectl.el
    git clone git@github.com:gempesaw/agent-shell-dashboard.git ~/opt/agent-shell-dashboard
    git clone https://github.com/nohzafk/consult-snapfile      ~/opt/consult-snapfile

`dg-modular.el` also sources `~/opt/modular/utils/emacs/modular.el`, and
the pulumi transient reads stack config out of `~/opt/infra` at run time.
Both are work repos and both already check before they touch anything, so
their absence is silent.

### assumptions

`~/.emacs.d` is expected to *be* this checkout -- clone it there, or
symlink it. A few paths resolve through `user-emacs-directory` and the
`aws-sso`, `kubie`, `micm` and `uv` binaries are expected on `PATH` for
the pulumi transient.

# Information

These configurations currently come from three main places:

1. Things I like and have gotten used to over the years
2. Ryan McGeary's [Working with OS X and Emacs](http://how-i-work.com/workbenches/30-working-with-os-x-and-emacs)
3. Bozhidar's Batsov's [emacs-prelude](https://github.com/bbatsov/prelude)
4. [Magnar Sveen's](http://github.com/magnars) amazing work over at [emacsrocks](http://www.emacsrocks.com)

I was previously using [dmitri's](https://github.com/dimitri/)
[el-get](https://github.com/dimitri/el-get) to manage my packges, but
have since changed to [package.el](http://elpa.gnu.org/) and
[MELPA](http://melpa.milkbox.net/) to accomplish this task.
