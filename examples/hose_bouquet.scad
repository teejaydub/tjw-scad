/* bouquet of hoses, to show off splines
*/

include <../dfm.scad>
include <../moves.scad>
use <../spline.scad>

path = [[-5, 0, 0], [5, 0, 0], [4, 2, 1], [-2, -1, 6], [-3, 0, 5], [4, 5, 10]];

union() {
  for (a = [0 : 20 : 360])
    rotate([0, 0, a])
      spline_hose(path, outer_diameter=2);
}
