/* Convenience functions for more-readable translations and rotations.
  Where relative directions like "left" and "right" are used,
  they assume you're looking from the Front view in OpenSCAD (Ctrl+8), 
  which is looking down the Y axis with X pointing right and Z to the top of the screen.
*/

module move(x=0,y=0,z=0,rx=0,ry=0,rz=0)
{ 
  translate([x,y,z])
    rotate([rx,ry,rz]) 
      children(); 
}

module moveUp(x) {
  translate([0, 0, x])
    children();
}

module moveDown(x) {
  translate([0, 0, -x])
    children();
}

module moveLeft(x) {
  translate([-x, 0, 0])
    children();
}

module moveRight(x) {
  translate([x, 0, 0])
    children();
}

module moveBack(x) {
  translate([0, x, 0])
    children();
}

module moveForward(x) {
  translate([0, -x, 0])
    children();
}

