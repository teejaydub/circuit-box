/* Mounting ears - for screwing an enclosure to a wall.
*/

include <tjw-scad/dfm.scad>;
use <tjw-scad/arrange.scad>;
use <tjw-scad/moves.scad>;
use <tjw-scad/primitives.scad>;

// A flat mounting ear, filleted into the wall.
// Dimensions are based on the size of the mounting hole and the height (h).
// Modeled in +Y with the floor at Z=0 and the wall it should sit against at Y = 0.
module mountingEar(hole_d=4, h=4.5) {
  MOUNTING_EAR_DX = 4 * hole_d;
  MOUNTING_EAR_DY = 4 * hole_d;
  MOUNTING_EAR_DZ = h;

  moveBack(MOUNTING_EAR_DY / 2)
    difference() {
      trimLower()
        union() {
          chicletZ(MOUNTING_EAR_DX, MOUNTING_EAR_DY, 2 * MOUNTING_EAR_DZ, $fn=40);
          moveForward(MOUNTING_EAR_DY / 4)
            difference() {
              moveForward(MOUNTING_EAR_DY / 8)
                cube([MOUNTING_EAR_DX + 2 * MOUNTING_EAR_DZ, 
                  MOUNTING_EAR_DY / 4, 
                  2 * MOUNTING_EAR_DZ], 
                  center=true);

              twin_x()
                moveRight(2 * MOUNTING_EAR_DZ + MOUNTING_EAR_DX / 2 - MOUNTING_EAR_DZ)
                  torusHub(MOUNTING_EAR_DZ, 2 * MOUNTING_EAR_DZ, $fn=40);
            }
        }
      moveDown(EPSILON)
        cylinder(d=hole_d, h=MOUNTING_EAR_DZ + 2*EPSILON, $fn=40);
    }
}

mountingEar();