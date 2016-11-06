/* Quick ways to arrange a bunch of child objects in space.*/

// Arranges all children in a grid, distributed in X, Y, and Z.
// Just specify the outside dimension of any child.
module arrangeSpread(diameter)
{
  root = ceil(sqrt($children));
  translate([
    -diameter * (root - 1) / 2,
    -diameter * (root - 1) / 2,
    -diameter * (ceil($children / root) - 1) / 2.0
  ])
    for (i = [0 : $children-1]) 
    {
      translate([
        diameter * floor(i % root),
        diameter * floor((i + i / root) % root),
        diameter * floor(i / root)
      ])
        child(i);
    }
}

// Duplicate all children n times.
// Adaptively arranges them in a grid, in steps of 'diameter' in X and Y.
module duplicate(n, diameter)
{
  root = ceil(sqrt(n));
  for (j = [0 : $children-1]) {
    for (i = [0: n - 1]) {
      translate([diameter * floor(i / root), diameter * (i % root)])
        children(j);
    }
  }
}

// Duplicate its children, mirrored in X.
// Uses the +X copy as is, and mirrors it for the -X copy.
module twin_x() {
  mirror([1, 0, 0])
    children();
  children();
}

// Duplicate its children, mirrored in +Y and -Y with the given offset.
module twin_y() {
  mirror([0, 1, 0])
    children();
  children();
}

// Duplicate its children similarly, in both x and y.
module twin_xy() {
  twin_x()
    twin_y()
      children();
}