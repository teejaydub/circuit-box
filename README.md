# circuit-box
Modular enclosure for electronics, for 3D-printing, using OpenSCAD.

Requires [tjw-scad](https://github.com/teejaydub/tjw-scad) in a subdirectory.

## Usage

Clone a new copy of this project for each box you want to make - you'll need to
modify a bunch of things in-place.

Customize `final_box.scad`.  Then run `build.bat` to generate STL files,
or `clean.bat` to remove them all.

A plain box with no customization for electronics is in `slide_panel_box.scad`.

Additional primitives for use with electronics are in `circuit_box.scad`.

You can use either of these modules directly, instead of customizing `final_box.scad`.

## Pushbuttons

There is an extensive module for attaching buttons to enclosures in `pushbutton.scad`.
It has a lot of tools for taking tactile pushbuttons and making everything else
necessary to make them accessible outside an enclosure.
