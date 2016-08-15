import os
import string
import re
import subprocess
import pprint
import time
import datetime
import serial
import ConfigParser             # to read ini file
from SCons.Script import *


# this class know how to handle specific ini file options
class Project_OptionsHandler():
    
    def __init__(self):
        # add options for sendv6 'port'
        #AddOption('--sendv6_port',
                  #dest='sendv6_port',
                  #type='string',
                  #nargs=1,
                  #action='store',   
                  #default='USB0',
                  #help='sendv6 connection port')
                  
        
        try:
            file_ini = open('sdccfw_config.ini')
            config = ConfigParser.ConfigParser()
            config.readfp(file_ini)
            #config.get('SendV6', 'port')
            self.config = config
            
        except IOError as (errno, strerror):
            print "I/O warning({0}): {1}".format(errno, strerror) + ' sdccfw_config.ini'
            
            # if no ini was readed, we build ini file, in memory, with default values
            config = ConfigParser.RawConfigParser()
            config.add_section('SendV6')
            config.set('SendV6', 'port', 'USB0')
            self.config = config


class Project_PlatformInfo():
    def Init(self, the_project):
      self.proj = the_project

    def GetUtilFilename(self, strName):
      env = DefaultEnvironment()
      platform = env['PLATFORM']
      
      # for now, even in linux we just use win32 exe file (because someone (valen :) is too lazy to download the source http://www.fourmilab.ch/xd/ and build xd utility )
      # (sure, wine is required)
      if strName == 'xd':
          return self.proj.basedir + 'c_support/tools/xd.exe' 

      if strName == 'sendv6':                   
          if platform == 'win32':
              return os.path.join(self.proj.v6_dir, 'Contributions/Daniel/Linux_tools/sendv6')
          else:                
              return 'sendv6'
          
                       
      if platform == 'win32':
          # in win32 we have all utils in this dir
          util = self.proj.basedir + 'c_support/tools/' + strName
      else:
          # on non win systems, you need to install req. utils
          util = strName
      return util