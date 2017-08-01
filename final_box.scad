/* Enclosure for a sample project, with main board and secondary board, 
  LCD display, buttons, LEDs, power inlet, and two power outlets.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;
use <tjw-scad/spline.scad>;
use <circuit_box.scad>;
use <pin2.scad>;
use <Pushbutton.scad>;
use <slide_panel_box.scad>;

RENDER_ALL = 1;
RENDER_SIDE = 2;
RENDER_SIDE_TEST = 2.5;
RENDER_BOTTOM = 3;
RENDER_BOTTOM_TEST = 3.5;
RENDER_TOP = 4;
RENDER_TOP_TEST = 4.5;
RENDER_TOP_LCD_TEST = 4.75;
RENDER_FRONT = 5;
RENDER_BACK = 6;
RENDER_BACK_TEST = 6.5;
RENDER_BACK_GROMMET = 6.75;
RENDER_BACK_GROMMET_VIZ = 6.85;
RENDER_BALCONY = 7;
RENDER_BALCONY_TEST = 7.5;
RENDER_BALCONY_CABLE_TEST = 7.75;
RENDER_EXTRAS = 8;

RENDER = RENDER_ALL;

HIDE_TOP = false;

//===================================================================================
// Dimensions that affect multiple parts

PANEL_THICK = spb_sidePanel_dims()[2];

BOX_DX = spb_frontPanel_dims()[0];
BOX_DY = spb_sidePanel_dims()[0];
BOX_DZ = spb_sidePanel_dims()[1];

POWER_BOARD_DX = 66.675 - 3.81;  // from Eagle board file
POWER_BOARD_DY = 64.135 - 3.81;
POWER_BOARD_DZ = 35;  // bottom of PCB to top of tallest component

PCB_PARTS_DZ = 17;  // height of the tallest thing on underside of main board.
PCB_DZ = 1.65;  // assumes both PCBs are equally thick
LCD_SOCKET_DZ = 11.25;  // total distance between main & LCD PCBs
BACKLIGHT_DZ = 2.5;  // offset of the backlight sticking out either side of the display

MAIN_BOARD_DZ = PCB_PARTS_DZ + PCB_DZ + LCD_SOCKET_DZ + PCB_DZ + BACKLIGHT_DZ;
echo("main board DZ", MAIN_BOARD_DZ);
echo("main board to top", LCD_SOCKET_DZ + PCB_DZ + BACKLIGHT_DZ + FRICTION_FIT);

BALCONY_Z = pcb_default_mountingPostH() + POWER_BOARD_DZ;
BALCONY_TOP_Z = BALCONY_Z + PANEL_THICK;

MAIN_BOARD_SPACE = BOX_DZ - BALCONY_TOP_Z;  // space available
if (MAIN_BOARD_SPACE < MAIN_BOARD_DZ) {
  echo("Not enough vertical space - increase BOX_INNER_DIMS[2] in slide_panel_box to", spb_boxInnerDims()[2] + MAIN_BOARD_DZ - MAIN_BOARD_SPACE);
} else {
  echo("Space for main board is OK:", MAIN_BOARD_SPACE);
}

// If we've undershot the necessary space, add it in later by extending the top frame.
EXTEND_TOP_Z = MAIN_BOARD_SPACE < MAIN_BOARD_DZ? MAIN_BOARD_DZ - MAIN_BOARD_SPACE: 0;
if (EXTEND_TOP_Z)
  echo("Extending top frame by", EXTEND_TOP_Z);

// Determine whether we want the left and right button holes.
USE_LEFT_EXTERNAL_BUTTON = true;
USE_RIGHT_EXTERNAL_BUTTON = false;

// For the jack for the external button cable - 1/8" phone jack.
BUTTON_JACK_D = 5.9 + SLIDE_CIRCLE_FIT;

//===================================================================================
// Bottom frame, to hold the power board and hold the side panels.

// Main frame, modeled centered in X and Y, with its bottom at Z=0.
module bottom() {
  pcb_bottomFrame(POWER_BOARD_DX, POWER_BOARD_DY, 0, -5, BALCONY_Z);

  if (RENDER == RENDER_ALL)
    color([1, 0, 1, 0.4])
      balcony(BALCONY_Z);
}


//===================================================================================
// "Balcony" panel, to cover up the power board and protect it.

FEED_HOLE_D = 6;
FEED_HOLE_NECK_D = FEED_HOLE_D / 2;

ZIP_TIE_DX = 3;

module balcony() {
  dims = [spb_boxInnerDims()[0], spb_boxInnerDims()[1], spb_panelThick()];

  difference() {
    pcb_balcony(BALCONY_Z);

    // Cut out a hole for the cables to fit through that go between the boards.
    // Put it at the edge, so cables can be routed through it without taking plugs off.
    translate([
      -dims[0] / 2 + LOOSE_FIT - EPSILON, 
      -dims[1] * 0.2, 
      BALCONY_Z + PANEL_THICK / 2
    ])
      // Now offset from the edge.
      moveRight(FEED_HOLE_D / 2 + PANEL_THICK / 2) {
        // The cut to allow cables to be slid in from the side.
        moveLeft(PANEL_THICK)
          cube([FEED_HOLE_D * 1.4 + PANEL_THICK, FEED_HOLE_NECK_D, 2 * PANEL_THICK], center=true);
        translate([PANEL_THICK, -FEED_HOLE_D / 4, -PANEL_THICK]) {
          // The main hole for the cables to pass through.
          cylinder(h=2 * PANEL_THICK, d=FEED_HOLE_D, $fn=25);

          // A second hole for a zip tie.
          moveBack(FEED_HOLE_D * 1.5)
            cubeOnFloor([ZIP_TIE_DX + LOOSE_FIT, FEED_HOLE_NECK_D, 2 * PANEL_THICK]);
        }
      }
  }
}


//===================================================================================
// Side panels - mirror images, with cutout for power outlet.

// Cutout dimensions
POWER_OUT_DX = 22.2 + FRICTION_FIT;
POWER_OUT_DY = 12.2;  // just file this down as needed - we want it tight.

// External dimensions - what shows through the panel
// These are referenced to the final placement orientation.
POWER_OUT_EXT_W = 26;  // width of the face
POWER_OUT_EXT_H = 16;  // height of face

POWER_OUT_THICK = 1.2;  // panel hole depth; datasheet: 1.0 - 1.8

POWER_OUT_BLOCK_DIMS = [
  26,  // across hole - all from data sheet
  12,
  24 - 3.5
];
POWER_OUT_PINS_DIMS = [
  17,
  6,
  33 - 24
];

// Cutout for the snap-in power outlet module.
// Modeled centered in Y, cutting a face at the XY plane, with the hole cutting through Z,
// with the inside of the hole in +Z.
module powerOutletHole() {
  union() {
    difference() {
      cube([POWER_OUT_DX, POWER_OUT_DY, 2*(PANEL_THICK + EPSILON)], center=true);

      // The datasheet has bites taken out of the bottom corners.
      twin_x() {
        translate([POWER_OUT_DX/2, -POWER_OUT_DY/2])
          rotate([0, 0, 45])
            cube([1.5 * sqrt(2), 1.5 * sqrt(2), 3*PANEL_THICK], center=true);
      }
    }

    // We also need to thin out the panel a bit, so the side springs can relax.
    // Do that on the inside of the box.
    moveUp(PANEL_THICK / 2 + POWER_OUT_THICK)
      cube([
        POWER_OUT_DX + 2 * PANEL_THICK, 
        POWER_OUT_DY, 
        PANEL_THICK], 
        center=true);
  }
}

// Left panel, modeled in its assembly orientation, centered in Y, 
// outer face at the X axis facing left, at actual offset in Z.
module leftPanel() {
  difference() {
    spb_leftPanel();
      spb_moveToPanelBottom(POWER_OUT_EXT_H/2 + 3 * PANEL_THICK) {
        invert() {
          powerOutletHole();

          // Add a rough outline of the power outlet, for visualization.
          if (RENDER == RENDER_ALL) {
            %cubeOnFloor(POWER_OUT_BLOCK_DIMS);
            moveUp(POWER_OUT_BLOCK_DIMS[2])
              %cubeOnFloor(POWER_OUT_PINS_DIMS);
          }
        }
      }
  }
}

module rightPanel() {
  leftPanel();
}


//===================================================================================
// Front and back panels
// Mirror images, before cutouts in the back for power and external button cables.

ZIP_CORD_X = 6;
ZIP_CORD_Y = 3.2;

GROMMET_MARGIN = 1;
GROMMET_COMPRESSION = 1;  // % you can compress the material down - 1 if you can't
GROMMET_UNCOMPRESSED = GROMMET_MARGIN / GROMMET_COMPRESSION;
GROMMET_X = ZIP_CORD_X / 2;
GROMMET_Y = ZIP_CORD_Y / 2;
GROMMET_THICK = GROMMET_UNCOMPRESSED;
GROMMET_LIP = 1.2;
GROMMET_GAP = 0.9;

// Generates a shape to print in flexible filament and insert in a rectangular hole.
// Specify the dimensions of the hole (x, y, and thick), 
// the inner dimension of the gasket (between the hole and the contained object),
// and the amount of 45-degree 'lip' to extend outside it.
module gasketRect(x, y, thick, wall, lip) {
  x2 = x / 2 - wall / 2 * 1;
  y2 = y / 2 - wall / 2 * 0.8; 
  w2 = wall / 2;
  t2 = thick / 2;
  backExtra = lip;  // tall version
  // backExtra = thick * 0.25;  // (nearly-)flush version

  noodle(smooth([
    [GROMMET_GAP / 2, y2, 0],
    [x2, y2, 0],
    [x2, -y2, 0],
    [-x2, -y2, 0],
    [-x2, y2, 0],
    [-GROMMET_GAP / 2, y2, 0]
  ], n=4, loop=false), [
    [-(t2 + lip), wall, 0],
    [-t2, wall + lip, 0],
    [-t2, wall, 0],
    [t2, wall, 0],
    [t2 + backExtra, wall, 0],  // where the old lip was: Y = wall + lip
    [t2 + backExtra, 0, 0],
    [-(t2 + backExtra), 0, 0]
  ]);
}

// A hole just big enough to let a 2-wire 18 AWG zip cord pass.
// modeled centered on the origin, with the hole in -Z.
// Pass additional amounts to be added around the edges in margins [x, y].
module zipCordHole(margins=[0,0]) {
  moveDown(PANEL_THICK * 1.5)
    chamfered_frame([ZIP_CORD_X, ZIP_CORD_Y, 0] + 2*margins, [0, 0, 2*PANEL_THICK], 
      radius=1, top=true, body=false);
}

// The cord - just for visualization purposes.
module zipCord() {
  moveDown(3 * PANEL_THICK)
    chamfered_frame([ZIP_CORD_X, ZIP_CORD_Y, 0], [0, 0, 6*PANEL_THICK], 
      radius=1, top=true, body=false);
}

// Generate the grommet, positioned to insert centered in the panel,
// in the modeling orientation for SPB panels.
module zipCordGrommet() {
  moveDown(PANEL_THICK / 2)
    gasketRect(ZIP_CORD_X, ZIP_CORD_Y, PANEL_THICK,
      GROMMET_THICK, GROMMET_LIP);
}

// A shape like a hurdle or gymnastic vault - an arch with a flat top.
// Modeled sitting on the X-Y plane, centered, so you jump over it in Z.
// BAR_THICK is in both Y and Z.
module hurdle(holeX, holeZ, barThick) {
  difference() {
    filletedChiclet(holeX + 2 * barThick, barThick, holeZ + barThick);
    moveDown(EPSILON)
      cubeOnFloor([holeX, 2 * barThick, holeZ]);
  }
}

// The hole for mounting the jack to receive the cable for mounting an external button.
// Modeled to be subtracted from the panel, in +X; mirror it for -X.
module external_button_jack_hole() {
  // Place them above the balcony.
  jack_z = BALCONY_TOP_Z + 3 * PANEL_THICK + BUTTON_JACK_D / 2;
  translate([BOX_DX / 4, jack_z - BOX_DY / 2, -PANEL_THICK - EPSILON])
    cylinder(h=PANEL_THICK + 2*EPSILON, d=BUTTON_JACK_D, $fn=30);
}

STRAIN_RELIEF_THICK = 2 * PANEL_THICK;
ZIP_CORD_ENTRY_HEIGHT = PANEL_THICK + ZIP_CORD_Y + ZIP_CORD_Y;

// Back panel, modeled in SPB panel orientation.
module backPanel() {
  union() {
    difference() {
      spb_backPanel();

      // Add the hole to admit the line cord.
      spb_moveToPanelBottom(ZIP_CORD_ENTRY_HEIGHT)
        zipCordHole([GROMMET_MARGIN, GROMMET_MARGIN]);

      // Remove holes for mounting remote button jacks.
      if (USE_LEFT_EXTERNAL_BUTTON)
        external_button_jack_hole();
      if (USE_RIGHT_EXTERNAL_BUTTON)
        mirror([1, 0, 0])
          external_button_jack_hole();
    }

    // Add the "hurdle" for strain relief for the line cord.
    moveDown(PANEL_THICK - EPSILON)
      invert()
        spb_moveToPanelBottom(ZIP_CORD_ENTRY_HEIGHT * 3)
          moveDown(EPSILON)
            hurdle(ZIP_CORD_X + SLIDE_FIT, ZIP_CORD_Y + SLIDE_FIT, STRAIN_RELIEF_THICK);
  }

  // Add the grommet, but just when we're displaying the assembly.
  if (RENDER == RENDER_ALL)
    moveUp(spb_explode())
      color([1, 0.9, 0.95, 1])
        spb_moveToPanelBottom(ZIP_CORD_ENTRY_HEIGHT)
          zipCordGrommet();
}


//===================================================================================
// Top.

// Mounting the display and the main board below it.
// These are the dimensions between the mounting posts.
// The mounting posts are centered.
LCD_MOUNT_D = [(3.075 - 0.125) * inch, (2.51 - 1.29) * inch];

// The display bezel's dimensions.
// It's centered between the mounting posts.
LCD_BEZEL_D = [71.4 + SLIDE_FIT, 26.4 + SLIDE_FIT, 2*PANEL_THICK];

// Shift the whole thing up a bit, for aesthetics 
// and to give more space between the buttons and the front lip.
MAIN_BOARD_Y_OFFSET = 5;

// The lid of the box, with cutouts for components and pin housings to connect to the frame.
// Modeled in the SPB panel orientation - looking down at the top.
module top() {
  difference() {
    union() {
      spb_topFrame(EXTEND_TOP_Z);

      // Small spacers to get the LCD back from the backlight.
      moveBack(MAIN_BOARD_Y_OFFSET) {
        corners(LCD_MOUNT_D)
          spb_flipPanelSide()
            pcb_standoff(BACKLIGHT_DZ);
      }
    }

    moveBack(MAIN_BOARD_Y_OFFSET) {
      // Mounting holes for the LCD.
      corners(LCD_MOUNT_D)
        moveDown(PANEL_THICK / 2)
          pcb_tapped_hole(PANEL_THICK / 2);

      // The hole for the LCD bezel.
      moveDown(PANEL_THICK)
        cube(LCD_BEZEL_D + [0, 0, 2*EPSILON], center=true);

      // Mounting holes for pushbuttons.
      moveForward(LCD_MOUNT_D[1] / 2 + 0.69 * inch) {
        button_mounting_hole();  // middle
        twin_x()
          moveRight(0.8 * inch)
            button_mounting_hole();
      }
    }
  }

  // For visualization, show three buttons in place.
  if (RENDER == RENDER_ALL)
    moveBack(MAIN_BOARD_Y_OFFSET)
      moveForward(LCD_MOUNT_D[1] / 2 + 0.69 * inch) {
        button_viz();   
        twin_x()
          moveRight(0.8 * inch)
            button_viz();   
      }
}

// The tapped standoff that sits between the top board and the LCD board.
module top_standoff() {
  pcb_standoff(LCD_SOCKET_DZ);
}


//===================================================================================
// Final rendering.

if (RENDER == RENDER_SIDE)
  spb_print_leftPanel()
    leftPanel();
else if (RENDER == RENDER_SIDE_TEST)
  trimFront(180, -7)
    spb_print_leftPanel()
      leftPanel();
else if (RENDER == RENDER_BOTTOM)
  spb_print_bottomFrame()
    bottom();
else if (RENDER == RENDER_BOTTOM_TEST)
  trimUpper(180, 50)
    trimRight(130, -25)
      spb_print_bottomFrame() {
        bottom();
        #balcony();
      }
else if (RENDER == RENDER_TOP_TEST) {
  moveLeft(40)
    intersection() {
      moveRight(BOX_DX/2) {
        spb_print_topFrame()
          top();
      }
      moveForward(BOX_DY / 2)
        cube([40, 30, BOX_DZ], center=true);
      // cube([40, BOX_DY*2, 40], center=true);
    }
  // moveRight(0)
  //   intersection() {
  //     moveRight(BOX_DX/2)
  //       spb_print_bottomFrame()
  //         bottom();
  //     cube([40, HUGE, HUGE], center=true);
  //   }
  // moveRight(50) {
  //   duplicate(2, 25)
  //     spin(45)
  //       pinpeg();
  // }
} else if (RENDER == RENDER_TOP_LCD_TEST) {
  intersection() {
    spb_print_topFrame()
      top();

    moveDown(EPSILON)
      moveBack(9)
        cube(LCD_BEZEL_D + [20, 42, 20], center=true);
  }
} else if (RENDER == RENDER_TOP)
  spb_print_topFrame()
    top();
else if (RENDER == RENDER_FRONT)
  spb_print_frontPanel()
    spb_frontPanel();
else if (RENDER == RENDER_BACK)
  spb_print_backPanel()
    backPanel();
else if (RENDER == RENDER_BACK_TEST)
  intersection() {
    spb_print_backPanel()
      backPanel();
      moveBack(30)
        cube([30, 80, 30], center=true);  // hole + strain relief
        // cube([20, 30, 30], center=true);  // just hole
  }
else if (RENDER == RENDER_BACK_GROMMET)
  moveUp(PANEL_THICK / 2)
    flipOver()
      zipCordGrommet();
else if (RENDER == RENDER_BACK_GROMMET_VIZ) {
  flipOver() {
    zipCordGrommet();
    color([0, 0, 0, 0.5])
      zipCord();
    color([1, 0, 0, 0.5])
      scale([1, 1, 0.5])
        zipCordHole([GROMMET_MARGIN, GROMMET_MARGIN]);
  }
} else if (RENDER == RENDER_BALCONY) {
  balcony();
} else if (RENDER == RENDER_BALCONY_TEST) {
  intersection() {
    moveDown(BALCONY_Z + PANEL_THICK)
      moveRight(spb_frontPanel_dims()[0] / 2)
        spb_print_bottomFrame()
          balcony();
    cubeOnFloor([33, spb_sidePanel_dims()[0] * 2, 10]);
  }

  moveRight(40)
    trimRight(offset=17)
      moveRight(spb_frontPanel_dims()[0] / 2)
        spb_print_bottomFrame()
          bottom();
} else if (RENDER == RENDER_BALCONY_CABLE_TEST) {
  trimBack()
    trimRight(offset=20)
      moveRight(BOX_DX / 2)
        moveDown(BALCONY_Z)
          balcony();
} else if (RENDER == RENDER_EXTRAS) {
  // pins
  arrange(50) {
    duplicate(4, 25)
      spin(45)
        pinpeg();
    duplicate(4, 25)
      top_standoff();
  }
} else {
  // Compose all objects in their assembly position.
  spb_assembly() {
    bottom();
    leftPanel();
    rightPanel();
    backPanel();
    spb_frontPanel();
    if (!HIDE_TOP)
      moveUp(EXTEND_TOP_Z)
        top();
  }
}
