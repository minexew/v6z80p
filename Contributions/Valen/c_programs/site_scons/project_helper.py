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

dictNodesProgressMessages = {}

class Project_Helper(object):
#    def __init__(self):
    
    def SetupDirs(self, project):                  
        #if 'v6z80pdir' not in os.environ:
        #    print 'Error: v6z80pdir env var is not set!'
        #    print '(for example, on my system this var have value  ~/sharedFolder1/v6z80p_code/trunk)'
        #    exit()
            
        
        # find out the root path of V6Z80P SDK
        original_path = os.getcwd()
        p1 = os.path.dirname(os.path.abspath(__file__))     # p1 for example: /home/valen/sharedFolder1/v6z80p-code/trunk/Contributions/Valen/c_programs/site_scons
        os.chdir(p1 + "/../../../../")
        sdk_root_path = os.getcwd()
        # resore original cwd
        os.chdir(original_path)
        #exit()
            
        project.v6_dir  = sdk_root_path
        project.basedir = sdk_root_path + '/Contributions/Valen/c_programs/'
        
        if Project_Helper.Is_Target_PC():
            project.base_variant_dir = 'build/pc/c_programs/'
        if Project_Helper.Is_Target_IAR_V6Z80P():
            project.base_variant_dir = 'build/iar_v6z80p/c_programs/'
        if Project_Helper.Is_Target_V6Z80P():
            project.base_variant_dir = 'build/v6/c_programs/'
    

    @staticmethod
    def SetProgressMessageForNode(node, message):                  
        #
        global dictNodesProgressMessages
        tmp = {node : message}
        dictNodesProgressMessages = dict( dictNodesProgressMessages.items() + tmp.items() )
      
    @staticmethod
    def GetProgressMessageForNode(node):                  
        #        
        global dictNodesProgressMessages
        # print "Length : %d" % len (dictNodesProgressMessages)

        try:
            str = dictNodesProgressMessages[node]
        except KeyError:
            return ''

        # print 'Fouded key  ======================================================================== '
        # print str

        return str


    
    @staticmethod
    def IsNode_CanBeCheked_ForProgressMessage(node):                  
        #
        if node is None:
            return False

        
        try:
            # if node is already up-to date (node is not building at now), skip node
            if node.is_up_to_date():        
                return False
        except AttributeError:
            # print("Oops!.  Try again.................")
            return False

        return True



    @staticmethod
    def Is_Target_PC():
        return (ARGUMENTS.get('target', 'v6z80p') == 'pc')
    @staticmethod
    def Is_Target_IAR_V6Z80P():
        return (ARGUMENTS.get('target', 'v6z80p') == 'iar_v6z80p')
    @staticmethod
    def Is_Target_V6Z80P():
        return (Project_Helper.Is_Target_PC() == False and Project_Helper.Is_Target_IAR_V6Z80P() == False)





