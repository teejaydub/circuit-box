/* rj11 - for mounting a modular 6-position connector,
  of the type commonly used in telephone cable.
  A common panel-mounted jack is designed to slide in a bracket and extend out of the enclosure.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;


PHONE_JACK_HOLE_DX = 0.495 * inch + FRICTION_FIT;
PHONE_JACK_HOLE_DY = 0.45 * inch + FRICTION_FIT;

// Outer dimensions of the jack itself.
PHONE_JACK_DX = 14.8;
PHONE_JACK_DY = 18.3;
PHONE_JACK_SHOULDER_DX = 1.1;  // the first protrusion that sits flush to the wall (included in PHONE_JACK_DX)
PHONE_JACK_SHOULDER_DY = 14.2;
PHONE_JACK_SHOULDER_DZ = 3.52;
PHONE_JACK_SLOT_DZ = 4.1;  // the slot between the two vertical protrusions
PHONE_JACK_TAIL_DX = 8.9;  // the part where the wires come out
PHONE_JACK_TAIL_DY = PHONE_JACK_DY - PHONE_JACK_SHOULDER_DY;
PHONE_JACK_TAIL_DZ = 10.3;

// Outer dimensions of the jack bracket.
PHONE_JACK_BRACKET_DX = PHONE_JACK_DX + SLIDE_FIT + 2 * THICK_WALL;
PHONE_JACK_BRACKET_DY = PHONE_JACK_DY + THICK_WALL;
PHONE_JACK_BRACKET_DZ = PHONE_JACK_SHOULDER_DZ + PHONE_JACK_SLOT_DZ - FRICTION_FIT;

// A cube in -Z, -Y, centered in X.
module alignedCube(dims) {
  moveForward(dims[1] / 2)
    cubeUnderFloor(dims);
}

// Bracket for capturing the jack as it's slid in.
// Must be placed at an edge, and have the hole subracted from the wall in the same place.
// Modeled with the plug entering in the -Z direction, centered in X,
// with the wall edge at Y=0, the plug in -Y, and the surface at Z=0.
module phoneJackBracket() {
  difference() {
    alignedCube([PHONE_JACK_BRACKET_DX, PHONE_JACK_BRACKET_DY, PHONE_JACK_BRACKET_DZ + EPSILON]);
    moveBack(EPSILON)
      moveUp(EPSILON)
        alignedCube([PHONE_JACK_DX + SLIDE_FIT, 
          PHONE_JACK_SHOULDER_DY + FRICTION_FIT + EPSILON, 
          PHONE_JACK_SHOULDER_DZ + FRICTION_FIT + EPSILON]);
    moveBack(EPSILON)
      moveDown(EPSILON)
        alignedCube([PHONE_JACK_DX - 2 * PHONE_JACK_SHOULDER_DX - FRICTION_FIT,
          PHONE_JACK_SHOULDER_DY + SLIDE_FIT + EPSILON,
          PHONE_JACK_BRACKET_DZ + EPSILON]);
    moveBack(EPSILON)
      moveUp(EPSILON)
        alignedCube([PHONE_JACK_TAIL_DX + SLIDE_FIT,
          PHONE_JACK_DY + SLIDE_FIT + EPSILON,
          PHONE_JACK_TAIL_DZ]);
  }
}

// Hole allowing the jack to protrude through the wall.
// Modeled to match the bracket.
module phoneJackHole() {
  moveBack(EPSILON)
    moveUp(EPSILON)
      alignedCube([PHONE_JACK_HOLE_DX, PHONE_JACK_HOLE_DY + EPSILON, PHONE_JACK_TAIL_DZ]);
}
