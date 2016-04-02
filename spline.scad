/* Catmull-Rom splines.
  An easy way to model smooth curve that follows a set of points.
  Do "use <spline.scad>", probably works better than "include".
  Read the module comments below; basic usage is to pass an array of 2D points,
  and specify how many levels of subdivisions you want (more is smoother,
  and each level doubles the number of points) and whether you want a closed loop
  or an open-ended path.

  To do:
    end caps on noodle are cut off, but another function adds hemispheres
    ramen vs. udon
    Examples
      carve out tunnels and/or grooves in a block
      tube/hose function - hollow noodle
      bouquet of bent nails/tubes
      3D spline noodle
      
    make the cross-section a parameter
      and it could be made from a spline
      and it could interpolate (loft) between several splines, twist, scale
    make a version that passes the diameter along with the vector of points
      interpolate it with the same function as you use for the points
    Number the control points in showMarkers()
    lathe a solid = spline_lathe vs. spline_pot
    spiral lathe
    spline surface
    Consider whether the iterative refinement is appropriate
      Is control over "ease" or "tightening" around control points feasible/desirable?

  Spline implementation based on Kit Wallace's smoothing, from:
  http://kitwallace.tumblr.com/post/84772141699/smooth-knots-from-coordinates
  which was in turn from Oskar's notes at:
  http://forum.openscad.org/smooth-3-D-curves-td7766.html
*/

// Makes a 2D shape that connects a series of points on the X-Y plane,
// with the given width.
// If loop is true, connects the ends together.
// If you output this as is, OpenSCAD appears to extrude it linearly by 1 unit,
// centered on Z=0.
module ribbon(path, width=1, loop=false)
{
  union() {
    for (i = [0 : len(path) - (loop? 1 : 2)]) {
      hull() {
        translate(path[i])
          circle(d=width);
        translate(path[(i + 1) % len(path)])
          circle(d=width);
      }
    }
  }
}

// Extrudes a ribbon to the given height.
module wall(path, width=1, height=1, loop=false)
{
  linear_extrude(height)
    ribbon(path, width, loop);
}

// Like a wall, but with a circular cross-section instead of a rectangle.
module noodle(path, diameter=1, loop=false, circle_steps=12)
{
  if (loop) {
    np = loop_extrusion_points(path, circle_points(diameter/2, circle_steps));
    nf = loop_extrusion_faces(len(path), circle_steps);
    polyhedron(points = np, faces = nf);
  } else {
    np = path_extrusion_points(path, circle_points(diameter/2, circle_steps));
    nf = path_extrusion_faces(len(path), circle_steps);
    //echo("path", path);
    //echo("np", np);
    polyhedron(points = np, faces = nf);
  }
}

// Makes a 2D shape that interpolates between the points on the given path,
// with the given width, in the X-Y plane.
module spline_ribbon(path, width=1, subdivisions=4, loop=false)
{
  ribbon(smooth(path, subdivisions, loop), width, loop);
}

// Extrudes a spline ribbon to the given Z height.
module spline_wall(path, width=1, height=1, subdivisions=4, loop=false)
{
  wall(smooth(path, subdivisions, loop), width, height, loop);
}

// Extrudes a spline as a noodle with the given diameter.
module spline_noodle(path, diameter=1, circle_steps=12, subdivisions=4, loop=false)
{
  noodle(smooth(path, subdivisions, loop), diameter, loop, circle_steps);
}

// Makes a lathed 3D shape whose inner edge follows the given path, as 2D points.
// Think of it like making a pot on a potter's wheel, where you want a defined wall thickness
// and you want the pot to follow a given contour.
// 'width' is the width of the "wall of the pot".
// Increase 'subdivisions' (slowly) to get more detail.
// Set 'preview' to show the 2D shape on the X-Y plane, along with inner_targets.
// (Nice if you're trying to fit your shape to measurements of an existing object.)
// Assumes the path is not a loop.
module spline_pot(path, width=1, subdivisions=4, preview=0, inner_targets=[])
{
  if (preview) {
    color("red")
      showMarkers(inner_targets);
    color("blue")
      translate([width/2, 0, 0])
        spline_ribbon(path, width, subdivisions);
  } else {
    rotate_extrude()
      translate([width/2, 0, 0])
        spline_ribbon(path, width, subdivisions);
   }
}

// ==================================================================
// Debugging tools

MARKER_D = 1;
MARKER_R = MARKER_D / 2;

// Shows a list of points as dots on the X-Y plane.
// Places the dots' right edges (+X) at the exact point.
// Probably not useful for modeling, but nice for debugging paths.
module showMarkers(points) {
  for (i = [0 : len(points) - 1]) {
    // Make the markers' right edge coincide
    translate([points[i][0] - MARKER_R, points[i][1], 0])
      rotate(30)
        circle(MARKER_R);
  }
}

// ==================================================================
// Interpolation and path smoothing

weight = [-1, 9, 9, -1] / 16;
weight0 = [6, 11, -1] / 16;
weight2 = [1, 1] / 2;

// Interpolate on an open-ended path, with discontinuity at start and end.
// Returns a point between points i and i+1, weighted.
function interpolateOpen(path, n, i) =
  i == 0? 
    n == 2?
      path[i]     * weight2[0] +
      path[i + 1] * weight2[1]
    :
      path[i]     * weight0[0] +
      path[i + 1] * weight0[1] +
      path[i + 2] * weight0[2]
  : i < n - 2?
    path[i - 1] * weight[0] +
    path[i]     * weight[1] +
    path[i + 1] * weight[2] +
    path[i + 2] * weight[3]
  : i < n - 1?
    path[i - 1] * weight0[2] +
    path[i]     * weight0[1] +
    path[i + 1] * weight0[0]
  : 
    path[i];

// Use this to interpolate for a closed loop.
function interpolateClosed(path, n, i) =
  path[(i + n - 1) % n] * weight[0] +
  path[i]               * weight[1] +
  path[(i + 1) % n]     * weight[2] +
  path[(i + 2) % n]     * weight[3] ;

// Takes an open-ended path of points (any dimensionality), 
// and subdivides the interval between each pair of points from i to the end.
// Returns the new path.
function subdivide(path) =
  let(n = len(path))
  flatten(concat([for (i = [0 : 1 : n-1])
    i < n-1? 
      // Emit the current point and the one halfway between current and next.
      [path[i], interpolateOpen(path, n, i)]
    :
      // We're at the end, so just emit the last point.
      [path[i]]
  ]));

// Takes a closed loop points (any dimensionality), 
// and subdivides the interval between each pair of points from i to the end.
// Returns the new path.
function subdivide_loop(path, i=0) = 
  let(n = len(path))
  flatten(concat([for (i = [0 : 1 : n-1])
    [path[i], interpolateClosed(path, n, i)]
  ]));

// Takes a path of points (any dimensionality),
// and inserts additional points between the points to smooth it.
// Repeats that n times, and returns the result.
// If loop is true, connects the end of the path to the beginning.
function smooth(path, n, loop=false) =
  n == 0
    ? path
    : loop
      ? smooth(subdivide_loop(path), n-1, true)
      : smooth(subdivide(path), n-1, false);

// ==================================================================
// Modeling a noodle
// Mostly from Kris Wallace's knot_functions, modified to remove globals
// and to allow for non-looped paths.

// Given a three-dimensional array of points (or a list of lists of points),
// return a single-dimensional vector with all the data.
function flatten(list) = [ for (i = list, v = i) v ]; 

function m_translate(v) = [ [1, 0, 0, 0],
                            [0, 1, 0, 0],
                            [0, 0, 1, 0],
                            [v.x, v.y, v.z, 1  ] ];
                            
function m_rotate(v) =  [ [1,  0,         0,        0],
                          [0,  cos(v.x),  sin(v.x), 0],
                          [0, -sin(v.x),  cos(v.x), 0],
                          [0,  0,         0,        1] ]
                      * [ [ cos(v.y), 0,  -sin(v.y), 0],
                          [0,         1,  0,        0],
                          [ sin(v.y), 0,  cos(v.y), 0],
                          [0,         0,  0,        1] ]
                      * [ [ cos(v.z),  sin(v.z), 0, 0],
                          [-sin(v.z),  cos(v.z), 0, 0],
                          [ 0,         0,        1, 0],
                          [ 0,         0,        0, 1] ];
                            
function vec3(v) = [v.x, v.y, v.z];
function transform(v, m) = vec3([v.x, v.y, v.z, 1] * m);

// Given a 3D vector v, return a vector that points in the same direction,
// but whose length is 1.
function normalize(v) = 
  let (length = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]))
  [v[0] / length, v[1] / length, v[2] / length];
 
// Given a vector of 3D points, apply the given affine transformation matrix.
// Return the transformed points.
function transform_points(points, matrix) = 
  [for (p = points) transform(p, matrix)];  
         
// Return a 3D transformation matrix to transform a set of points centered at the origin
// with normal in +Z to the given center and normal vector.
function orient_to(centre, normal) =
  m_rotate([0, atan2(sqrt(pow(normal.x, 2) + pow(normal.y, 2)), normal.z), 0]) 
  * m_rotate([0, 0, atan2(normal[1], normal[0])]) 
  * m_translate(centre);

// Returns a normal vector for a face centered at p,
// if you want the face's edge to point halfway between a and b.
// Returns a sane value if two of the points are equal.
function halfway_normal(prev, p, next) =
  let (prev_norm = normalize(p - prev),
    next_norm = normalize(next - p))
  prev == p?
    next_norm
  : next == p?
    prev_norm
  :
    (next_norm + prev_norm) / 2;

// Returns the 3D points lying on a circle with radius r, on the X-Y plane,
// taking the given number of steps around the circumference.
function circle_points(r = 1, steps=12) = 
  let (step = 360/steps)
    [for (a = [0 : 360/steps : 360 - 360/steps])
      [r * sin(a), r * cos(a), 0]
    ];

// Return a list of points used to make an extruded loop.
// loop - the 3D points that make up the loop to extrude along.
// cross_section - the 3D points that make up the loop to use as the cross-section.
function loop_extrusion_points(loop, cross_section) = 
  let (n = len(loop))
    flatten([for (i = [0 : 1 : n - 1])
      let (prev_pt = loop[(i + n - 1) % n],
        this_pt = loop[i],
        next_pt = loop[(i + 1) % n]
      )
        transform_points(cross_section, 
          orient_to(loop[i], halfway_normal(prev_pt, loop[i], next_pt)))
    ]);

// Return a list of indices that make up one segment's worth of faces
// in an extruded loop.
function loop_extrusion_segment_faces(segs, sides, s) =
  [for (i = [0 : sides-1])
    [s * sides + i, 
      s * sides + (i + 1) % sides, 
      ((s + 1) % segs) * sides + (i + 1) % sides, 
      ((s + 1) % segs) * sides + i
    ]
  ];
                       
// Return a list of all the faces in an entire extruded loop.
// segs - number of segments in the extrusion loop.
// cross_section_len - number of points in the cross_section loop.
function loop_extrusion_faces(segs, cross_section_len) = 
  flatten([for (s = [0 : segs-1])
    loop_extrusion_segment_faces(segs, cross_section_len, s)
  ]);

// Return a list of points used to make an extruded open-ended path.
// path - the 3D points that make up the path to extrude along.
// cross_section - the 3D points that make up the loop to use as the cross-section.
function path_extrusion_points(loop, cross_section) = 
  let (n = len(loop))
    flatten([for (i = [0 : 1 : n - 1])
      let (prev_pt = loop[max(0, i - 1)],
        this_pt = loop[i],
        next_pt = loop[min(n - 1, i + 1)]
      )
        transform_points(cross_section, 
          orient_to(loop[i], halfway_normal(prev_pt, loop[i], next_pt)))
    ]);

// Return a list of all the faces in an extruded open-ended path.
// segs - number of segments in the extrusion path.
// cross_section_len - number of points in the cross_section loop.
function path_extrusion_faces(segs, cross_section_len) = 
  flatten(concat([[[for (i = [cross_section_len-1 : -1 : 0]) i]]],
    [for (s = [0 : segs-2])
      loop_extrusion_segment_faces(segs, cross_section_len, s)],
    [[[for (i = [0 : cross_section_len-1]) (segs-1) * cross_section_len + i]]])
  );

// ==================================================================
// Examples, doubling as unit tests.
// Do 'use <spline.scad>' to avoid inserting these.

TEST_SPACING = 5;

module SeparateChildren(space) {
  for (i = [0 : 1 : $children-1])
    translate([i * space, 0, 0]) {
      children(i);
      //translate([-1, -4, 0]) scale(0.2) text(str(i+1));
    }
}
  
path_2D = [[-1, -1], [1, -1], [2, 1], [-1, 2], [0, 0]];
segment_3D = [[-1, -1, 0], [1, 1, 0]];
path_flat = [[-1, -1, 0], [0, 0, 0], [-3, 0, 0]];
sharp_path_3D = [[0, 0, 0], [-1, 1, 0], [-1, -1, 0]];
path_3D = [[-1, -1, 0], [1, -1, 0], [2, 1, 0], [-1, 2, 0], [0, 0, 0]];

// Test the functions.
echo("flatten()", flatten([[[1, 1], [10, 10]], [2, 3, 4], [5, 6]]));

pep1 = loop_extrusion_points(path_flat, circle_points(1, 12));
echo("pep1", pep1);

echo("subdivide(segment_3D)", subdivide(segment_3D));

echo("normalize", normalize([1, 1, 1]));
echo("halfway_normal", halfway_normal([0,0,0], [1,0,0], [0,1,0]));

// Column labels
for (i = [0 : 1 : 6])
  translate([-1 + TEST_SPACING * i, -4, 0])
    linear_extrude(height=0.25)
      scale(0.2)
        text(str(i+1));

// Zero-th row, below the numbers: support functions
cp = circle_points(steps=12);
translate([0, -6, 0])
  // #1: Test circle_points()
  linear_extrude(1) 
    polygon([for (p = cp) [p[0], p[1]] ]);

// First row: loops
SeparateChildren(TEST_SPACING) {

  // #1: Test ribbon(loop)
  linear_extrude(height=4, twist=90, slices=20)
    ribbon(path_2D, width=1/2, loop=true, $fn=16);

  // #2: Test spline_ribbon(loop)
  linear_extrude(height=4, twist=90, slices=20)
    spline_ribbon(path_2D, width=1/2, loop=true, $fn=16);

  // #3: Test wall(loop)
  wall(path_2D, loop=true, width=1/2, height=2, $fn=16);

  // #4: Test spline_wall(loop)
  spline_wall(path_2D, loop=true, width=1/2, height=2, $fn=16);

  // #5: Test noodle(loop)
  noodle(path_3D, loop=true);

  // #6: Test spline_noodle(loop)
  spline_noodle(path_3D, width=1, loop=true, circle_steps=30);

  // #7: A noodle with sharp elbows
  spline_noodle(sharp_path_3D, loop=true);
}

// Second row: open-ended paths
translate([0, TEST_SPACING, 0])
  SeparateChildren(TEST_SPACING) {
    // #1: Test ribbon
    linear_extrude(height=4, twist=-90, slices=20)
      ribbon(path_2D, width=1/2, $fn=16);

    // #2: Test spline_ribbon
    linear_extrude(height=4, twist=90, slices=20)
      spline_ribbon(path_2D, width=1/2, $fn=16);

    // #3: Test wall
    wall(path_2D, width=1/2, height=2, $fn=16);

    // #4: Test spline_wall
    spline_wall(path_2D, width=1/2, height=2, $fn=16);

    // #5: Test noodle
    noodle(path_3D, circle_steps=12);

    // #6: Test spline_noodle
    spline_noodle(path_3D, circle_steps=20);

    // #7: A sharp elbow noodle - not interpolated, helpful for debugging noodle
    noodle(sharp_path_3D);
  }