/* Sampel enclosure, for an Adafruit Perma-Proto 1/2-size board.
  Also illustrates how to add panel-mounted components to the sides,
  by fitting an RJ11 jack on the left panel.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;
use <tjw-scad/spline.scad>;
use <circuit_box.scad>;
use <mounting_ear.scad>;
use <pin2.scad>;
use <rj11.scad>;
use <slide_panel_box.scad>;

RENDER_ALL = 1;
RENDER_LEFT_SIDE = 2;
RENDER_LEFT_SIDE_TEST = 2.5;
RENDER_RIGHT_SIDE = 2.75;
RENDER_BOTTOM = 3;
RENDER_BOTTOM_TEST = 3.5;
RENDER_TOP = 4;
RENDER_TOP_TEST = 4.5;
RENDER_TOP_TEST2 = 4.75;
RENDER_FRONT = 5;
RENDER_BACK = 6;
RENDER_BACK_TEST = 6.5;
RENDER_EXTRAS = 8;

RENDER = RENDER_ALL;

HIDE_TOP = false;

//===================================================================================
// Dimensions that affect multiple parts

PANEL_THICK = spb_sidePanel_dims()[2];

BOX_DX = spb_frontPanel_dims()[0];
BOX_DY = spb_sidePanel_dims()[0];
BOX_DZ = spb_sidePanel_dims()[1];


//===================================================================================
// Bottom frame, to hold the power board and hold the side panels.

MOUNTING_POST_DX = 2.9 * inch;
EAR_NUDGE = 0.5;  // bigger pushes the ears further into the sides of the frame

// Main frame, modeled centered in X and Y, with its bottom at Z=0.
module bottom() {
  union() {
    pcb_bottomFrame(MOUNTING_POST_DX);
    corners([
      spb_boxOuterDims()[0] - 2 * (mountingEarDx() / 2 + spb_cornerPostD()),
      spb_boxOuterDims()[1] + 2 * (PANEL_THICK - SLIDE_FIT - EPSILON) - 2 * EAR_NUDGE,
      -2*PANEL_THICK
    ])
      mountingEar(h=1.5 * PANEL_THICK);
  }
}


//===================================================================================
// Side panels

// Left panel, including the cutout and bracket for the RJ-45 jack.
// Modeled lying outer face up and centered on the underside of the X-Y plane.
module leftPanel() {
  union() {
    difference() {
      spb_leftPanel();

      moveBack(spb_sidePanel_dims()[1] / 2) {
        moveForward(spb_channel_d())
          phoneJackHole();
        // Add another one not-offset, so we can knock it out all the way to the edge.
        phoneJackHole();
      }
    }
    moveBack(spb_sidePanel_dims()[1] / 2)
      moveForward(spb_channel_d())
        moveDown(PANEL_THICK - EPSILON)
          phoneJackBracket();
  }
}

// Right panel is just blank.
module rightPanel() {
  spb_rightPanel();
}


//===================================================================================
// Front and back panels

// Back panel, modeled in SPB panel orientation.
module backPanel() {
  spb_backPanel();
}


//===================================================================================
// Top.
// Modeled in the SPB panel orientation - looking down at the top.

module top() {
  spb_topFrame();
}


//===================================================================================
// Final rendering.

if (RENDER == RENDER_LEFT_SIDE)
  spb_print_leftPanel()
    leftPanel();
else if (RENDER == RENDER_LEFT_SIDE_TEST)
  trimBack(50, 8)
    trimSides(50, PHONE_JACK_BRACKET_DX / 2 + PANEL_THICK)
    spb_print_leftPanel()
      leftPanel();
else if (RENDER == RENDER_RIGHT_SIDE)
  spb_print_rightPanel()
    rightPanel();
else if (RENDER == RENDER_BOTTOM)
  spb_print_bottomFrame()
    bottom();
else if (RENDER == RENDER_BOTTOM_TEST)
  trimUpper(180, 50)
    trimRight(130, -25)
      spb_print_bottomFrame() {
        bottom();
      }
else if (RENDER == RENDER_TOP_TEST) {
  // Just one post, top and bottom; RENDER_EXTRAS to get a pin to test with:
  trimBack(HUGE, -BOX_DY/6) {
    moveLeft(40)
      moveRight(BOX_DX/2)
        trimRight(HUGE, -BOX_DX/3)
          spb_print_topFrame()
            top();
    moveRight(0)
      moveRight(BOX_DX/2)
        trimRight(HUGE, -BOX_DX/3)
          spb_print_bottomFrame()
            bottom();
  }
} else if (RENDER == RENDER_TOP_TEST2) {
  // Two posts:
    moveLeft(40)
      moveRight(BOX_DX/2)
        trimRight(HUGE, -BOX_DX/3)
          spb_print_topFrame()
            top();
    moveRight(0)
      moveRight(BOX_DX/2)
        trimRight(HUGE, -BOX_DX/3)
          spb_print_bottomFrame()
            bottom();
} else if (RENDER == RENDER_TOP)
  spb_print_topFrame()
    top();
else if (RENDER == RENDER_FRONT)
  spb_print_frontPanel()
    spb_frontPanel();
else if (RENDER == RENDER_BACK)
  spb_print_backPanel()
    backPanel();
else if (RENDER == RENDER_BACK_TEST) {
  intersection() {
    spb_print_backPanel()
      backPanel();
      moveBack(30)
        cube([30, 80, 30], center=true);  // hole + strain relief
        // cube([20, 30, 30], center=true);  // just hole
  }
} else if (RENDER == RENDER_EXTRAS) {
  // pins
  duplicate(4, 25)  // one at a time is easier though
    spin(45)
      spb_pinpeg();
} else {
  // Compose all objects in their assembly position.
  spb_assembly() {
    bottom();
    turnAround()
      leftPanel();
    rightPanel();
    backPanel();
    spb_frontPanel();
    if (!HIDE_TOP)
      top();
  }
}
