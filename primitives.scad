/* Primitive shapes that I find useful for constructing projects.
  Loosely-structured, just a "misc" home for new things.
  Usage:
    use <tjw-scad/primitives.scad>;
*/

use <arrange.scad>;
use <moves.scad>;


// Generates a lower right triangle in the fourth quadrant of X-Y, extruded in Z.
// If center=true, centers in Z; otherwise, it's in +Z.
// Otherwise, it's entirely in the fourth quadrant.
module right_triangle(dims, center=false) {
  moveDown(center? dims[2] / 2: 0)
    linear_extrude(dims[2])
      polygon([[0, 0], [-dims[0], 0], [0, dims[1]]]);
}

module hollow_cube(dims, walls){
  holes = dims - 2*walls + 2*EPSILON3;
  difference(){
    cube(dims);
    translate(walls - EPSILON3)
      cube(holes);
  }
}

// Produces a 2D rectangle with the corners taken off at a 45-degree angle, centered.
// Dims is [x, y], and radius is taken off of each side.
module chamfered_square(dims, radius) {
  offset(delta=radius, chamfer=true) {
    square(dims - [2*radius, 2*radius], center = true);
  }
}

// Produces a 2D rectangle with the corners rounded off, centered.
// Dims is [x, y], and radius is taken off of each side.
module rounded_square(dims, radius) {
  offset(r=radius) {
    square(dims - [2*radius, 2*radius], center = true);
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

// Same as rounded_square_shell, but chamfered instead of rounded.
module chamfered_square_shell(dims, walls, inner_radius, outer_radius, hollow=true) {
  difference() {
    chamfered_square(dims, outer_radius);
    if (hollow)
      chamfered_square(dims - w*walls, inner_radius);
  }
}

/* Extrudes a centered, rounded square shell in Z.
  dims is [x, y, z] - includes just the body in Z, not top and bottom.
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

// Same, but with square corners - not round or chamfered.
module frame(dims, walls, top=false, bottom=false, body=true) {
  translate([0, 0, -dims[2]/2]) {
    union() {
      if (body)
        linear_extrude(height=dims[2])
          hollow_cube(dims, walls);
      if (bottom) 
        translate([0, 0, -walls[2]])
          linear_extrude(height=walls[2])
            cube(dims);
      if (top) 
        translate([0, 0, dims[2]])
          linear_extrude(height=walls[2])
            cube(dims);
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

/* Torus with minor radius r1 and major radius r2,
  centered at the origin,
  lying flat like a bagel on a table, with the hole pointing up.
*/
module torus(r1, r2) {
  rotate_extrude(convexity = 10)
    translate([r2, 0])
      circle(r = r1);
}

// A centered cube, except that it's not centered in Z.
module cubeOnFloor(dims) {
  moveUp(dims[2] / 2)
    cube(dims, center=true);
}

// A cylinder, on the X-Y plane, with a fillet to the horizontal plane.
// 'r1' is the fillet radius; defaults to d/2.
// If 'quarter', only fillet over the positive X+Y quadrants.
// (Good for sticking it in a corner.)
module filletedCylinder(h, d, fillet=0, quarter=false) {
  r1 = fillet? fillet: d/2;
  r2 = r1 + d/2;
  union() {
    cylinder(h=h, d=d);
    difference() {
      cylinder(h=r1, r=r2);
      moveUp(r1)
        torus(r1, r2);
      if (quarter)
          cube([2*d, 2*d, 2*r1]);
    }
  }
}

// Like a cube with these outer dimensions,
// but rounded on all sides.
// Centered.
// Requires that Z be the shortest dimension.
module chicletZ(dx, dy, dz) {
  union() {
    // Cube in the middle, shortened in X and Y
    cube([dx - dz + 0.1, dy - dz + 0.1, dz], center=true);

    // Cylinders on the sides, shortened along their lengths
    twin_x()
      moveLeft(dx/2 - dz/2)
        rotate([90, 0, 0])
          cylinder(h=dy - dz, d=dz, center=true);
    twin_y()
      moveBack(dy/2 - dz/2)
        rotate([0, 90, 0])
          rotate([0, 0, 5])
            cylinder(h=dx - dz, d=dz, center=true);

    // Spheres at the corners
    twin_xy()
      translate([dx/2 - dz/2, dy/2 - dz/2])
        sphere(d=dz);
  }
}

// Same, but any dimension can be the shortest.
module chiclet(dx, dy, dz) {
  // Simplify so that Z is the minor axis - the radius of the corners.
  if (dz != min([dx, dy, dz])) 
    if (dx == min([dx, dy, dz])) {
      rotate([0, 90, 0])
        chicletZ(dz, dy, dx);
    } else if (dy == min([dx, dy, dz])) {
      rotate([90, 0, 0])
        chicletZ(dx, dz, dy);
    }
  else
    chicletZ(dx, dy, dz);
}

// A round fillet like a bead of caulk,
// centered in X, laid down between X-Z and X-Y planes,
// in -Y and +Z - that is, in front on the floor.
module fillet(length, r) {
  difference() {
    moveLeft(length/2)
      moveForward(r)
        moveDown(0.01)
          cube([length, r + 0.01, r + 0.01]);
    moveForward(r)
      moveUp(r)
        rotate([5, 0, 0])  // line up with other fillets
          rotate([0, 90, 0])
            cylinder(h=length + 0.02, r=r, center=true);
  }
}

// Like a cube with these dimensions,
// but filleted outward on the bottom to blend into a horizontal surface.
// Modeled sitting on the X-Y plane, centered.
// Assumes Y is the thinnest dimension.
// Leaves some holes on the bottom that I don't care about right now.
module filletedChiclet(dx, dy, dz, fillet=0) {
  fillet = fillet? fillet: dy/2;
  union() {
    // Start with the chiclet.
    // Make it taller, then cut off the bottom.
    intersection() {
      moveDown(dy/2)
        moveUp(dz/2)
          chiclet(dx, dy, dz + dy, bothRound=false, $fn=30);
      moveUp(dz/2 - 0.01)
        cube([2*dx, 2*dy, dz], center=true);
    }

    // Add cylindrical fillets on the ends.
    twin_x()
      moveLeft((dx - dy)/2)
        filletedCylinder(d=dy, h=dz - dy, fillet, $fn=30);

    // Add fillets along the sides.
    twin_y()
      moveForward(dy/2)
        fillet(length=dx - dy, r=fillet, $fn=30);
  }
}