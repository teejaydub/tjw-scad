# tjw-scad
My reusable additions to OpenSCAD.

Emphasis is on trying to provide semantic names that are self-explanatory, or at least evocative of what they're for - or if that's hard, at least mnemonic once you've understood them.

Also, I'm attempting to collect things that are generic enough to be commonly useful, rather than a catch-all of everything I've ever built.

## Installation 
Put the files somewhere accessible to your OpenSCAD installation.  I use a subfolder called `tjw`.

## Overview
See the comments within the modules for usage details.  Current contents:

* *arrange* - Easily arrange duplicates of a given object or many objects in two or three dimensions.
* *dfm* - Design For Manufacturing - has a ton of constants to use in your designs when some dimension depends on your printer's capabilities.
* *moves* - Mostly for readability, like `moveUp(4) cube(2)`.
* *spline* - Draw smooth spline curves through a list of points, and make surfaces from them.
* *primitives* - Plenty of reusable shapes, especially for things that recur in my own designs.
