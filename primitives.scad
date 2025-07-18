/* Primitive shapes that I find useful for constructing projects.
  Loosely-structured, just a "misc" home for new things.
  Usage:
    use <tjw-scad/primitives.scad>;
*/

use <arrange.scad>;
use <moves.scad>;

EPSILON = 0.01;


// Generates a lower right triangle in the fourth quadrant of X-Y, extruded in Z.
// If center=true, centers in Z; otherwise, it's in +Z.
// Otherwise, it's entirely in the fourth quadrant.
module right_triangle(dims, center=false) {
  moveDown(center? dims[2] / 2: 0)
    linear_extrude(dims[2])
      polygon([[0, 0], [-dims[0], 0], [0, dims[1]]]);
}

// Convert a regular polygon inner or "flat" diameter to the outer or "vertex" one.
function polygon_outer_d(sides, inner_d) = inner_d / cos(180 / sides);

// Generates an extruded polygon with the given number of equal sides,
// and either the outer diameter measured at the vertices,
// or the inner diameter measured from flat-to-flat (if an even number of faces).
// (When cloning a physical object, that can be easier to measure precisely.)
module regular_polygon_prism(sides=5, outer_d=0, flat_d=0, h=1) {
  outer_d = (outer_d? outer_d : polygon_outer_d(sides, flat_d));
  cylinder(h=h, $fn=sides, d=outer_d);
}

// Convenience functions
module decagon_prism(outer_d=0, flat_d=10, h=1)
  { regular_polygon_prism(10, outer_d, flat_d, h); }

module octagon_prism(outer_d=0, flat_d=10, h=1)
  { regular_polygon_prism(8, outer_d, flat_d, h); }

module hexagon_prism(outer_d=0, flat_d=10, h=1)
  { regular_polygon_prism(6, outer_d, flat_d, h); }

module triangle_prism(outer_d=0, flat_d=10, h=1)
  { regular_polygon_prism(3, outer_d, flat_d, h); }

// Generates a hexagon on the X-Y plane.
// d is the flat diameter - the width of a wrench that you're fitting around it like a nut.
// (Maybe more efficient if done with regular_polygon_prism now?)
module hexagon(d) {
  boxWidth = d/1.75;

  for (r = [-60, 0, 60])
    rotate([0,0,r]) 
      square([boxWidth, d], center=true);
}

// Returns a sinusoidal path, with the given length in X, varying in Y, at Z=0.
// Goes through the given number of whole cycles.
// Starts at X=0, Y=0.
function sinePath(length, cycles, amplitude) =
  let(POINTS_PER_CYCLE = 16)
  let(POINTS = POINTS_PER_CYCLE * cycles)
  concat(
    [for (i = [0 : 1 : POINTS])
      [i * length / POINTS, amplitude * sin(i * 360 * cycles / POINTS)]
    ]);

// A "bump" made of a portion of a sphere.
// Its bottom is at Z=0, where it has the given radius,
// and its convex curve reaches just up to h.
module spherical_bump(r, h) {
  big_r = (h*h + r*r)/(2*h);
  d = 2 * big_r;
  difference() {
    moveDown(big_r - h)
      sphere(r=big_r);
    moveDown(big_r)  // cut off at Z=0
      cube([d, d, d], center=true);
  }
}

// Same, but with a rounded bottom edge.
module spherical_bump_rounded(r, h) {
  d = 2 * r;
  scale([1, 1, 2 * h / d])
    difference() {
      sphere(r=r);
      moveDown(r)  // cut off at Z=0
        cube([d, d, d], center=true);
    }
}

module hollow_cube(dims, walls){
  holes = dims - 2*walls + 2*EPSILON3;
  difference(){
    cube(dims);
    translate(walls - EPSILON3)
      cube(holes);
  }
}

// A cylinder with its center cut out.
// Modeled in +Z, centered in X-Y.
// d is the outer dimension.
module pipe(h, d, wall) {
  difference() {
    cylinder(h=h, d=d);
    moveDown(EPSILON)
      cylinder(h=h + 2 * EPSILON, d=d - 2 * wall);
  }
}

// A cylinder with its center cut out.
// Modeled in +Z, centered in X-Y.
// outer is the outer diameter, inner is the inner (hole) diameter.
module pipe2(h, outer, inner) {
  difference() {
    cylinder(h=h, d=outer);
    moveDown(EPSILON)
      cylinder(h=h + 2 * EPSILON, d=inner);
  }
}


// Same, with chamfers on inner and outer circumferences, top and bottom.
// Chamfer at 45 degrees by the given amount,
// which defaults to a quarter of the height, the radius, or the wall width,
// whichever is smaller.
module pipe_chamfered(h, d, wall, chamfer=-1)
{
  chamfer = (chamfer == -1? min(h/4, d/4, wall/4): chamfer);
  rotate_extrude(convexity=10) {
    polygon([
      [d / 2, h - chamfer],
      [d / 2, chamfer],
      [d / 2 - chamfer, 0],
      [d / 2 - (wall - chamfer), 0],
      [d / 2 - wall, chamfer],
      [d / 2 - wall, h - chamfer],
      [d / 2 - (wall - chamfer), h],
      [d / 2 - chamfer, h]
      ]);
  }
}

// Same, but with different diameters and wall thicknesses at bottom and top.
module pipe_tapered(h, d1, d2, wall1, wall2)
{
  difference() {
    cylinder(h=h, d1=d1, d2=d2);
    moveDown(EPSILON)
      cylinder(h=h + 2 * EPSILON, d1=d1 - 2 * wall1, d2=d2 - 2 * wall2);
  }
}

// Same, but d1 and d2 are the diameters at the centers of the walls.
module pipe_tapered_c(h, d1, d2, wall1, wall2)
{
  difference() {
    cylinder(h=h, d1=d1 + wall1, d2=d2 + wall2);
    moveDown(EPSILON)
      cylinder(h=h + 2 * EPSILON, d1=d1 - wall1, d2=d2 - wall2);
  }
}

// A cylinder with the given height and radius, with its bottom at Z=0.
// Chamfer the upper edge at 45 degrees by the given amount,
// which defaults to half the height or half the radius,
// whichever is smaller.
module chamfered_cylinder(h, r, chamfer=-1) {
  chamfer = (chamfer == -1? min(h/2, r/2): chamfer);
  r2 = r - chamfer;
  h1 = h - chamfer;
  union() {
    // bottom half is a straight cylinder.
    cylinder(h=h1, r=r, center=false);
    // upper half is a truncated cone.
    moveUp(h1 - EPSILON)
      cylinder(h=chamfer + EPSILON, r1=r, r2=r2);
  }
}

// A cylinder with the given height and radius, with its bottom at Z=0.
// Bevel the upper edge with the given radius,
// which defaults to half the height or half the radius,
// whichever is smaller.
module beveled_cylinder(h, r, bevel=-1) {
  bevel = (bevel == -1? min(h/2, r/2): bevel);
  r2 = r - bevel;
  h1 = h - bevel;

  // Construct it in 2D from bottom and top rects joined by a circle,
  // then lathe it.
  rotate_extrude(convexity = 10) {
    union() {
      square([r, h1]);
      translate([r2, h1])
        circle(r=bevel);
      square([r2, h]);
    }
  }
}

// Same, but with bevels top and bottom.
module sausage(h, r, bevel=-1) {
  bevel = (bevel == -1? min(h/2, r/2): bevel);
  r2 = r - bevel;
  h2 = h - 2 * bevel;

  rotate_extrude(convexity = 10) {
    union() {
      translate([0, bevel])
        square([r, h2]);  // shorter, wider square
      square([r2, h]);  // taller, narrower square
      intersection() {
        // Just keep the half-circles (quarter would even be enough),
        // so the rotation doesn't complain when bevel > r/2
        union() {
          translate([r2, bevel])
            circle(r=bevel);
          translate([r2, bevel + h2])
            circle(r=bevel);
        }
        square([2*r, h + EPSILON]);
      }
    }
  }
}

// Produces a 2D rectangle with the corners taken off at a 45-degree angle, centered.
// Dims is [x, y], and radius is taken off of each side.
// Radius must be less than 1/4 of the smaller dimesntion.
module chamfered_square(dims, radius) {
  offset(delta=radius, chamfer=true) {
    square(dims - [2*radius, 2*radius], center = true);
  }
}

// Produces a 2D rectangle with the corners rounded off, centered.
// Dims is [x, y], and radius is taken off of each side.
// Radius must be less than 1/4 of the smaller dimesntion.
module rounded_square(dims, radius, center=true) {
  translate([center? 0: radius, center? 0: radius, 0])
    offset(r=radius)
      square(dims - [2*radius, 2*radius], center=center);
}

// Like a "cube" with the given dims, with corners rounded off in the X-Y plane,
// to the given radius.
// (See chiclet() to round all corners.)
module slab(dims, radius, center=true) {
  linear_extrude(height=dims[2])
    rounded_square(dims, radius, center);
}

// Same, but chamfered instead of rounded, and always centered.
module chamfered_slab(dims, radius) {
  linear_extrude(height=dims[2])
    chamfered_square(dims, radius);
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
      chamfered_square(dims - 2*walls, inner_radius);
  }
}

// Same as chamfered_square, but with no chamfers.
module square_shell(dims, walls, hollow=true) {
  difference() {
    square(dims + [0, 0]);
    if (hollow)
      translate(walls)
        square(dims - 2*walls);
  }
}

/* Extrudes a centered, rounded square shell in Z.
  dims is [x, y, z] - includes just the body in Z, not top and bottom.
  walls is [x, y, z] (z is for top and bottom).
  Puts the corner at the origin, and the frame in +x, +y, +z.
  If centerV is true, centers the result vertically.
  If top and/or bottom are true, adds solid slabs in +Z and -Z.
  (Top and bottom slabs are added around the body, wherever it's placed vertically.)
*/
module round_frame(dims, walls, radius, top=false, bottom=false, body=true, centerV=true) {
  deltaV = centerV? -dims[2]/2 : 0;
  translate([0, 0, deltaV])
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
module chamfered_frame(dims, walls, radius, top=false, bottom=false, body=true, centerV=true) {
  deltaV = centerV? -dims[2]/2 : 0;
  translate([0, 0, deltaV])
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

// Same, but with square corners - not round or chamfered.
module frame(dims, walls, top=false, bottom=false, body=true, centerV=true) {
  deltaV = centerV? -dims[2]/2 : 0;
  translate([0, 0, deltaV])
    union() {
      if (body)
        linear_extrude(height=dims[2])
          square_shell(dims, walls);
      if (bottom) 
        translate([0, 0, -walls[2]])
          cube([dims[0], dims[1], walls[2]]);
      if (top) 
        translate([0, 0, dims[2]])
          cube([dims[0], dims[1], walls[2]]);
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
  If r2 < r1, you'll get nothing - I don't know what you'd expect, but it wouldn't be a torus.
*/
module torus(r1, r2) {
  if (r2 >= r1)
    rotate_extrude(convexity = 10)
      translate([r2, 0])
        circle(r=r1);
}

// Just the portion of a torus, positioned as above, that's in the +X/+Y quadrant.
module quarterTorus(r1, r2) {
  if (r2 >= r1)
    intersection() {
      torus(r1, r2);
      translate([0, 0, -r1 + EPSILON])
        cube([r1 + r2 + EPSILON, r1 + r2 + EPSILON, 2*r2 + 2*EPSILON]);
    }
}

// Negative torus, for cutting off a rounded corner from something.
// Modeled the same as the torus.
// You may want to trim it before you use it.
module torusCutter(r1, r2) {
  difference() {
    cube([2 * (r2 + r1) + 2*EPSILON, 2 * (r2 + r1) + 2*EPSILON, 2 * r1 + 2*EPSILON], center=true);
    torus(r1, r2);
  }
}

// Cutter for the inside edge of a torus.
// Looks like a hub for a torus-shaped wheel.
// Nice for rounding a fillet in two curving dimensions.
module torusHub(r1, r2) {
  intersection() {
    torusCutter(r1, r2);
    cylinder(r=r2, h=2 * r1 + 2, center=true);
  }
}

// A sphere resting on the X-Y plane and centered in it.
// Its lower hemisphere filleted to the X-Y plane.
module filleted_sphere(d) {
  let(r = d / 2, fr1 = r / 4) {
    union() {
      moveUp(r)
        sphere(d=d);
      moveUp(fr1)
        // Trimming the upper quarter of the hub makes its slope there 45 degrees,
        // which exactly matches the slope of the sphere at that point, for a smooth transition.
        trimUpper(2 * d, fr1 / 2)
          torusHub(fr1, r);
    }
  }
}

// A cube, centered in and sitting on X-Y, with the specified draft angles, in degrees.
// Draft always shrinks one end of the cube.
// E.g., a positive draft angle of 5 in X means the width is less on the bottom than the top,
// so that the sides make an angle of 5 degrees from vertical.  The top dimension is as specified.
// A negative X draft angle means that the bottom is as specified, and the top is narrower.
// The Y draft is similar, but affects only the Y axis.
// (There is no Z draft, for clarity - would it be versus X or Y? - and because often,
// draft is for removing something from a mold, where an "up" direction is natural.)
module cubeDraftAngle(dims, drafts) {
  cubeDraft(dims, [
      drafts[0] > 0? tan(drafts[0]) * dims[2]:
        drafts[0] < 0? -tan(-drafts[0]) * dims[2]:
          0,
      drafts[1] > 0? tan(drafts[1]) * dims[2]:
        drafts[1] < 0? -tan(-drafts[1]) * dims[2]:
          0,
    ]);
}

// Same, but deltas are absolute, subtracted from each side.
// That is, with an X delta of 1, the bottom points move 1 toward the center.
// With an X delta of -1, the top points move 1 toward the center.
// Again, Z draft isn't allowed, because what it would mean is unclear.
module cubeDraft(dims, deltas) {
  // Positive values for the dimensions at upper and lower levels.
  dxLower = dims[0] / 2 - (deltas[0] > 0? deltas[0]: 0);
  dxUpper = dims[0] / 2 - (deltas[0] < 0? -deltas[0]: 0);
  dyLower = dims[1] / 2 - (deltas[1] > 0? deltas[1]: 0);
  dyUpper = dims[1] / 2 - (deltas[1] < 0? -deltas[1]: 0);

  // See figures at: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Primitive_Solids#polyhedron
  CubePoints = [
    [ -dxLower, -dyLower, 0 ],  //0
    [  dxLower, -dyLower, 0 ],  //1
    [  dxLower,  dyLower, 0 ],  //2
    [ -dxLower,  dyLower, 0 ],  //3
    [ -dxUpper, -dyUpper, dims[2] ],  //4
    [  dxUpper, -dyUpper, dims[2] ],  //5
    [  dxUpper,  dyUpper, dims[2] ],  //6
    [ -dxUpper,  dyUpper, dims[2] ]]; //7
    
  CubeFaces = [
    [0,1,2,3],  // bottom
    [4,5,1,0],  // front
    [7,6,5,4],  // top
    [5,6,2,1],  // right
    [6,7,3,2],  // back
    [7,4,0,3]]; // left
    
  polyhedron(CubePoints, CubeFaces);
}

// A centered cube, except that it's not centered in Z - its bottom is at Z=0.
module cubeOnFloor(dims) {
  moveUp(dims[2] / 2)
    cube(dims, center=true);
}

// Same, but its top is at Z=0. 
module cubeUnderFloor(dims) {
  moveDown(dims[2] / 2)
    cube(dims, center=true);
}

// A cylinder, on the X-Y plane, with a fillet to the horizontal plane.
// 'fillet' is the fillet radius; defaults to d/2.
// If 'quarter', only fillet over the positive X+Y quadrants.
// (Good for sticking it in a corner.)
module filletedCylinder(h, d, fillet=0, quarter=false) {
  r1 = fillet? fillet: min(h, d/2);
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

// Same, but in +Z.
module chicletOnFloor(dims) {
  moveUp(dims[2] / 2)
    chiclet(dims[0], dims[1], dims[2]);
}

// Similar to the chiclet, but allows any radius instead of using the smallest.
// Maybe less efficient.  Probably negligible.
// Centered.
// r is the radius of rounding; constrained (and defaulting) to half of the smallest side.
// [not yet finished!]
module roundedCube(dims, r=0) {
  smallestSide = min(dims);
  radius = r == 0? smallestSide / 2: min(r, smallestSide / 2);
  diameter = 2 * radius;
  union() {
    cube([dims.x - diameter + 0.1, dims.y - diameter + 0.1, dims.z], center=true);
    cube([dims.x, dims.y - diameter + 0.1, dims.z - diameter], center=true);
    cube([dims.x - diameter + 0.1, dims.y, dims.z - diameter], center=true);

    // Cylinders on the sides, shortened along their lengths
    twin_xz()
      moveUp(dims[2] / 2 - radius)
      moveLeft((dims[0] - diameter) / 2)
        rotate([90, 0, 0])
          cylinder(h=dims[1] - diameter, d=diameter, center=true);
    twin_yz()
      moveUp(dims[2] / 2 - radius)
      moveBack((dims[1]- diameter) / 2)
        rotate([0, 90, 0])
          rotate([0, 0, 5])
            cylinder(h=dims[0] - diameter, d=diameter, center=true);

    // Cylinders at the four corners
    twin_xy()
      moveLeft((dims[0] - diameter) / 2)
      moveBack((dims[1] - diameter) / 2)
        cylinder(h=dims[2] - diameter, d=diameter, center=true);

    // Spheres at the corners
    twin_xyz()
     translate([dims[0]/2 - radius, dims[1]/2 - radius, dims[2]/2 - radius])
       sphere(d=diameter);
  }
}

module roundedCubeOnFloor(dims, r) {
  moveUp(dims.z / 2)
    roundedCube(dims, r);
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
// 'fillet' is the fillet radius; defaults to dy/2.
// Modeled sitting on the X-Y plane, centered.
// Assumes Y is the thinnest dimension.
// Leaves some holes on the bottom that I don't care about right now.
// Also may have some limitations in dimensions that make sense??
module filletedChiclet(dx, dy, dz, fillet=0) {
  fillet = fillet? fillet: dy/2;
  union() {
    // Start with the chiclet.
    // Make it taller, then cut off the bottom.
    intersection() {
      moveDown(dy/2)
        moveUp(dz/2)
          chiclet(dx, dy, dz + dy, $fn=30);
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

// A countersunk screw hole cutter.
// Modeled in -Z, with the countersink just above Z=0, centered in X-Y.
// That is, as though you're screwing the screw downward into the X-Y plane.
// Pass the screw hole diameter and height, the diameter of the (usually flat) screw head,
// and the depth of the countersink.
// The default head diameter is twice the hole width.
// The default countersink depth is half the hole diameter.
// If clearance is specified, it's the height of an additional cutter
// designed to give access to the screw head.
module screwHole(diameter, height, head_d=0, sink_depth=0, clearance=0) {
  head_d = head_d? head_d: diameter * 2;
  sink_depth = sink_depth? sink_depth: diameter / 2;
  nudgeUp()
    // Easier to model the whole thing upside down, then flip.
    flipOver()
    union() {
      // Hole
      cylinder(d=diameter, h=height + 2*EPSILON);

      // Countersink
      moveDown(sink_depth) {
        cylinder(d1=head_d, d2=diameter, h=sink_depth + EPSILON);

        // Clearance
        if (clearance) {
          moveDown(clearance - EPSILON)
            cylinder(d1=head_d * 2, d2=head_d, h=clearance + EPSILON);
        }
      }
    }
}
