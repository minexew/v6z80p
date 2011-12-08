#!/usr/bin/env python

#from struct import *
import Image, ImageDraw
import argparse
import pprint

#from pythonmagickwand.image import Image


class Convertor_PlanarPixels_To_ChunkyPixels:

    def __init__(self):
        # user params
        self.is_output_image_horizontal = True
        self.planar_font_height = 8     
        self.planar_font_width = 8
        self.planar_font_chars = 96
        #self.output_pixel_value # set by cmd line args

        # init class vars
        self.image_gen = Convertor_ImageGenerator()
        self.x_dest = 0
        self.y_dest = 0
        self.count_pixels = 0
        self.init_OptParser()

    def ConvertByteToPixels(self, str_byte):
        if(str_byte == ""):
            return False
            
        byte = ord(str_byte[0]) # byte var have type 'int'
        
        mask = 128
        for x in range(1,9):
            if(byte & mask):
                pixel = 1
            else:
                pixel = 0
            
            #print 'mask  = ' + str(mask)
            #print 'pixel = ' + str(pixel)

            self.ComputeImageDestCoord()
            self.image_gen.PutPixelToImage(self.x_dest, self.y_dest, pixel, self.output_pixel_value)
            
            mask = mask >> 1
            self.count_pixels = self.count_pixels + 1
        return True
            

    def Convert(self):
        if self.is_output_image_horizontal:
            im_w = self.planar_font_chars * self.planar_font_width
            im_h = self.planar_font_height
        else:
            im_w = self.planar_font_width
            im_h = self.planar_font_chars * self.planar_font_height
        self.image_gen.CreateImage(im_w, im_h)
        
        #file_planar_font = '/home/valen/_1/v6z80p_SVN/V6_SD_card/fonts/philfont.fnt'
        count_pixels = 0
        with open(self.args.file_planar_font, "rb") as f:
            byte = f.read(1)
            self.ConvertByteToPixels(byte)
            
            while byte != "":
                # Do stuff with byte.
                byte = f.read(1)        
                self.ConvertByteToPixels(byte)                   
        
        print 'count_pixels = ' + str(self.count_pixels)
        self.image_gen.SaveImage(self.args.file_chunky_font)


    def ComputeImageDestCoord(self):
        cur_char      = (self.count_pixels % 768) / 8   
        cur_char_line = self.count_pixels  / 768        

        if self.is_output_image_horizontal:
            self.x_dest = cur_char * 8 + self.count_pixels  % 8            
            self.y_dest = cur_char_line
        else:   
            self.x_dest = self.count_pixels  % 8            
            self.y_dest =  cur_char * 8 + cur_char_line
                
    def init_OptParser(self):
        parser = argparse.ArgumentParser(description='Convert planar font to chunky font.')
        parser.add_argument('file_planar_font', type=str, help='input planar font file')
        parser.add_argument('file_chunky_font', type=str, help='output chunky image, with font')
        parser.add_argument('--out_pixel', type=int, default=255, help='an integer for out pixel color value')

        args = parser.parse_args()
        #pprint.pprint(args)
        self.output_pixel_value = args.out_pixel
        self.parser = parser
        self.args   = args
        #print self.args.file_planar_font

class Convertor_ImageGenerator:
    def CreateImage(self, im_w, im_h):       
        size = (im_w, im_h)             # size of the image to create        
        im = Image.new('P', size) # create the image
        im.putpalette([ 0, 0, 0,
                        255,255,255,
                        0  ,255,255,
                        255,  0,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,
                        255,255,255,])

        
        self.im = im
        
    def PutPixelToImage(self, x, y, pixel_value, out_pixel_value):
        #draw = ImageDraw.Draw(self.im)   # create a drawing object that is
                                # used to draw on the new image
        #red = (255,0,0)    # color of our text
        #text_pos = (10,10) # top-left position of our text
        #text_pos = (x, y)
        #print text_pos
        #text = "Hello World!" # text to draw
        # Now, we'll do the drawing: 
        #draw.text(text_pos, text, fill=red)
        #del draw # I'm done drawing so I don't need this anymore
        
        if pixel_value:
            p = out_pixel_value     #(255,255,255)
        else:
            p = 0                           #(0,0,0)
        self.im.putpixel((x, y), p)
        
    def SaveImage(self, filename):        
        self.im.save(filename, 'BMP')

c = Convertor_PlanarPixels_To_ChunkyPixels()
c.Convert()


#b = unpack('c', byte[0])
#b = ord(byte[0])
#print type(b)
#print int(b[0], 16)
#print type(int('10'))

#print type(b)
#pprint.pprint(  )
