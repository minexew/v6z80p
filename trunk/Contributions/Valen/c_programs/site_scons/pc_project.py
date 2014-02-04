import os
import string
import re
import subprocess
import pprint
import time
import datetime
import serial
from SCons.Script import *

from  project_helper import Project_Helper

class PC_Project(object):
    def __init__(self):
        # call project helper, to setup dirs
        self.project_helper = Project_Helper()
        self.project_helper.SetupDirs(self)
        
    def SetupEnv(self):
        env = Environment()
        # make common settings

        # propagate PATH 
        env['ENV']['PATH'] = os.environ['PATH']
        env['CPPPATH'] =  [self.basedir + 'inc/', '.']        # '.' represent current project dir]
        
        self.env = env
