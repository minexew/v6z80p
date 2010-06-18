
The routine inc/objects_to_sprites.asm simplifies the implementation of
various sized sprites in a game. Each object is built from component
sprites by the use of data structures containing the position of
each component sprite relative to an origin point. Only the origin
point needs to be moved by the host program. 

The code is set up so that top left origin coordinate of the display
window is $100,$100 - the routine handles the X/Y MSBs, clipping etc.

See .asm file for details.
