/* Circuit Board Box
   =================

  Additions to the Sliding Panel Box for use as an electronics enclosure.

  Features:
    - Includes circuit board standoffs.

  Advantages:
    - You can assemble electronics in stages and still have access 
      to whatever parts you need.
    - Accommodates multiple circuit boards, even on all faces of the box.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;
use <slide_panel_box.scad>;


//===================================================================================
// Mounting post, for self-tapping screws.
// Matches the screws used on a salvaged socket,
// so may need to remeasure to match a more reproducible part.
// Modeled centered in X and Y, with its bottom at Z=0.

// Dimensions of your favorite mounting hardware.
MOUNTING_SCREW_D = 2.7;  // #4 screw, using a tap.
MOUNTING_SCREW_HEAD_D = 5.4;
MOUNTING_SCREW_HEAD_H = 1.9;  // pan head

// For holes where a screw needs to slip freely.
MOUNTING_SCREW_SLIP_D = 3.3;

MOUNTING_POST_H = 6 + EPSILON;
function pcb_default_mountingPostH() = MOUNTING_POST_H;
STIFF_WIDTH = 1.5;

MOUNTING_POST_D = MOUNTING_SCREW_D + 2 * THICK_WALL;
MOUNTING_POST_R = MOUNTING_POST_D / 2;

// Generates a stiffening fin for the sides of the mounting post.
// Oriented vertically, in +Z and -X, centered in Y, offset from center
// so that it won't overlap the hole.
module mounting_post_fin(height=MOUNTING_POST_H) {
  moveLeft(MOUNTING_POST_R - EPSILON)
    rotate([90, 0, 0])
      right_triangle([MOUNTING_POST_R, height, STIFF_WIDTH], center=true);
}

// A standardized mounting post for PCBs.
// The default height is good for getting most boards off the floor
// and allowing wires to be routed underneath, but you can customize it.
module mounting_post(height=MOUNTING_POST_H) {
  rotate(45)
    moveDown(EPSILON)
      difference() {
        union() {
          filletedCylinder(h=height, d=MOUNTING_POST_D, 
            fillet=MOUNTING_POST_D/4, $fn=30);

          // Add stiffening fins.
          for (i = [0: 3]) {
            spin(i * 90)
              mounting_post_fin(height);
          }
        }
        // Subtract out the screw hole.
        moveUp(height * 0.25)
          cylinder(h=height, d=MOUNTING_SCREW_D, $fn=30);
      }
}

// A cylindrical standoff, for tapping and attaching with screws at either end.
// Generally for spacing two boards apart from one another.
// Generated centered on the floor (+Z).
module pcb_standoff(height=MOUNTING_POST_H, hole_d=MOUNTING_SCREW_D) {
  difference() {
    cylinder(h=height, d=MOUNTING_POST_D, $fn=30);
    moveDown(EPSILON)
      cylinder(h=height + 2*EPSILON, d=hole_d, $fn=30);
  }
}

// A panel-mounting hole for a screw, sized so it can be tapped.
module pcb_tapped_hole(height) {
  moveDown(height + EPSILON)
    cylinder(h=height + 2*EPSILON, d=MOUNTING_SCREW_D, $fn=30);
}

// A panel-mounting hole for a screw, non-threaded so the screw can slip.
module pcb_screw_hole(height) {
  moveDown(height + EPSILON)
    cylinder(h=height + 2*EPSILON, d=MOUNTING_SCREW_SLIP_D, $fn=30);
}

// A cylindrical spacer, like a standoff but with an untapped hole
// that a screw can slide through.
module pcb_spacer(height) {
  pcb_standoff(height=height, hole_d=MOUNTING_SCREW_SLIP_D);
}

// A panel-mounting hole for a countersunk pan-head screw.
module pcb_pan_head_hole(height) {
  union() {
    pcb_screw_hole(height);

    // countersink
    moveDown(MOUNTING_SCREW_HEAD_H)
      cylinder(h=MOUNTING_SCREW_HEAD_H + EPSILON, 
        d=MOUNTING_SCREW_HEAD_D + SLIDE_FIT, $fn=20);
  }
}

//===================================================================================
// Sliding Panel Box parts

BALCONY_INSET = spb_panelThick() + spb_cornerPostD() / 2 + MOUNTING_POST_D / 2;
BALCONY_MOUNT_X = spb_boxInnerDims()[0] - 2 * BALCONY_INSET;
BALCONY_MOUNT_Y = spb_boxInnerDims()[1] - 2 * BALCONY_INSET;

CORNER_INSET = spb_panelThick();

// Generates a Sliding Panel Box-compatible bottom frame
// with mounting posts for a PCB at the given distances from one another.
// They're centered in X-Y, but with the given translation (tx, ty).
// If either X or Y is omitted, only two mounting posts are generated.
// If 'balcony' is specified, it's the height above the top of the mounting posts
// at which to put the bottom of a second panel, which will have supports on this frame.
module pcb_bottomFrame(dx=0, dy=0, tx=0, ty=0, balcony=0) {
  union() {
    spb_bottomFrame();
    moveDown(EPSILON)
      corners([dx, dy], [tx, ty])
        mounting_post();

    if (balcony) {
      // Mounting posts for the balcony.
      corners([BALCONY_MOUNT_X, BALCONY_MOUNT_Y])
        mounting_post(height=balcony);

      // Connect their fins to the corner posts for strength.
      corners([
        BALCONY_MOUNT_X + BALCONY_INSET / 2, 
        BALCONY_MOUNT_Y + BALCONY_INSET / 2
      ])
        rotate(45)
          cubeOnFloor([MOUNTING_POST_D, STIFF_WIDTH, balcony * 0.9]);
    }
  }
}

// Generates the balcony piece referenced in the previous module.
// Attach with the same screws that are used for the mounting posts.
// Modeled at its height above the bottom.
module pcb_balcony(height) {
  dims = [spb_boxInnerDims()[0], spb_boxInnerDims()[1], spb_panelThick()];
  moveUp(height)
    difference() {
      cubeOnFloor(dims - [2*LOOSE_FIT, 2*LOOSE_FIT, 0]);

      // Cut out the corners so it'll fit around the pin posts.
      twin_xy() {
        translate([
          dims[0] / 2 - CORNER_INSET,
          dims[1] / 2 - CORNER_INSET,
          -EPSILON
        ])
          linear_extrude(height=height + 2*EPSILON)
            chamfered_square([spb_cornerPostD(), spb_cornerPostD()], spb_cornerPostD() / 3);
      }

      // And cut out the screw holes for attaching the balcony to its mounting posts.
      moveUp(spb_panelThick())
        corners([BALCONY_MOUNT_X, BALCONY_MOUNT_Y])
          pcb_screw_hole(spb_panelThick());
    }
}


// Generate various parts, for testing.
arrange(35) {
  mounting_post(35);
  pcb_standoff(20);
}