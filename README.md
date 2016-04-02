# tjw-scad
My reusable additions to OpenSCAD.

## Installation 
Put the files somewhere accessible to your OpenSCAD installation.  I use a subfolder called `tjw`.

## Overview
See the comments within the modules for usage details.  Current contents:

* *arrange* - Easily arrange duplicates of a given object or many objects in two or three dimensions.
* *dfm* - Design For Manufacturing - has a ton of constants to use in your designs when some dimension depends on your printer's capabilities.
* *moves* - Mostly for readability, like `moveUp(4) cube(2)`.
* *spline* - Draw smooth spline curves through a list of points, and make surfaces from them.
