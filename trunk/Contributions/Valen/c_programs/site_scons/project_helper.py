#
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

class Project_Helper(object):
#    def __init__(self):
    
    def SetupDirs(self, project):                  
        if 'v6z80pdir' not in os.environ:
            print 'Error: v6z80pdir env var is not set!'
            print '(for example, on my system this var have value  ~/sharedFolder1/v6z80p_code/trunk)'
            exit()
            
            
        project.v6_dir  = os.environ['v6z80pdir']
        project.basedir = os.environ['v6z80pdir'] + '/Contributions/Valen/c_programs/'
        
        if Project_Helper.Is_Target_PC():
            project.base_variant_dir = 'build/pc/c_programs/'
        else:
            project.base_variant_dir = 'build/v6/c_programs/'

    @staticmethod
    def Is_Target_PC():
        return (ARGUMENTS.get('target', 'v6z80p') == 'pc')
    @staticmethod
    def Is_Target_V6Z80P():
        return (Project_Helper.Is_Target_PC() == False)
