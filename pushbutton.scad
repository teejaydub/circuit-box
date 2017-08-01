/* Pushbutton housing.

  Main idea: 

  I want to use nice pushbuttons in my electronic designs.  They should be 
  integrated into the overall enclosure, look nice, and feel nice.  But they
  should also be cheap and easy to print.  Ideally I should not have to buy
  and stock particular hardware - I may need to stock some standard switch
  mechanisms, but this should adapt them to any context.

  High-level requirements:

  1. All parts 3D-printable.  Maybe an exception for one kind of cheap fastener,
  like a standard screw.  But preferably not, to minimize the "Shucks, I want
  to make this today but I don't have time to go to the hardware store" effect.

  2. Allow flexible customization.  Buttons are not a one-size-fits-all part.
  There are lots of variables, detailed below.

  3. The end result has to look and feel roughly as good as a purchased part,
  at least to the extent possible with current 3D printing tech.

  4. Performance has to be very high - if it breaks easily, comes apart,
  blocks button presses, or needs special attention of any kind, I'd rather
  buy the commercial version.

  Glossary:

  - Housing: All the parts added by this project.
  - Switch: The mechanism that makes and breaks contact.
  - Bracket: What holds the switch in place.
  - Cap: What the user sees, touches and presses down.
  - Stem: What delivers the force from the cap to the switch's actuator.
  - Bezel: A part that surrounds the top of the enclosure hole;
    may also help attach the bracket and/or keep the cap in place.
  - Spring: Provides additional compression beyond that provided by the switch.
  - Throw: How far the cap descends from its rest position to "fully pressed."
    - Switch throw: The throw provided by the switch itself.
    - Spring throw: The distance added by the spring - how far you move the cap
      until it touches the switch's actuator.
  - Tactile feedback: The changing resistance that signals the user that the 
    button has made contact.
  - Audible feedback: A sound that signals the user that the button 
    has made contact.

  Initial version requirements:

  - Support the "tactile" PCB-mounted switch, e.g. by Omron.

  - Mount the switch via a bracket, with leads soldered to the switch legs.

  - Support round caps, with a smooth concave top.

  - Use no spring; all the throw comes from the switch.

  - Use no stem; mount the switch just under the cap.

  - Take the thickness of the enclosure surface as a design variable.

  - Don't require any preparation of the enclosure surface other than making
    a round hole.

  - Support cap diameters between 10 - 30 mm.

  - Support a pitch between button instances of 20 mm.

  - Any reasonable depth - say, less than 50 mm below the enclosure surface.

  - The housing must not rattle.  Some play between the cap and the switch
    is acceptable.

  - The housing must not separate or break during normal use, after being
    dropped, or at normal room temperatures.

  - The switch must be removable from the housing for replacement and 
    during development and prototyping.

  - It would be best if the housing could be removable from the enclosure.

  To do:

  - Produce Boolean positive and negative objects for the enclosure and 
    mounting hole, and do whatever nice things we can do if we assume that the 
    enclosure is also 3D printed (e.g., alternate mounting mechanisms).

  - Integrate a spring to take up any clearance space between the cap 
    and the switch.

  - Support more kinds of switches.  E.g., the "snap-action" switch common
    in arcade controls, the "Cherry MX" keyboard switch, and maybe even a 
    3D-printed switch using conductive filament.
      http://www.thingiverse.com/thing:941782

  - Support PCB-mounted tactile switches.  Help place the mounting holes,
    maybe, and provide the other parts further up.  Add a stem to allow
    placement of the PCB any distance into the enclosure.

  - Support tactile switches mounted on a cable - so that you can insert 
    the switch into the holder without desoldering wires if possible 
    (not as important for switches with quick-connect tabs).

  - Support other cap shapes, including other polygons.

  - Support an additional spring (ideally 3D-printed) for when you want a deeper
    throw before encountering the switch's resistance.

  - Support a minimum pitch between button instances of 0.3", which is
    the nominal spacing of tactile switches when mounted on a standard
    breadboard grid.

  - Add room for an LED with two to four leads in all versions.
*/

/* Next tasks:

Threads get tighter as you screw them farther.
Spring?
  Z-shaped extrusion, with a hole in the middle for the switch cap?
  Or, notes on troubleshooting the sizes - what to modify, or what to sand
Constrain so that you can't go smaller than the switch would fit
  Or if you want to, move the switch further down?
Diagnostic/info outputs, constraints, use cases
  Cap D
  Overall D_max - probably the bezel
  Min size driven by tolerances around tactile switch (or other types)
  Size to input as the hole diameter if you really want to dictate button D
*/

use <threads.scad>
include <tjw-scad/arrange.scad>
include <tjw-scad/dfm.scad>
include <tjw-scad/moves.scad>
include <tjw-scad/primitives.scad>

//===================================================================================
// Inputs

// Start with the diameter of the mounting hole, 
// because sometimes you want to use an existing hole,
// or you're constrained by available drill bits.
// For the moment, 1/2 inch is the minimum and nominal size.
MOUNTING_HOLE_D = 1/2 * inch;

// Also customize to the thickness of the enclosure wall.
ENCLOSURE_THICK = 3;

// Adjust for switches with a short or long throw:
// the distance between the top of the cap when pressed and when released.
THROW = 0.4;

// Cap options
CAP_TOP_SQUARE = 1;
CAP_TOP_CHAMFERED = 2;
CAP_TOP_CONCAVE = 3;
CAP_TOP_CONVEX = 4;

CAP_TOP = CAP_TOP_CONCAVE;

// Choose your switch type:
// (only one choice right now)
USE_TACTILE_SWITCH = 1;  // Omron-style breadboard-mountable, 0.1" pitch, four legs

USE_SWITCH = USE_TACTILE_SWITCH;

// Set this if the switch is soldered to a circuit board, and held in place by it.
// The bracket will be generated to sit around the switch, instead of to hold it in place.
PCB_MOUNT = false;
// If that's set, set this to the distance from the inside of the enclosure surface
// to the circuit board.
PCB_TO_TOP = 15.15;

// For tactile switches:
// The height of the built-in cap above the body of the switch.
TACTILE_CAP_Z = 0.9;

// Keep these as they are if your tactile switch is typical.
TACTILE_JUST_TWO_HOLES = 0;  // if you are only running wires to two legs (remove the others)
  // (but it may be hard to remove the other legs cleanly enough)
TACTILE_HAS_FIFTH_LEG = 1;  // the one on the side for orientation - compatible with 4-leggeds
TACTILE_BODY_D = 6;  // assumes they're square, which is the most common type.
TACTILE_BODY_H = 3.8 + FRICTION_FIT;

// For integrating a PCB-mounted LED to shine through the cap.
PCB_LED = true;
// These are suggested values - they can be modified a bit, 
// but it's not guaranteed that the LED will shine into the bracket
// without a light pipe if these are changed.
PCB_LED_OFFSET = 0.175 * inch;  // from center of switch to center of LED.
PCB_LED_DIMS = [2, 1.6, 0.6];  // X, Y, Z

/* Output style */

EXPLODE = 0;  // 0 for normal assembly, 1 for fully exploded

CUTAWAY = true;  // Press Ctrl+keypad 9 for the correct view (and View > Orthographic)

// Set one or more of these to print things.
// Otherwise, you'll get an assembled view.
PRINT_BEZEL = 0;
PRINT_BRACKET = 0;
PRINT_CAP = 0;

PRINT_ANYTHING = (PRINT_BEZEL || PRINT_CAP || PRINT_BRACKET);


//===================================================================================
// Derived constants

// 20 is good for draft, 100 for final
RESOLUTION = PRINT_ANYTHING? 100: 20;
  
$fn=RESOLUTION;


//===================================================================================
// Model parts - positioned for assembly: centered at (x,y) = (0,0), 
// with z = 0 at the top surface of the enclosure.
//
// Bezel part

// Keep the thread pitch as tight as possible, because that minimizes
// the size of everything else.
// Less than this, you start to get poor geometry.
// More, and it should be easier to screw (may need less THREAD_FIT below),
// but the button cap will end up being smaller for the same size mounting hole.
THREAD_PITCH = 5 * NOMINAL_LAYER;

// Angle between the two faces of the thread.
// I.e., twice the overhang angle.
// "Std value for Acme is 29 or for metric lead screw is 30"
// This overhang seems to work OK in this context,
// vs. the usual MAX_OVERHANG_ANGLE from dfm.scad,
// maybe because the size is small, or maybe because it's spirals.
THREAD_OVERHANG_ANGLE = 67.5;
THREAD_ANGLE = 180 - (THREAD_OVERHANG_ANGLE * 2);

// The depth of the thread.
// This is D_maj - D_min in the Wikipedia article:
// https://en.wikipedia.org/wiki/ISO_metric_screw_thread
THREAD_D = THREAD_PITCH * cos(THREAD_ANGLE) * 5/8;

// Bottom of the bezel slides through the mounting hole.
// So, make sure the threads can slide through it.
BEZEL_BOTTOM_D = MOUNTING_HOLE_D - FRICTION_FIT;
BEZEL_BOTTOM_R = BEZEL_BOTTOM_D / 2;

// Set a minimum thickness for the wall that carries the thread.
MIN_WALL = STRONG_FLEX;

// The hole through the middle leaves space for the threads and the wall.
BEZEL_INNER_R = BEZEL_BOTTOM_R - THREAD_D - MIN_WALL;
BEZEL_INNER_D = BEZEL_INNER_R * 2;

// Outer radius of the bezel rim.
// The bezel rim has the minimum horizontal thickness required to grab the enclosure.
BEZEL_RIM_WIDTH = 2.5;

// The height of the bezel cap, scaled to the size of the rim, 
// which I think makes sense because it has a chamfer.
BEZEL_TOP_Z = BEZEL_RIM_WIDTH / 2;

// The bezel outer radius is its inner radius plus the rim.
BEZEL_R = BEZEL_RIM_WIDTH + BEZEL_INNER_R;

// Four threads give a good amount of grip
// without taking too much effort to assemble.
THREAD_OVERLAP = 4 * THREAD_PITCH;

// Same amount of threading on the bracket as there is on the bezel.
BRACKET_THREAD_LEN = THREAD_OVERLAP;

// For a PCB-mounted switch, this is the difference vertically 
// between where the switch would end up using our regular holder 
// and where the PCB places it.
SWITCH_BOTTOM_TO_PANEL_BOTTOM = BRACKET_THREAD_LEN + TACTILE_BODY_H;
PCB_OFFSET = PCB_TO_TOP - SWITCH_BOTTOM_TO_PANEL_BOTTOM + FRICTION_FIT;
echo("PCB-mounted switch adds", PCB_OFFSET);

BEZEL_BOTTOM_H = THREAD_OVERLAP + ENCLOSURE_THICK
  + (PCB_MOUNT? PCB_OFFSET - LOOSE_FIT: 0);

// The height of the whole bezel: rim + threads.
BEZEL_H = BEZEL_TOP_Z + BEZEL_BOTTOM_H;

// The bezel has a retaining ring around the top that captures the cap.
BEZEL_RING_D = 1;
BEZEL_RING_Z = 0.6;

module bezel() {
  difference() {
    union() {
      // Rim
      chamfered_cylinder(h=BEZEL_TOP_Z, r=BEZEL_R);

      // Thread
      moveDown(BEZEL_BOTTOM_H)
        metric_thread(
          diameter=BEZEL_BOTTOM_D, 
          pitch=THREAD_PITCH,
          length=BEZEL_BOTTOM_H,
          angle=THREAD_ANGLE);
    }
    // The inner hole, that the cap sticks through.
    moveDown(BEZEL_BOTTOM_H + EPSILON)
      cylinder(h=EPSILON + BEZEL_H + EPSILON, r=BEZEL_INNER_R - BEZEL_RING_D);
    // The outer hole, that the cap slides along.
    moveDown(BEZEL_BOTTOM_H + EPSILON + BEZEL_RING_Z)
      cylinder(h=EPSILON + BEZEL_H + EPSILON, d=BEZEL_INNER_D);
  }
}


//===================================================================================
/* Switch holder - a subcomponent of the bracket.
  Can come in various styles, grafted onto the bracket nut.
*/

// A switch holder for standard "tactile" switches,
// the breadboardable style, as commonly available from Omron etc.
TACTILE_LEG_D = 3;  // allowance for a leg, in either dimension
TACTILE_CAP_D = 3.45;  // assumes standard

// The holes are cones, not cylinders, to leave more room for wiring.
TACTILE_LEG_D1 = TACTILE_LEG_D * 1.2;

// THe thickness of the floor at the bottom of the holder,
// that keeps the switch from falling out.
// This also takes the force of a button press.
HOLDER_BOTTOM_Z = MIN_WALL;

// The tactile holder's depth below Z=0, i.e. below the bracket nut.
TACTILE_HOLDER_Z = TACTILE_BODY_H + HOLDER_BOTTOM_Z;

// The distance the cap extends above Z=0 when modeled, i.e. above the bracket nut.
TACTILE_HOLDER_CAP_Z = TACTILE_CAP_Z;

// Half the leg cutter height; assume it extends up and down this much from the body bottom,
// and that that's enough to cut all the way through the holder.
TACTILE_LEG_Z2 = TACTILE_HOLDER_Z / 2 + EPSILON;
TACTILE_LEG_Z = 4 * TACTILE_LEG_Z2;

// Dimensions to translate the legs, from the origin.
// Place the longer dimension in X.
TACTILE_LEG_TX = TACTILE_BODY_D / 2 + TACTILE_LEG_D / 3 - EPSILON;
TACTILE_LEG_TY = TACTILE_BODY_D / 2 - TACTILE_LEG_D / 4;

TACTILE_HOOKUP_D = TACTILE_LEG_D * 0.5;

// Constants that take into account which switch we're actually using,
// which for now is just the tactile.
HOLDER_CAP_Z = TACTILE_HOLDER_CAP_Z;
HOLDER_H = TACTILE_HOLDER_Z;

// Oversize the bracket slightly to make the looser fit,
// compensating for non-circularity in the printed model.
// 0.9 seemed good for a 0.5-inch mounting hole, but was sometimes tight.
THREAD_FIT = 1.0;

// Leave that extra slack between the bezel's thread and the bracket's.
BRACKET_INNER_D = BEZEL_BOTTOM_D + THREAD_FIT;
BRACKET_INNER_R = BRACKET_INNER_D / 2;

// Leave at least the minimum wall thickness around the thread.
BRACKET_R = BRACKET_INNER_R + THREAD_D + MIN_WALL;
BRACKET_D = 2 * BRACKET_R;

BRACKET_H = BRACKET_THREAD_LEN + HOLDER_H;

// A rough approximation of the tactile switch, inflated to act as a Boolean cutter.
// Centered in X-Y with Z=0 at the bottom of the body.
// Add more slack in both dimensions around the switch body with 'slack' if needed.
module tactile_switch_cutter(slack=0) {
  union() {
    // The body.
    moveUp((TACTILE_BODY_H + EPSILON) / 2)
      cube([
        TACTILE_BODY_D + SLIDE_FIT + slack,
        TACTILE_BODY_D + SLIDE_FIT + slack, 
        TACTILE_BODY_H + EPSILON],
        center=true);

    // The four legs.
    translate([TACTILE_LEG_TX, TACTILE_LEG_TY, 0])
      cylinder(d1=TACTILE_LEG_D1, d2=TACTILE_LEG_D, h=TACTILE_LEG_Z, center=true);
    translate([TACTILE_LEG_TX, -TACTILE_LEG_TY, 0])
      cylinder(d1=TACTILE_LEG_D1, d2=TACTILE_LEG_D, h=TACTILE_LEG_Z, center=true);
    if (!TACTILE_JUST_TWO_HOLES) {
      translate([-TACTILE_LEG_TX, TACTILE_LEG_TY, 0])
        cylinder(d1=TACTILE_LEG_D1, d2=TACTILE_LEG_D, h=TACTILE_LEG_Z, center=true);
      translate([-TACTILE_LEG_TX, -TACTILE_LEG_TY, 0])
        cylinder(d1=TACTILE_LEG_D1, d2=TACTILE_LEG_D, h=TACTILE_LEG_Z, center=true);
    }

    // The fifth leg, if needed.
    if (TACTILE_HAS_FIFTH_LEG)
      translate([0, TACTILE_LEG_TX, 0])
        cylinder(d=TACTILE_LEG_D, h=TACTILE_LEG_Z, center=true);

    // The hole for the LED, if needed.
    if (PCB_LED)
      translate([0, -PCB_LED_OFFSET])
        cube([PCB_LED_DIMS[0] + FRICTION_FIT, PCB_LED_DIMS[1] + FRICTION_FIT, TACTILE_BODY_H], center=true);
  }
}

// The tactile holder itself, centered in X-Y with its top surface at Z = 0.
module tactile_switch_holder() {
  // Model this as a cylinder with a rough approximation of the switch subtracted.
  moveDown(TACTILE_BODY_H)
    difference() {
      moveDown(HOLDER_BOTTOM_Z)
        cylinder(h=TACTILE_HOLDER_Z - EPSILON, d=BRACKET_D);
      tactile_switch_cutter();
    }
}

// A cover to go over a tactile switch that's mounted on a circuit board.
// It should slip over it (to a loose tolerance) and capture the cap.
module tactile_switch_cover() {
  // The height of the floor of the bracket.
  // The floor now just keeps the cap from escaping.
  floor_dz = max(MIN_THICKNESS_FIRST_LAYER, TACTILE_BODY_H / 2 - SLIDE_FIT);

  // The additional length we need to reach down to the switch where it's mounted
  // on the circuit board.
  moveDown(PCB_OFFSET) {
    pipe(h=PCB_OFFSET, d=BRACKET_D, wall=THREAD_FIT * 1);

    // Model it like the tactile switch holder, but just end it higher.
    moveDown(floor_dz)
      difference() {
        cylinder(h=floor_dz + EPSILON, d=BRACKET_D);
        moveDown(EPSILON)
          tactile_switch_cutter(LOOSE_FIT - SLIDE_FIT);
      }
  }
}


//===================================================================================
// Bracket part

// The whole bracket, centered in X-Y with its top surface at Z = 0.
module bracket() {
  moveDown(BRACKET_THREAD_LEN)
    union() {
      difference() {
        // Outer cylinder
        moveDown(EPSILON)  // so it'll intersect the holder.
          cylinder(h=BRACKET_THREAD_LEN + EPSILON, r=BRACKET_R);
        // Threads
        moveDown(2*EPSILON)
          metric_thread(
            internal=true,
            diameter=BRACKET_INNER_D, 
            pitch=THREAD_PITCH,
            length=EPSILON + BRACKET_THREAD_LEN + 2*EPSILON,
            angle=THREAD_ANGLE);
      }

      if (PCB_MOUNT)
        tactile_switch_cover();
      else
        tactile_switch_holder();
    }
}


//===================================================================================
// Cap part

// The cap needs to slide inside the bezel.
CAP_D = BEZEL_INNER_D - SLIDE_CIRCLE_FIT;
echo("Cap diameter", CAP_D);
CAP_R = CAP_D / 2;

// Let the cap poke up from the bezel - makes it easier to feel.
// Purely aesthetic.
CAP_EXTEND = BEZEL_TOP_Z;

// Call the "neck" the thinner part that sticks out,
// and the "shoulder" the thicker part that slides inside the bezel.
CAP_NECK_Z = BEZEL_RING_Z + CAP_EXTEND;

CAP_NECK_R = CAP_R - BEZEL_RING_D;

// No separate stem or spring at the moment,
// so the cap needs to reach down from the top of the bezel
// to the top of the switch actuator.
CAP_H = BEZEL_H  // to the bottom of the bezel threads = top of holder
  - (PCB_MOUNT? 0: HOLDER_CAP_Z)  // but up from that, because the cap's allowed to stick up.
  - FRICTION_FIT  // compensate for touching faces
  + CAP_EXTEND;  // sticking-out bit

// Position the cap where it would be - this is just for display.
CAP_DEPRESSION = CAP_H  // flush with the top of the enclosure
  - BEZEL_TOP_Z  // flush with top of bezel
  + FRICTION_FIT / 2  // Center it between the top and bottom contact surfaces
  - CAP_EXTEND;  // and then stick out as far as we wanted.

// Measurements for cap styles
CAP_CHAMFER = 0.6;

CAP_CONCAVE_DEPTH = 1;
CAP_CONCAVE_R = CAP_R * 2;
CAP_CONCAVE_D = CAP_CONCAVE_R * 2;

CAP_CONVEX_HEIGHT = CAP_EXTEND - THROW;

// Modeled centered in X-Y, with the bottom of the enclosure at Z=0.
module cap() {
  moveDown(CAP_DEPRESSION)
    union() {
      // Neck, and the chosen top type
      moveUp(CAP_H - CAP_NECK_Z)
        if (CAP_TOP == CAP_TOP_SQUARE)
          cylinder(h=CAP_NECK_Z, r=CAP_NECK_R);
        else if (CAP_TOP == CAP_TOP_CONCAVE)
          difference() {
            chamfered_cylinder(h=CAP_NECK_Z,
              r=CAP_NECK_R,
              chamfer=CAP_CHAMFER);
            moveUp(CAP_CONCAVE_R + CAP_NECK_Z - CAP_CONCAVE_DEPTH + CAP_CHAMFER)
              sphere(r=CAP_CONCAVE_R);
          }
        else if (CAP_TOP == CAP_TOP_CONVEX)
          union() {
            cylinder(h=CAP_NECK_Z - CAP_CONVEX_HEIGHT,
              r=CAP_NECK_R);
            moveUp(CAP_NECK_Z - CAP_CONVEX_HEIGHT - EPSILON)
              spherical_bump(r=CAP_NECK_R, h=CAP_CONVEX_HEIGHT + EPSILON);
          }
        else //if (CAP_TOP == CAP_TOP_CHAMFERED)  // default
          chamfered_cylinder(h=CAP_NECK_Z,
            r=CAP_NECK_R,
            chamfer=CAP_CHAMFER);

      // Shoulder and the rest of the height of the cap; the outer cylinder.
      cylinder(h=CAP_H - CAP_NECK_Z + EPSILON, 
        d1=CAP_D - FRICTION_FIT,
        d2=CAP_D);
    }
}

// Generates a mounting hole for the button, at -Z, centered in X and Y.
module button_mounting_hole() {
  moveDown(ENCLOSURE_THICK + EPSILON)
    cylinder(h=ENCLOSURE_THICK + 2*EPSILON, d=MOUNTING_HOLE_D + FRICTION_FIT);
}

// Generate all parts of the button, for visualization.
// Center in X-Y, and align so Z=0 is at the bottom of the bezel 
// (the surface of the enclosure).
module button_viz(explode=0) {
  // Assembly, either together or exploded.

  // You don't need alpha in exploded view, but it's nice when not exploded.
  ALPHA = 0.5 + (0.5 * explode);

  color("Magenta", ALPHA)
  bezel();

  color("Orange", ALPHA)
  moveDown(explode * 1.5 * BEZEL_H)
    cap();

  color("LightBlue", ALPHA)
  moveDown(explode * 1.5 * (BEZEL_H + CAP_H))
    moveDown(ENCLOSURE_THICK)
      bracket();
}

// Print what needs to be printed.
// If there are multiple things, arrange them nicely.
if (PRINT_ANYTHING) {
  arrangeLine(BRACKET_D + 20) {
    if (PRINT_BEZEL) {
      flipOver()
        moveDown(BEZEL_TOP_Z)
          bezel();
    }

    if (PRINT_BRACKET) {
      moveUp(BRACKET_H)
        bracket();
    }

    if (PRINT_CAP) {
      moveUp(CAP_DEPRESSION)
        cap();
    }
  }

} else {
  difference() {
    button_viz(EXPLODE);

    if (CUTAWAY)
      moveBack(BRACKET_D)
        cube([2*BRACKET_D, 2*BRACKET_D, 2*BRACKET_D], center=true);
  }
}
