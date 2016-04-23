/* Design For Manufacture (DFM) constants.
  Include it using: include <dfm.scad>
  Use these to allow others to easily modify your designs to work well on their own printers,
  or to port your own designs to your next printer!
*/

// ===========================================================================
// Settings to customize per printer

// The layer height setting you're using to print.
NOMINAL_LAYER = 0.2;

// The nominal height of the first layer printed, often different from the rest.
NOMINAL_FIRST_LAYER = 0.35;

// The steepest angle, in degrees from +Z, that your printer can print.
// The maximum overhang angle.
MAX_OVERHANG_ANGLE =
  //45;  // fairly conservative universal value
  60;  // not impossible if you have a layer fan and it hits the geometry well


// ===========================================================================
// Universal constants

// Use this to ensure that Boolean edges aren't coincident.
EPSILON = 0.01;
EPSILON2 = [EPSILON, EPSILON];
EPSILON3 = [EPSILON, EPSILON, EPSILON];

// The "Golden Ratio," AKA golden mean or divine proportion, 
// possibly overhyped but you could do worse as a relative size for nice forms.
GOLDEN = 1.618;

// Use like "THUMB = 1*inch;"
inch = 25.4;


// ===========================================================================
// Derived settings that you may not need to customize

// This is the default for my machine.
SINGLE_LAYER = NOMINAL_LAYER + EPSILON;

// The first layer is usually thicker to promote good bonding with the build plate.
// So, if you want a single layer, and it's the bottom layer, use this.
FIRST_LAYER = NOMINAL_FIRST_LAYER + EPSILON;
// But that's probably not enough to actually get it to appear from the slicer,
// so to produce a single first layer output, use this.
MIN_THICKNESS_FIRST_LAYER = NOMINAL_FIRST_LAYER + 0.45;

// The minimum horizontal thickness for something to get printed - a vertical wall, e.g.
MIN_WALL_THICKNESS = NOMINAL_LAYER * 2.6;

// If you want a dimension to be the same horizontally and vertically,
// this is the minimum thickness for printing.
MIN_THICKNESS = max(MIN_WALL_THICKNESS, MIN_THICKNESS_FIRST_LAYER);

// This is the total delta between surfaces for different degrees of fit.
// The main constant in each group is sized for things that slide freely between two walls; 
// if you have something that is fixed in the middle between two walls, use _FIXED.
// And for structures that are fixed and have only one gap, use _SINGLE.
LOOSE_FIT = 1.2;  // Extra sloppy - for things that need some slack to insert.
LOOSE_FIT_FIXED = LOOSE_FIT + 0.2;
LOOSE_FIT_SINGLE = LOOSE_FIT / 2;

SLIDE_FIT = 0.6;  // Close enough to slide well without getting crooked.
SLIDE_FIT_FIXED = SLIDE_FIT * 2;
SLIDE_FIT_SINGLE = SLIDE_FIT / 2;

FRICTION_FIT = 0.4;  // Close enough to require some force, and then stick.
FRICTION_FIT_FIXED = 0.6;
FRICTION_FIT_SINGLE = 0.3;

// The thickness of something to be printed just for support.
SUPPORT_WIDTH = MIN_THICKNESS;

// A good thickness for something that should flex, but be strong.
// Ends up being a couple of layers at 0.2 mm layer height.
STRONG_FLEX = 0.45;
