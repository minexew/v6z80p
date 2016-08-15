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

from  project_helper    import Project_Helper
from  uploader          import Uploader   
from  options_handler   import Project_OptionsHandler, Project_PlatformInfo   

class IAR_V6Z80P_Project(object):
    def __init__(self):                      
        
        

        # call project helper, to setup dirs: v6_dir, basedir, base_variant_dir
        self.project_helper = Project_Helper()
        self.project_helper.SetupDirs(self)
        
        
        self.depend         = IAR_V6Z80P_Project_Dependencies()
        self.depend.Init(self)
        
        self.uploader       = Uploader()
        self.uploader.Init(self)        

        self.platform        = Project_PlatformInfo()
        self.platform.Init(self) 

        self.checker        = IAR_V6Z80P_Project_SystemChecker()

        self.options_handler = Project_OptionsHandler()  
        # self.misc_tools      = V6_Project_MiscTools()
        
        # self.utilFilename_xd     = self.GetUtilFilename('xd')
        self.utilFilename_sendv6 = self.platform.GetUtilFilename('sendv6')


        # register our own progress function
        Progress(progress_function)


    def Init(self):                    
        self.iar_lib_path = self.basedir + 'c_support/iar/lib'

        return True
    
    """This func will be called from SConscript file."""
    def FLOS_Program(self, objs):       
        objs[0].my_progress_message = '------------- Compile user files ---------'
        
        # obj_heap = self.MakeHeapObj()
        # self.obj_proj_info = self.Make_ProjectInfo_Obj()
        # 
        
        #variant_dir =  Dir('.').get_abspath()
        variant_dir =  Dir('.').path    #'src/pong/obj'
        #print ' ======= ' + variant_dir
        
        
        file_ihx = self.env.Program(self.name,             
                    objs + self.obj_iflos + self.misc_lib
                    )
                    
        self.env.Depends(file_ihx, [self.dummy1, self.dummy2])
        self.env.Depends(file_ihx, self.iar_lib_path + '/clz80.r01')

        self.env.Depends(file_ihx, self.obj_iflos)

        self.file_ihx = file_ihx
        # return file_ihx                      
                    # Wee need to link file proj_info.rel, with our .ihx file.
                    # But  we can't just add  proj_info.rel to 'sources' of .ihx file, because proj_info.rel file is 'order-only' dependency.
                    # So, to link it, we will add proj_info.rel to the end of link command line.
                    # (This little trick was described in scons docs.)
                    # LINKCOM = self.env['LINKCOM'] + '  ' + os.path.join(variant_dir, str(self.obj_proj_info[0]))
                                    
        #pprint.pprint(vars(file_ihx))                    
        
        # make order-only dependency, the target should not change in response to changes in the dependent file (doc here http://www.scons.org/doc/production/HTML/scons-user/x1302.html)
        # Requires(file_ihx, self.obj_proj_info)
        
        # convert IHX to BIN
        srec_util = self.platform.GetUtilFilename('srec_cat')
        # srec_util = 'srec_cat'
        
        command1 = srec_util + ' $SOURCE -intel -offset -0x5000   -o $TARGET -binary'
        return self.env.Command(self.name + '.exe', file_ihx, command1)

        
   
    def SetupEnv(self):
        # env = Environment(tools = ['default', 'sdcc', 'sdcclib'])
        env = Environment(tools = ['default', 'iar_iccz80', 'iar_xlink'])

        # make common settings

        # propagate PATH to external commans env
        env['ENV']['PATH'] = os.environ['PATH']


        # iar_root = '/home/valen/Programs/IAR'
        try:
            self.iar_root = os.environ['IAR_C_ROOT']
        except KeyError: 
            print "Error: Please set the environment variable IAR_C_ROOT"
            print '       Example: On Linux machine /home/valen/Programs/IAR'
            # sys.exit(1)
            Exit()

        env['CPPPATH'] =  [self.iar_root + '/z80/inc', self.basedir + 'inc',
                                '.']        # '.' represent current project dir
        env['CPPDEFINES'] = []      # env wide defines (just an empty list)        can be somethisng like [{'MYDEFINEVAR' : 'MYGOODVALUE'}]

        env['PROGSUFFIX'] = '.a01'
        env['OBJSUFFIX'] = '.r01'
        env.Append(CCFLAGS='-v0 -ml -e -K -gA -q -r0i -x')


        
        env.Append(LINKFLAGS='-l ${TARGET}.map')
        env.Append(LINKFLAGS='-x')
        
        # env['LIBS'] =['i_flos_lib', 'stdio_v6z80p_lib', 'base_lib']
        
        # lib1 = Dir(self.basedir + self.base_variant_dir + 'c_support/os_interface_for_c/')
        # lib2 = Dir(self.basedir + self.base_variant_dir + 'c_support/stdio_v6z80p/')
        # lib3 = Dir(self.basedir + self.base_variant_dir + 'c_support/base_lib/')
        # env.Append(LIBPATH=[lib1, lib2, lib3])
                            

        

        
        
        #print env['CC']
        #print env['ENV']['PATH']
        self.env = env
        
        self.uploader.SetupEnv()

        # self.env_pasmo   = self.env.Clone(tools=['pasmo'],      CPPPATH = '')
        self.env_az80 = self.env.Clone(tools=['iar_az80'],    CPPPATH = '')
        self.env_az80.Append(ASFLAGS = '-l ${TARGET}.lst')
        self.env_az80.Append(CPPPATH = [self.basedir + 'inc/', '.'])        # '.' represent current project dir

    # def GetEnv_SDCC(self):
    #     return self.env
        



# this class know, how to build all v6 proj depend. (CRT for FLOS, C FLOS interface, asm FLOS proxy, C libs)
class IAR_V6Z80P_Project_Dependencies():
    
    def Init(self, the_project):
        self.the_project = the_project
        
    
    
    # ------------------------------------------------------------------
    # C runtime (object file)
    def Make_CRT_Obj(self):        
        env_az80 = self.the_project.env_az80
        
        file_src = 'Cstartup.s01'        
        self.obj_crt = env_az80.Object('Cstartup.r01' , file_src)
        self.obj_crt[0].my_progress_message = '------------- Compile Cstartup asm module ---------'
                        
    
        # Command: Replace cstartup module in clz80.r01 library        
        self.the_project.dummy1 = self.Replace_ObjectModule_In_Lib(
                self.obj_crt, 'clz80.r01','put_to_lib')

        
    # OS interface for C  (object files)
    def Make_OS_interface_for_C(self): 
        env = self.the_project.env
        
        all_src_files = Glob('FLOS_.s01')
        # all_src_files = ['FLOS_WaitVRT.c']
        # print all_src_files[0]
        self.the_project.obj_iflos = self.the_project.env_az80.Object( all_src_files, 
                    CCFLAGS     = env['CCFLAGS'] + ['-uua', '-s9'] )

    # putchar  (object files)
    # Note: About a putchar.c
    #       This func, is making  a standard v6z80p putchar.c module, which can print on serial port and/or on FLOS console.
    #       If user dont want it or want its own implementation, just copy putchar.c to your proj dir and compile it with your program.
    def Make_putchar_Obj(self): 
        env = self.the_project.env
        self.obj_putchar = env.Object('putchar.r01' , 'putchar.c',
                    CCFLAGS     = env['CCFLAGS']           + ['-uua', '-s9',
                                                        '',              # -b, make library object module (not a program module)
                                                        '-Hputchar'], )    # -H, specify internal object module name
        
        # Command: Replace putchar module in clz80.r01 library                
        self.the_project.dummy2 = self.Replace_ObjectModule_In_Lib(
                self.obj_putchar, 'clz80.r01','put_to_lib_putchar')

    def Replace_ObjectModule_In_Lib(self, repl_obj, strLibName, strFileName_XLB): 
        env = self.the_project.env

        d1 = self.the_project.iar_lib_path
        f1 = repl_obj[0].abspath
        tempDir =  os.path.dirname(f1)
        
        o_name, o_ext = os.path.splitext(  str(repl_obj[0])  )
        # print o_name        
        # Exit(0)

        command1 = [ Copy(tempDir + "/" + strLibName,                   d1 + '/' + strLibName),
                     Copy(tempDir + "/" + strFileName_XLB + '.xlb',     d1 + '/' + strFileName_XLB + '.xlb'),
                    'xlib.exe ' + strFileName_XLB,
                     Copy(d1 + '/' + strLibName,    tempDir + "/" + strLibName),

                     'echo dummy > ' + o_name + '_dummy',
                     # Delete(d1 + "/Cstartup.r01")                    
                    ]
        dummy = env.Command(o_name + "_dummy", repl_obj , command1, chdir=tempDir)
        dummy[0].my_progress_message = '------------- Replace ' + o_name + ' module in Lib ' + strLibName + ' ---------'
        return dummy


 
class IAR_V6Z80P_Project_SystemChecker():
    
    def Init(self, iar_project):
        self.iar_project = iar_project
        
        if self.Check_IAR() == False:
            return False

        return True
       
        
    def Check_IAR(self):
        # check, if iar is installed in system
        comp =  self.iar_project.env['CC']
        print 'Check for: iar. Executing: ' + comp
        pipe = SCons.Action._subproc(self.iar_project.env, [comp, ''],                                                       
                             stdin = 'devnull',                                                                    
                             stderr = 'devnull',                                                                   
                             stdout = subprocess.PIPE)                                                             
        out,err = pipe.communicate()
        status = pipe.wait()
        # print err
        # print status
        if status < 0:
            print 'Warning: IAR C compiler not found! '
            # print '       Add it to your system PATH var.'
            # return False
                                                                                            
        return True

        # ---------------------------------- TODO: version check                                                                           
        line = pipe.stdout.readline()
                    
        match = re.search(r'[0-9]+(\.[0-9]+)+', line)                                                                      
        if match:                                                                                                          
            #self.v6_project.env['CXXVERSION'] = 
            self.sdcc_version = match.group(0)
        if self.sdcc_version[0] != '3':
            print 'Warn: SDCC 3.3 or later is required!'
            
        
        # revision 
        match = re.search(r'(\#[0-9]+)+', line)                                                                      
        if match:                                                                                                                      
            self.sdcc_revision =  match.group(0)
            
        return True                



			
        

                        
#screen = open('/dev/tty', 'w')
def progress_function(node):
    str_node = str(node)
    #count += 1
    #print('Node %4d: %s\r' % (count, node))
    #pprint.pprint (node)
    
 
    if(Project_Helper.IsNode_CanBeCheked_ForProgressMessage(node) == False):
        return

    mess = Project_Helper.GetProgressMessageForNode(node)
    if(mess != ''):
        print mess
        return


    
    if string.find(str_node, '.exe') >= 0:
        print "------------- IHX to BIN convertion ---------"
        return
    if string.find(str_node, '.a01') >= 0:
        print "------------- Linking project -------------"
        return
        
    if string.find(str_node, 'myheap.rel') >= 0:
        print "---------------- Heap allocation -------------------"
        return
    if string.find(str_node, 'putchar.r01') >= 0:
        print "------------- Compile putchar module ---------"
        return
    if string.find(str_node, 'i_flos.rel') >= 0:
        print "------------- OS interface for C ---------"
        return
    if string.find(str_node, 'flos_proxy_code.rel') >= 0:
        print "------------- FLOS proxy: Compile C code ---------"
        return        

    if string.find(str_node, 'flos.asm.bin') >= 0:
        print "------------- FLOS proxy: Compile asm code to binary ---------"
        return         
    if string.find(str_node, 'flos_proxy_code.c') >= 0:
        print "------------- FLOS proxy: Convert binary to C code ---------"
        return          
        
    

