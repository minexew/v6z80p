"bmp to chunky sprites"
-----------------------

Converts a 256 colour windows .bmp format file to raw pixel data in
the form 1 byte = pixel, suitable for direct use in the VxZ80P as
sprite data.

When building up the output file, the source picture is scanned
in blocks 16x16 pixels in size, from top to bottom, left to right
(ie: vertical block slices) So sprite block 0 is taken from 0,0
block 1: 0,16.. block 2: 0,32 etc.. until the bottom of the
image, then source coords go: 16,0, 16,16, 16,32.. etc

You have the option of skipping any 16x16 blocks that contains
nothing but zeroes.


"bmp to chunky tiles_16x16"
---------------------------

Similar to above, except the source image is scanned in 16x16 blocks
from left to right, top to bottom. So tile block 0 starts at 0,0
block 1 at 16,0  block 2 at 32,0 etc


"bmp to chunky tiles_8x8"
-------------------------

As above, except the source image is scanned in 8x8 blocks
from left to right, top to bottom. So tile block 0 starts at 0,0
block 1 at 8,0  block 2 at 16,0 etc


"bmp to raw chunky"
-------------------

Similar to above, except the image is simply scanned in its entirity
from left to right, top to bottom, a pixel at a time (not divided into
blocks).


"bmp to raw planar"
-------------------

This converts 256 colour .bmp format images which are natively in 1 byte = 1
pixel indexed format to linear bitplanes. You can take 1 to 8 bitplanes
from the source picture, but note that no colour scaling is done - upper
colours will just be cropped off. The image is scanned left to right,
top to bottom.

The bitplanes are saved in sequence, all bit zeroes first, hence..

Pixel BYTE    0, 1, 2, 3, 4, 5, 6, 7 
              !  !  !  !  !  !  !  !
Bit select:0  !  !  !  !  !  !  !  !
              V  V  V  V  V  V  V  V 
bitplane bit  7  6  5  4  3  2  1  0  <- Plane 0 Output Byte 0

Pixel BYTE    8, 9, a, b, c, d, e, f
              !  !  !  !  !  !  !  !
Bit select:0  !  !  !  !  !  !  !  !
              V  V  V  V  V  V  V  V 
bitplane bit  7  6  5  4  3  2  1  0  <- Plane 0 Output Byte 1


repeated for all pixels in image.. then next bitplane is made,
if required..

 
Pixel BYTE    0, 1, 2, 3, 4, 5, 6, 7
              !  !  !  !  !  !  !  !
Bit select:1  !  !  !  !  !  !  !  !
              V  V  V  V  V  V  V  V 
bitplane bit  7  6  5  4  3  2  1  0  <- Plane 1 Output Byte 0

Pixel BYTE    8, 9, a, b, c, d, e, f
              !  !  !  !  !  !  !  !
Bit select:1  !  !  !  !  !  !  !  !
              V  V  V  V  V  V  V  V 
bitplane bit  7  6  5  4  3  2  1  0  <- Plane 1 Output Byte 1          


Palettes
--------

The original 24 bit platte colours from the .bmp file are by default
scaled down to 12 bit, padded with 4 zero bits at 15:12 (0000:R4:G4:B4)
and saved as little endian words. You can also save the palette
unscaled in 3 byte groups (Red, Green, Blue.. if you wish)



