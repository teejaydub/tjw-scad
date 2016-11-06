/* Primitive shapes that I find useful for constructing projects.
  Loosely-structured, just a "misc" home for new things.
  Usage:
    use <tjw-scad/primitives.scad>;
*/

module hollow_cube(dims, walls){
  holes = dims - 2*walls + 2*EPSILON3;
  difference(){
    cube(dims);
    translate(walls - EPSILON3)
      cube(holes);
  }
}

/* Produces a centered square, hollow, with the specified wall thicknesses,
  with corners rounded by the specified radii.
  dims and walls are pairs of [x, y].
*/
module rounded_square_shell(dims, walls, inner_radius, outer_radius, hollow=true) {
  difference() {
    offset(r = outer_radius, $fn=30) {
      square(dims - [2*outer_radius, 2*outer_radius], center = true);
    }
    if (hollow)
      offset(r = inner_radius, $fn=30) {
        square(dims - 2*walls - [2*inner_radius, 2*inner_radius], center = true);
    }
  }
}

// Same, but chamfered instead of rounded.
module chamfered_square_shell(dims, walls, inner_radius, outer_radius, hollow=true) {
  difference() {
    offset(delta=outer_radius, chamfer=true, $fn=30) {
      square(dims - [2*outer_radius, 2*outer_radius], center = true);
    }
    if (hollow)
      offset(delta=inner_radius, chamfer=true, $fn=30) {
        square(dims - 2*walls - [2*inner_radius, 2*inner_radius], center = true);
    }
  }
}

/* Extrudes a centered, rounded square shell in Z.
  dims is [x, y, z].
  walls is [x, y, z] (z is for top and bottom).
  Puts the corner at the origin, and the frame in +x, +y, +z.
  If top and/or bottom are true, adds solid slabs in +Z and -Z.
*/
module round_frame(dims, walls, radius, top=false, bottom=false, body=true) {
  translate([0, 0, -dims[2]/2])
    union() {
      if (body)
        linear_extrude(height=dims[2])
          rounded_square_shell(dims, walls, radius, radius);
      if (bottom)
        translate([0, 0, -walls[2]])
          linear_extrude(height=walls[2])
            rounded_square_shell(dims, walls, radius, radius, hollow=false);
      if (top) 
        translate([0, 0, dims[2]])
          linear_extrude(height=walls[2])
            rounded_square_shell(dims, walls, radius, radius, hollow=false);
    }
}

// Same, but with a chamfered edge.
module chamfered_frame(dims, walls, radius, top=false, bottom=false, body=true) {
  translate([0, 0, -dims[2]/2]) {
    union() {
      if (body)
        linear_extrude(height=dims[2])
          chamfered_square_shell(dims, walls, radius, radius);
      if (bottom) 
        translate([0, 0, -walls[2]])
          linear_extrude(height=walls[2])
            chamfered_square_shell(dims, walls, radius, radius, hollow=false);
      if (top) 
        translate([0, 0, dims[2]])
          linear_extrude(height=walls[2])
            chamfered_square_shell(dims, walls, radius, radius, hollow=false);
    }
  }
}


/* Given an array, returns a copy of it, reversed.
*/
// (not used after all)
function reverse(a) = [ for (i = [len(a) - 1 : -1 : 0]) a[i] ];

/* Sort of a printer-friendly equivalent of a cylinder.
  Oriented with its point in +Z, centerd on the origin.
*/
module teardrop(width, depth) {
  union() {
    rotate([0, 45, 0])
      cube([width / sqrt(2), depth, width / sqrt(2)], center=true);
    difference() {
      rotate([90, 0, 0])
        cylinder(r=width / 2, h=depth, center=true);
      translate([0, 0, width * 2 + 0.01]) 
        cube([width * 4, depth * 4, width * 4], center=true);
    }
  }
}
