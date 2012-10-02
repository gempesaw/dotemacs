# dotemacs

my .emacs.d folder with all of my customizations. should be completely portable.

# Installation

There are a couple different ways this can be done, but what works for me is the following:

    git clone git://github.com/gempesaw/dotemacs.git directory-of-your-choosing
    ln -s directory-of-your-choosing ~/.emacs.d

To get the snippets:

    cd directory-of-your-choosing
    git submodule update --init

# Issues

During the first installation, you'll need to go into elget.el and uncomment out the two lines at the bottom in order to pull recipies from emacswiki and melpa. Afterwards, you should probably comment those lines out again because it seems to take a long time to talk to emacswiki.

## Ubuntu

While installing Magit, it may want you to have makeinfo installed, which you can get with:

    sudo apt-get install texinfo

# Information

These configurations currently come from three main places:

1. Things I like and have gotten used to over the years
2. Ryan McGeary's [Working with OS X and Emacs](http://how-i-work.com/workbenches/30-working-with-os-x-and-emacs)
3. Bozhidar's Batsov's [emacs-prelude](https://github.com/bbatsov/prelude)
4. [Magnar Sveen's](http://github.com/magnars) amazing work over at [emacsrocks](http://www.emacsrocks.com)

I'm using [dmitri's](https://github.com/dimitri/) [el-get](https://github.com/dimitri/el-get) to manage my packges - a couple installed from his recipe list and a couple custom ones added to el-get-sources.
