# dotemacs

my .emacs.d folder with all of my customizations; should be completely portable (in theory).

# Installation

There are a couple different ways this can be done, but what works for me is the following:

    git clone git://github.com/gempesaw/dotemacs.git directory-of-your-choosing

In UNIX-like environments (OS X, Linux), you can create a handy symlink.

    ln -s directory-of-your-choosing ~/.emacs.d

In Windows, you'll probably want to check out [Sacha Chua's helpful guide](http://sachachua.com/blog/2012/06/making-gnu-emacs-play-well-on-microsoft-windows-7/). When you clone this repo, put it in your %HOME% directory, whatever you make that, since the option of symlinks is slightly less attractive.

To get the snippets submodule:

    cd directory-of-your-choosing
    git submodule update --init

## Issues

### Ubuntu

While installing Magit, it may want you to have makeinfo installed, which you can get with:

    sudo apt-get install texinfo

# Information

These configurations currently come from three main places:

1. Things I like and have gotten used to over the years
2. Ryan McGeary's [Working with OS X and Emacs](http://how-i-work.com/workbenches/30-working-with-os-x-and-emacs)
3. Bozhidar's Batsov's [emacs-prelude](https://github.com/bbatsov/prelude)
4. [Magnar Sveen's](http://github.com/magnars) amazing work over at [emacsrocks](http://www.emacsrocks.com)

I was previously using [dmitri's](https://github.com/dimitri/) [el-get](https://github.com/dimitri/el-get) to manage my packges, but have since changed to [package.el](http://elpa.gnu.org/) and [MELPA](http://melpa.milkbox.net/) to accomplish this task.
