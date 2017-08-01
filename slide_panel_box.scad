/* Sliding Panel Box
   =================

  A general-purpose box.

  Features:
    - Customizable by inner dimensions and panel thickness.
    - All sides slide into the bottom frame.
    - The box is held together securely with printed snap pins.

  Advantages:
    - The top can be removed and replaced without tools (maybe a little prying).
    - No fasteners are visible on the outside of the enclosure.
    - You can do detailed work inside the box easily by removing panels.
    - You can replace panels easily if they're damaged or if you're
      iterating over a design.

  Features or bugs, depending on your viewpoint:
    - Each face of the box prints as a separate panel, so if a print fails, 
      or while developing cutouts, you can replace just that panel.
    - Panels are printed face-down, so if you like the qualities imparted
      by your print surface (if it's pleasantly glossy, e.g.) you can have
      that surface on all sides of the box.

  Usage:
    Set values in the "main inputs" section below.

    use <slide_panel_box.scad>;

    Use the generation functions, like spb_frontPanel(), to generate the parts.

    Customize those parts as needed - e.g., by cutting holes out of them.

    Then pass the results to the transformation functions, like spb_print_frontPanel()
    or spb_assemble_frontPanel(), to output them in printing orientation or
    to view the final assembly.

    Also see an example of the spb_assembly() function calling at the end of this file.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;
use <pin2.scad>;


//===================================================================================
// Control rendered output, if you're processing this script as is instead of 'using' it.

RENDER_ALL = 0;
RENDER_ALL_BUT_TOP = 1;
RENDER_SIDE = 2;
RENDER_SIDE_TEST = 2.5;
RENDER_BOTTOM = 3;
RENDER_BOTTOM_TEST = 3.5;
RENDER_TOP = 4;
RENDER_TOP_TEST = 4.5;
RENDER_FRONT = 5;
RENDER_PINS = 7;
RENDER_PRINT_ALL = 8;  // all on one plate?!

RENDER = RENDER_PRINT_ALL;

// Set this to separate the component parts, during RENDER_ALL.
EXPLODE = 0;
// EXPLODE = 30;

// Make this available for use in calling modules.
function spb_explode() = EXPLODE;

//===================================================================================
// Main inputs to set the size of the box.

// The inner dimensions from wall to wall.
// Note that this is the amount of usable space inside the box,
// EXCEPT for the posts in the corners.
// BOX_INNER_DIMS = [40, 40, 40];  // probably about a minimum workable size.
BOX_INNER_DIMS = [132, 90, 64.5];
function spb_boxInnerDims() = BOX_INNER_DIMS;

// The thickness of the outer walls, as well as the slots.
PANEL_THICK = 3;  // 3 is strong with PLA, 2 is workable.
function spb_panelThick() = PANEL_THICK;

// Radius of the rounded corners.
BOX_RADIUS = 4;


//===================================================================================
// Frame, used for both top and bottom.

BOX_DX = PANEL_THICK + BOX_INNER_DIMS[0] + PANEL_THICK;
BOX_DY = PANEL_THICK + BOX_INNER_DIMS[1] + PANEL_THICK;
BOX_DZ = PANEL_THICK + BOX_INNER_DIMS[2] + PANEL_THICK;

CORNER_POST_D = PANEL_THICK * 5.5;
function spb_cornerPostD() = CORNER_POST_D;
CORNER_POST_OUT = PANEL_THICK * 1.5;
CORNER_POST_R = CORNER_POST_D / 2;

PANEL_THICK_ALLOW = SLIDE_FIT + PANEL_THICK;
POST_TRIM = CORNER_POST_R - PANEL_THICK_ALLOW - PANEL_THICK;
CHANNEL_D = 2 * PANEL_THICK;  // overlap for the channels to grip the slides
PANEL_BITE = CORNER_POST_D + CORNER_POST_OUT - CHANNEL_D;

PIN_LENGTH = 13;
PIN_HOUSING_DZ = PIN_LENGTH + 2;
PIN_HOUSING_D = 10;  // diameter of a post that can solidly hold a pin socket
PIN_HOUSING_OFFSET = PIN_HOUSING_D/2;

// Bottom and most of the frame, modeled centered in X and Y, with its bottom at Z=0.
// If extendZ is specified, enlarge the frame by that much in Z - to make up for the panels
// and the bottom frame being too short by that much.
module spb_frame(boxDz0 = BOX_DZ, extendZ=0) {
  $fn=40;
  boxDz = boxDz0 + extendZ;
  pinReceiveHeight = boxDz;
  adjustZ = 1;  // don't know why!
  panelZ = extendZ - 1;

  difference() {
    union() {
      // Bottom
      cubeOnFloor([BOX_DX, BOX_DY, PANEL_THICK]);

      // Corner posts
      twin_xy() {
        translate([
          BOX_DX / 2 - CORNER_POST_R + CORNER_POST_OUT, 
          BOX_DY / 2 - CORNER_POST_R + CORNER_POST_OUT 
        ]) {
          intersection() {
            difference() {
              cylinder(d=CORNER_POST_D, h=boxDz + PANEL_THICK, $fn=40);

              translate([-PIN_HOUSING_OFFSET, -PIN_HOUSING_OFFSET])
                union() {
                  // Omit what overlaps the lower pin housing.
                  moveUp(PANEL_THICK + pinReceiveHeight - PIN_HOUSING_DZ)
                    cylinder(d=PIN_HOUSING_D, h=2*PIN_HOUSING_DZ + 2*PANEL_THICK + extendZ);

                  // Omit detached crumbs that don't add strength, for PANEL_THICK >= 3.
                  translate([POST_TRIM - PANEL_THICK/2, CORNER_POST_R])
                    turnAround()
                      cube([CORNER_POST_D, CORNER_POST_D, boxDz + 2*PANEL_THICK]);
                  translate([CORNER_POST_R, POST_TRIM - PANEL_THICK/2])
                    turnAround()
                      cube([CORNER_POST_D, CORNER_POST_D, boxDz + 2*PANEL_THICK]);
                }
            }

            // Trim the outside to what's needed for strength and looks.
            translate([-CORNER_POST_D * 1.5 - POST_TRIM, -CORNER_POST_D * 1.5 - POST_TRIM, 0])
              cube([2*CORNER_POST_D, 2*CORNER_POST_D, boxDz + 2*PANEL_THICK]);
          }

          // The column that supports and contains the pin hole,
          // which recieves the pin attaching the top.
          translate([-PIN_HOUSING_OFFSET, -PIN_HOUSING_OFFSET, PANEL_THICK])
            intersection() {
              difference() {
                // The post itself.
                filletedCylinder(h=pinReceiveHeight, d=PIN_HOUSING_D);

                // The hole to receive the pin.
                spin(-45)
                  moveUp(pinReceiveHeight + EPSILON)
                    invert()
                      pinhole(fixed=true);
              }
              // Cut off the portion of the fillet that would collide with the walls.
              translate([-PIN_HOUSING_D/2, -PIN_HOUSING_D/2])
                cubeOnFloor([2*PIN_HOUSING_D, 2*PIN_HOUSING_D, boxDz]);
            }
        }
      }

      // Pads to stiffen where the panels meet the bottom

      moveUp((CHANNEL_D + panelZ)/2 - EPSILON)
        round_frame([BOX_DX - SLIDE_FIT / 2 + 2*PANEL_THICK, 
          BOX_DY - SLIDE_FIT / 2 + 2*PANEL_THICK, 
          CHANNEL_D + panelZ],
          [PANEL_THICK_ALLOW + 2*PANEL_THICK - 2*EPSILON, 
          PANEL_THICK_ALLOW + 2*PANEL_THICK - 2*EPSILON, 0], CORNER_POST_R / 2);
    }

    // Slots for side panels:
    // Left and right panels.
    twin_x() {
      translate([-BOX_DX / 2, -(BOX_DY - PANEL_BITE) / 2, PANEL_THICK + panelZ])
        cube([PANEL_THICK_ALLOW + EPSILON, BOX_DY - PANEL_BITE, BOX_DZ + EPSILON]);
    }
    // Front and back panels.
    twin_y() {
      translate([-(BOX_DX - PANEL_BITE) / 2, -BOX_DY / 2, PANEL_THICK + panelZ])
        cube([BOX_DX - PANEL_BITE, PANEL_THICK_ALLOW + EPSILON, BOX_DZ + EPSILON]);
    }
  }
}


//===================================================================================
// Top and bottom frames.
// The top is as shallow as it can be and still contain the locking pins,
// and the rest of the height goes into the bottom.

// Modeled centered in X-Y, with the bottom facing down,
// and the upper surface of the bottom at Z=0.
module spb_bottomFrame() {
  moveDown(PANEL_THICK)
    spb_frame(BOX_DZ - PIN_HOUSING_DZ - FRICTION_FIT_SINGLE);
}

// Modeled centered in X-Y, with the top facing up at Z=0.
// If extendZ is specified, enlarge the frame by that much in Z.
module spb_topFrame(extendZ=0) {
  flipOver()
    spb_frame(PIN_HOUSING_DZ, extendZ=extendZ);
}

// Transformations

module spb_print_bottomFrame() {
  moveUp(PANEL_THICK)
    children();
}

module spb_print_topFrame() {
  flipOver()
    children();
}

// Assembly location is the same as for printing for the bottom frame.
module spb_assemble_bottomFrame() {
  moveUp(PANEL_THICK)
    children();
}

// The top frame needs to be moved up for assembly.
module spb_assemble_topFrame() {
  moveUp(PANEL_THICK + BOX_DZ + PANEL_THICK)
    children();
}

//===================================================================================
// Side panels - mirror images.

// Returns an array of dimensions for the side panels,
// in the printing orientation.
function spb_sidePanel_dims() = [
  BOX_DY - PANEL_BITE - SLIDE_FIT, 
  BOX_DZ - FRICTION_FIT, 
  PANEL_THICK
];

// Left panel, modeled in printing orientation:
// lying outer face up and centered on the underside of the X-Y plane.
// (For ease in cutting out holes - you're looking down on the outside
// with the surface at Z=0.)
module spb_leftPanel() {
  moveDown(PANEL_THICK)
    cubeOnFloor(spb_sidePanel_dims());
}

module spb_rightPanel() {
  spb_leftPanel();
}

// Print transformations

module spb_print_leftPanel() {
  flipOver()
    children();
}

module spb_print_rightPanel() {
  flipOver()
    children();
}

// Assembly orientations

module spb_assemble_leftPanel() {
  moveLeft((BOX_DX - SLIDE_FIT) / 2)
    moveUp(spb_sidePanel_dims()[1] / 2 + PANEL_THICK + FRICTION_FIT)
      rotate([90, 0, -90])
        children();
}

module spb_assemble_rightPanel() {
  moveRight((BOX_DX - SLIDE_FIT) / 2)
    moveUp(spb_sidePanel_dims()[1] / 2 + PANEL_THICK + FRICTION_FIT)
      rotate([90, 0, 90])
        children();
}


//===================================================================================
// Front and back panels - mirror images.

// Returns an array of dimensions for the side panels,
// in the printing orientation.
function spb_frontPanel_dims() = [
  BOX_DX - PANEL_BITE - SLIDE_FIT, 
  BOX_DZ - FRICTION_FIT, 
  PANEL_THICK
];

// Front panel, modeled in printing orientation:
// lying outer face up and centered on the underside of the X-Y plane.
// (For ease in cutting out holes - you're looking down on the outside
// with the surface at Z=0.)
module spb_frontPanel() {
  moveDown(PANEL_THICK / 2)
    cube(spb_frontPanel_dims(), center=true);
}

// Back panel, same as the front.
module spb_backPanel() {
  spb_frontPanel();
}

// Print the panels face down.
module spb_print_frontPanel() {
  flipOver()
    children();
}

module spb_print_backPanel() {
  spb_print_frontPanel()
    children();
}

module spb_assemble_frontPanel() {
  moveUp(PANEL_THICK + FRICTION_FIT)
    moveUp(spb_frontPanel_dims()[1] / 2)
      moveForward((BOX_DY - SLIDE_FIT) / 2)
        rotate([90, 0, 0])
          children();
}

module spb_assemble_backPanel() {
  turnAround()
    spb_assemble_frontPanel()
      children();
}


//===================================================================================
// Tools to easily place things on side panels.

// Moves its children to the bottom of a side or front panel.
// If offset is specified, moves back that far from the bottom edge of the panel.
module spb_moveToPanelBottom(offset=0) {
  moveForward(spb_sidePanel_dims()[1] / 2 - offset)
    children();
}

// Flips its children to the other side of a panel.
// Uses invert, and moves down to the other side.
module spb_flipPanelSide() {
  moveDown(PANEL_THICK)
    invert()
      children();
}


//===================================================================================
// Final rendering.

// Shows the complete assembly of all parts, optionally exploded.
// Requires all parts to be passed as children, in this order:
// Bottom, left, right, back, front, top.
// This is to allow you to customize the panels while still using this to assemble.
module spb_assembly(explode=EXPLODE) {
  // Bottom
  spb_assemble_bottomFrame()
    children(0);

  // Side panels
  moveLeft(explode)
    spb_assemble_leftPanel()
      children(1);
  moveRight(explode)
    spb_assemble_rightPanel()
      children(2);
  moveBack(explode)
    spb_assemble_backPanel()
      children(3);
  moveForward(explode)
    spb_assemble_frontPanel()
      children(4);

  // Pins
  twin_xy() 
    translate([
      BOX_DX / 2 - CORNER_POST_R + CORNER_POST_OUT - PIN_HOUSING_OFFSET,
      BOX_DY / 2 - CORNER_POST_R + CORNER_POST_OUT - PIN_HOUSING_OFFSET,
      PANEL_THICK + BOX_DZ - PIN_HOUSING_DZ + explode
    ])
      spin(-45)
        rotate([90, 0, 0])
          moveDown(2)
            pinpeg();

  // Top
  color([0, 1, 1, 0.6])
    moveUp(explode * 2)
      spb_assemble_topFrame()
        children(5);
}

if (RENDER == RENDER_SIDE)
  spb_print_leftPanel()
    spb_leftPanel();
else if (RENDER == RENDER_SIDE_TEST)
  trimBack(BOX_DZ * 1.5, 30)
    spb_print_leftPanel()
      spb_leftPanel();
else if (RENDER == RENDER_BOTTOM)
  spb_print_bottomFrame()
    spb_bottomFrame();
else if (RENDER == RENDER_BOTTOM_TEST)
  trimUpper(BOX_DX * 1.5, 34)
    trimRight(BOX_DY * 1.5, -30)
      spb_print_bottomFrame()
        spb_bottomFrame();
else if (RENDER == RENDER_TOP_TEST) {
  moveLeft(40)
    intersection() {
      moveRight(BOX_DX/2)
        spb_print_topFrame()
          spb_topFrame();
      cube([40, HUGE, 40], center=true);
    }
  moveRight(0)
    intersection() {
      moveRight(BOX_DX/2)
        spb_print_bottomFrame()
          spb_bottomFrame();
      cube([40, HUGE, HUGE], center=true);
    }
  moveRight(50) {
    duplicate(2, 25)
      spin(45)
        pinpeg();
  }
} else if (RENDER == RENDER_TOP)
  spb_print_topFrame()
    spb_topFrame();
else if (RENDER == RENDER_FRONT)
  spb_print_frontPanel()
    spb_frontPanel();
else if (RENDER == RENDER_PINS)
  duplicate(4, 30)
    spin(45)
      pinpeg();
else if (RENDER == RENDER_PRINT_ALL) {
  arrange(max(BOX_DX, BOX_DY) + 20) {
    spb_print_bottomFrame()
      spb_bottomFrame();
    spb_print_topFrame()
      spb_topFrame();
    spb_print_backPanel()
      spb_backPanel();
    spb_print_frontPanel()
      spb_frontPanel();
    spb_print_leftPanel()
      spb_leftPanel();
    spb_print_rightPanel()
      spb_rightPanel();
    duplicate(4, 25)
      spin(45)
        pinpeg();
  }
}
else {
  spb_assembly() {
    spb_bottomFrame();
    spb_leftPanel();
    spb_rightPanel();
    spb_backPanel();
    spb_frontPanel();
    if (RENDER != RENDER_ALL_BUT_TOP)
      spb_topFrame();
  }
}
