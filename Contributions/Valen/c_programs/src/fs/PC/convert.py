#!/usr/bin/env python

# Main script.
# 1. Call convertor convert_bin2chunky.py 15 times, with command line params.
# 2. Convertor will output bmp images, append them  to one bmp image.

import os
from PIL import Image

size = (768, 120)             # size of the image to create        
im_all = Image.new('P', size)   # create the image


all_out_files = ""
y_dest = 0
# We need 15 fonts, with colors  1...15
for x in range(1,16):
    out_file = "tmp_" + str(x) + ".bmp"
    all_out_files = all_out_files + out_file + " "
    
    os.system("convert_bin2chunky.py " +
            "--out_pixel=" + str(x) + " " +
            "/home/valen/_1/v6z80p_SVN/V6_SD_card/fonts/philfont.fnt " + 
            out_file)

    im = Image.open(out_file)
    im_all.paste(im, (0,y_dest))
    y_dest = y_dest + 8
    
            
    #print x
im_all.save("myfont.bmp", 'BMP')

# clean tmp files
os.system("rm tmp_*.bmp")


#print all_out_files
#os.system("convert " + all_out_files + "-append  -dither none " +
#            "-type Palette -define png:bit-depth=8  -define png:preserve-colormap  -define png:color-type=Palette " +
#             "tmp_all.png")
#os.system("convert " + "tmp_all.png " + " " + "myfont.bmp ")




