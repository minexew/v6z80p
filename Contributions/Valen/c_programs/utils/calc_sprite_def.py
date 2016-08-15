#!/usr/bin/env python

# This program takes two input files: image file and areas files.

# Image is an image file with sprites.

# Area file is a simple text file, with space separated values.
# Areas define sprite location on image.
# Each area begins on a new line.
# Can be as many areas as you want.
# All values are in pixels.
# - X coord of the area
# - Y coord of the area
# - Width of the area
# For eample:
# 80 48 80
# 80 0  16

# In this example, we have two areas.

# 2015 valen

import re
import PythonMagick



class CalcDefinitionNumber:

    color_transparent = (255, 0, 255)
    number_of_items_in_area = 5

    def  InitList(self):
        self.obj_output_code = Output_C_Code()

        # comprehension used to generate a list
        size = self.img_blocks_width * self.img_blocks_height
        self.blocksList = [0 for i in range(size)]

        # Following this (above code) you have a multi element list and you can write
        # blocksList[i]=something

    def Do(self):
        filename            = '/home/valen/sharedFolder1/v6z80p-code/trunk/Contributions/Valen/c_programs/src/game/data/free_sprites.bmp'
        self.areas_filename = '/home/valen/sharedFolder1/v6z80p-code/trunk/Contributions/Valen/c_programs/src/game/data/sprites_rect.txt'
        self.out_filename   = '/home/valen/sharedFolder1/v6z80p-code/trunk/Contributions/Valen/c_programs/src/game/data/c_code.c'

        self.image = PythonMagick.Image(filename)
        print "Image depth %i"  % self.image.depth()
        print "Color transparent = %i, %i, %i"  %  (self.color_transparent[0], self.color_transparent[1], self.color_transparent[2] )
        
        # print image.classType()

        self.img_blocks_width  = int(self.image.size().width()  / 16)
        self.img_blocks_height = int(self.image.size().height() / 16)
        print 'Image size in blocks %i x %i' % ( self.img_blocks_width, self.img_blocks_height )
        
        self.InitList()
        self.CalcBlocksInfo_BasedOnImageData()

        self.ReadAreasFile()
        self.CalcDefinitions_BasedOnAreasFile()

        


    def ReadAreasFile(self):
        mylist = []
        with open(self.areas_filename) as f:            
            for x in f.readlines():
                # print x
                mystr = x.strip('\n')
                mylist += re.split('\s*', mystr)
        # print mylist
        # exit(1)
        self.areasList = mylist

    def CalcDefinitions_BasedOnAreasFile(self):
        
        self.obj_output_code.Init(self.out_filename)
        self.obj_output_code.Open_File()

        num_areas = len(self.areasList) / self.number_of_items_in_area
        # print num_areas
        for x in range(0, num_areas):
            index = x * self.number_of_items_in_area
            n_area = self.areasList[index + 0]
            x_area = int(self.areasList[index + 1])
            y_area = int(self.areasList[index + 2])
            w_area = int(self.areasList[index + 3])
            h_area = int(self.areasList[index + 4])
            print "Area: %s Rect: %i, %i, %i, %i" % ( n_area, (x_area), (y_area), (w_area), (h_area) )
            definitions = self.CalcDefinitionNumber_BasedOnImageCoordinates(x_area, y_area, w_area)
            # print definitions
            # exit(1)
            
            self.obj_output_code.OutputArea(n_area, x_area, y_area, w_area, h_area, definitions)


    def CalcDefinitionNumber_BasedOnImageCoordinates(self, img_x, img_y, img_width):
        definitions = []

        # convert coord: pixels to blocks  
        block_x = int(img_x / 16)
        block_y = int(img_y / 16)

        last_block_x = (img_x + img_width - 1) / 16
        # print "last block x = %i" % last_block_x
        # for each vertical line of blocks
        for x in range(block_x, last_block_x + 1):
            info = self.GetBlockInfo(x, block_y)            

            if info == 0:  # if block is empty, print a warning
                print "Error: block %i, %i is empty (transparent)! Check x,y and width values of your rect !. You defined rect with an empty block. "  % (
                        x, block_y)
                exit(1)
            else:
                # block is ok (not empty)
                d = info[0]
                definitions += [d]
                print "point %i, %i width %i In block %i, %i and definition number is %i" %    (
                    img_x, img_y, img_width,  x, block_y, d)
        
        return definitions

    def CalcBlocksInfo_BasedOnImageData(self):
        blocks_count = 0

        definition_number = 0
        for x in range(0, self.img_blocks_width):
            for y in range(0, self.img_blocks_height):
                if(self.IsImageBlock_Transparent(x, y) == False):
                    # non-transparent block found
                    info = [definition_number]
                    self.SetBlockInfo(x, y, info)
                    definition_number += 1
            
                blocks_count += 1
                # if blocks_count == 1:
                #     exit()

        print "Total blocks = %i" % blocks_count
        print "Non-transparent blocks = %i" % definition_number


    
    def SetBlockInfo(self, block_x, block_y, info):
        i = block_y * self.img_blocks_width + block_x
        self.blocksList[i] = info
    
    def GetBlockInfo(self, block_x, block_y):
        i = block_y * self.img_blocks_width + block_x
        return self.blocksList[i]


    # Task: Is al pixels in block are transparent ?
    def IsImageBlock_Transparent(self, block_x, block_y):
        # convert coord: blocks to pixels
        img_x = block_x * 16
        img_y = block_y * 16

        pixels_count = 0

        # check all pixels in the block
        for y in range(0, 16):
            for x in range(0, 16):
                color = self.getPixel(img_x + x, img_y + y)
                
                if color != self.color_transparent:
                    # print "Non-transparent"
                    return False
                
                # print "%i, %i, %i" % ( color[0], color[1], color[2] )    
                pixels_count += 1

        # print "Transparent"
        return True

        # print "pixels count = %i" % pixels_count

    def getPixel(self, x, y):
        color = self.image.pixelColor(x, y)
        r = int(color.redQuantum() / 256.0)
        g = int(color.greenQuantum() / 256.0)
        b = int(color.blueQuantum() / 256.0)
        return (r, g, b)


class Output_C_Code:

    

    template = """unsigned short %s_def[] =  { %s };
void InitRect_%s(sprite)
{
    
}

"""

    def Init(self, out_filename):
        self.out_filename = out_filename
    
    def Open_File(self):
        self.out_file = open(self.out_filename, 'w')

    def OutputArea(self, n_area, x_area, y_area, w_area, h_area, definitions):
        f =  self.out_file    
        strDef = ''
        
        for d in definitions:
            # print d
            # print str(d)
            strDef += str(d) + ', '
            # print strDef
        
        f.write(self.template % (n_area, strDef, n_area) )
            



# help(PythonMagick)

# if image.classType == PythonMagick.ClassType.DirectClass:
#     print 'Pixels are literal.'
    
# if image.classType == PythonMagick.ClassType.PseudoClass:
#     print 'Pixels are indexes in palette.'

# if image.depth() != 8:
#     print 'Err: Image depth is not 8.'
#     exit(1)

obj = CalcDefinitionNumber()
obj.Do()