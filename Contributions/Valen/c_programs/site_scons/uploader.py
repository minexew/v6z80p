import os
import string
import re
import subprocess
import pprint
import time
import datetime
import serial
# import ConfigParser             # to read ini file
from SCons.Script import *

from  project_helper    import Project_Helper


class Uploader(object):
    # def __init__(self):                      
        #
    def Init(self, the_project):
        self.proj = the_project

    def SetupEnv(self):
        self.proj.env.Append( 
            SENDV6_UTIL = self.proj.v6_dir + '/Contributions/Daniel/Linux_tools/sendv6/' + self.proj.utilFilename_sendv6,
            SENDV6_PORT = self.proj.options_handler.config.get('SendV6', 'port'),
            SLEEP_UTIL  = 'sleep')        

    def Upload(self, upload_target):     #, is_upload_always):
        # Note: Why we need pause a few seconds, between file uploads :
        # when FILERX is writing the last sended 32KB buffer to disk, it may be about 1.5-2 seconds to complete disk write,
        # but (on the side of fast PC), the sendv6 exits immidiatly  and will re-run again, and thus will fail to connect to v6,
        # because on v6 board, FILERX is still in disk write mode (not in listening mode).
        
        port = self.proj.options_handler.config.get('SendV6', 'port')
        if self.Is_SerialPort_CanBeOpened(port):
            upload_command = 'cd ${SOURCE.dir} && $SENDV6_UTIL $SENDV6_PORT ${SOURCE.file}  &&  $SLEEP_UTIL 2'   
        else:
            upload_command = '@@echo WARNING The serial port $SENDV6_PORT is BUSY ! Cant open port.  Cant upload the file. '
            #upload_command = 'echo zzzzzz';
        #upload_command = 'sendv6 S0 $SOURCE'       # (via COM1, 'S0' - part of linux specific name ttyS0 of COM1)
        
        upload = self.proj.env.Alias('upload_' + self.proj.name + '_' + str(upload_target[0]), upload_target, upload_command)
        if 1:        #is_upload_always:
            AlwaysBuild(upload)        
        Project_Helper.SetProgressMessageForNode(upload[0], '------------- Upload file to V6 -------------')
        
        upload2 = self.proj.env.Alias('upload_' + self.proj.name, upload)
        Alias('upload_all', upload)

        
        
    def Is_SerialPort_CanBeOpened(self, port):
        try:    
            ser = serial.Serial()
            ser.port = "/dev/tty"  + port 
            ser.baudrate = 115200 
            ser.open()
            ser.close()
            return True
        except serial.SerialException:
            return False        