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
