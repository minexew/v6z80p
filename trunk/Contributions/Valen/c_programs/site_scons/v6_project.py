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

class V6_Project(object):
    def __init__(self):                      
        
        # call project helper, to setup dirs: v6_dir, basedir, base_variant_dir
        self.project_helper = Project_Helper()
        self.project_helper.SetupDirs(self)
        #print self.v6_dir
        #print self.basedir 
        #print self.base_variant_dir
        #exit()
        
        
        self.depend          = V6_Project_Dependencies()
        self.depend.Init(self)

        self.uploader        = Uploader()
        self.uploader.Init(self)  

        self.platform        = Project_PlatformInfo()
        self.platform.Init(self)          
        
        self.checker         = V6_Project_SystemChecker()
        self.options_handler = Project_OptionsHandler()  

        self.misc_tools      = V6_Project_MiscTools()
        
        self.utilFilename_xd     = self.platform.GetUtilFilename('xd')
        self.utilFilename_sendv6 = self.platform.GetUtilFilename('sendv6')
        

        # register our own scons progress function
        Progress(progress_function)



    def Init(self):
 
        return True
    
    """This func will be called from SConscript file."""
    def FLOS_Program(self, objs):               
        Project_Helper.SetProgressMessageForNode(objs[0], '------------- Compile user files ---------')
                
        obj_heap = self.MakeHeapObj()
        self.obj_proj_info = self.Make_ProjectInfo_Obj()
        # 
        
        #variant_dir =  Dir('.').get_abspath()
        variant_dir =  Dir('.').path    #'src/pong/obj'
        #print ' ======= ' + variant_dir
        
        # NOTE: CRT object file (crt0_v6z80p) must be first in this sources list!!!
        file_ihx = self.env.Program(self.name , 
                    self.depend.obj_crt +
                    self.depend.obj_iflos +
                    self.depend.obj_flosproxy +
                    obj_heap + objs, LINKFLAGS=self.env['LINKFLAGS'] + self.linkopt,
                      
                    # Wee need to link file proj_info.rel, with our .ihx file.
                    # But  we can't just add  proj_info.rel to 'sources' of .ihx file, because proj_info.rel file is 'order-only' dependency.
                    # So, to link it, we will add proj_info.rel to the end of link command line.
                    # (This little trick was described in scons docs.)
                    LINKCOM = self.env['LINKCOM'] + '  ' + os.path.join(variant_dir, str(self.obj_proj_info[0]))
                                    )
        #pprint.pprint(vars(file_ihx))                    
        
        # make order-only dependency, the target should not change in response to changes in the dependent file (doc here http://www.scons.org/doc/production/HTML/scons-user/x1302.html)
        Requires(file_ihx, self.obj_proj_info)
        
        # convert IHX to BIN
        srec_util = self.platform.GetUtilFilename('srec_cat')
        
        command1 = srec_util + ' $SOURCE -intel -offset -0x5000   -o $TARGET -binary'
        return self.env.Command(self.name + '.exe', file_ihx, command1)         #, "cp $SOURCE $TARGET")
    
    def MakeHeapObj(self):
        file1 = self.basedir + 'c_support/myheap.s'

        subst = Environment(tools = ['textfile'])
        # generate asm file, concatenate another asm file with a string
        heap_size = 1024            # this is default sdcc heap size
        if hasattr(self, 'heapsize'):
            heap_size = self.heapsize
            # print self.name
            # print "heap_size: "
            # print heap_size

        # asm_heap = subst.Textfile(target = 'myheap.s',              
        #                         source = [self.env.File(file1), heap_size], 
        #                         LINESEPARATOR=' ')
        script_dict = {'HEAP_TOTAL_BYTES': heap_size }  # replace string with heap size string
        asm_heap = subst.Substfile(target='myheap.s', source=file1, SUBST_DICT = script_dict)
        

        self.env.Depends(asm_heap, 'SConscript')
        
        # compile asm to obj
        env_sdasz80 = self.env_sdasz80        
        obj_heap = env_sdasz80.Object('myheap' + env_sdasz80['OBJSUFFIX'], asm_heap)     #"cp $SOURCE $TARGET")
        self.heapsize = 1024
        return obj_heap
        #src/$(prjname)/obj/myheap.rel
        
    # generate proj info .c file, it will contain sdcc version, compilation date
    def Make_ProjectInfo_Obj(self):
        env_text = Environment(tools = ['textfile'])
        # generate c file, with some info
        #time_now = time.ctime(time.time())
        date_now = datetime.datetime.now()
        str_date_now = date_now.strftime("%d-%m-%Y")        # %H:%M")
        
        project_info_c_source = env_text.Textfile(target = 'v6_project_info/proj_info.c',              
                                source = ['// project info ', 
                                          'const char projInfo[] = "' 
                                          + 'Info: SDCC ' 
                                          + self.checker.sdcc_version  + '  '
                                          + self.checker.sdcc_revision + '  '
                                          + str_date_now + '" ;    '], 
                                
                                )
            
      
        
        obj_project_info =  self.env.Object(project_info_c_source, 
                                            CCCOMSTR = "Compiling proj info file")
        
        return obj_project_info
   
    def SetupEnv(self):
        env = Environment(tools = ['default', 'sdcc', 'sdcclib'])

        # make common settings

        # propagate PATH to external commans env
        env['ENV']['PATH'] = os.environ['PATH']


        env['CPPPATH'] =  [self.basedir + 'inc/', '.']        # '.' represent current project dir
        env['CPPDEFINES'] = []      # env wide defines (just an empty list)        can be somethisng like [{'MYDEFINEVAR' : 'MYGOODVALUE'}]

        env['PROGSUFFIX'] = '.ihx'
        env['OBJSUFFIX'] = '.rel'
        env.Append(CCFLAGS='-mz80')


        env.Append(LINKFLAGS=['-mz80', '--no-std-crt0' , '-Wl-b_FLOS_PROXY_CODE=0x5080'])
        #env['LINKCOMSTR'] = "Linking $TARGET"
        env['LIBS'] =['i_flos_lib', 'stdio_v6z80p_lib', 'base_lib']
        
        lib1 = Dir(self.basedir + self.base_variant_dir + 'c_support/os_interface_for_c/')
        lib2 = Dir(self.basedir + self.base_variant_dir + 'c_support/stdio_v6z80p/')
        lib3 = Dir(self.basedir + self.base_variant_dir + 'c_support/base_lib/')
        env.Append(LIBPATH=[lib1, lib2, lib3])
                            

        
        #print env['CC']
        #print env['ENV']['PATH']
        self.env = env

        self.uploader.SetupEnv()
        
        self.env_pasmo   = self.env.Clone(tools=['pasmo'],      CPPPATH = '')
        self.env_sdasz80 = self.env.Clone(tools=['sdasz80'],    CPPPATH = '')

    def GetEnv_SDCC(self):
        return self.env
        
            
    def Upload(self, upload_target):
        self.uploader.Upload(upload_target)



# this class know, how to build all v6 proj depend. (CRT for FLOS, C FLOS interface, asm FLOS proxy, C libs)
class V6_Project_Dependencies():
    
    def Init(self, v6_project):
        self.v6_project = v6_project
        
    
    
    # ------------------------------------------------------------------
    # C runtime (object file)
    def Make_CRT_Obj(self):        
        env_sdasz80 = self.v6_project.env_sdasz80
        
        file_src = 'crt0_v6z80p.s'        
        self.obj_crt = env_sdasz80.Object('crt0_v6z80p.rel' , file_src)     #"cp $SOURCE $TARGET")
    
    # OS interface for C  (object file)
    def Make_OS_interface_for_C(self): 
        env = self.v6_project.env
        
        self.obj_iflos = env.Object(   ['i_flos.c'], 
                CCFLAGS     = env['CCFLAGS'] + ['--std-sdcc99', '--opt-code-speed'] )
    
    #  asm proxy (object file)
    def Make_FLOS_Proxy_Obj(self): 
        env = self.v6_project.env
        
        env_pasmo = self.v6_project.env_pasmo.Clone(CPPPATH = [self.v6_project.v6_dir + '/Equates/', '.'], 
        ASFLAGS='')         #-d
        
        # compile asm proxy to binary file
        src_asm  = 'flos.asm'
        dest_bin = 'flos.asm.bin'     
        binary_proxy = env_pasmo.Object(dest_bin, src_asm)
        Depends(binary_proxy, ['macro.asm', 'i__kernal_jump_table.asm'])
        
        # generate C source from binary file
        target = 'flos_proxy_code.c'
        source = binary_proxy
        self.v6_project.misc_tools.Generate_C_source_from_binary_file(target, source, 'flos_proxy_code')
        
        
        # compile C source
        self.obj_flosproxy = env.Object(   ['flos_proxy_code.c'], 
                CCFLAGS     = env['CCFLAGS'] + ['--constseg', 'FLOS_PROXY_CODE', '--std-sdcc99', '--opt-code-speed', ] 
                )
        
      
        
    def Make_C_FLOS_Lib(self):
        #return
        env_lib = self.v6_project.env
        
        obj = env_lib.Object(   Glob('FLOS_*.c'), 
                CCFLAGS     = env_lib['CCFLAGS'] + ['--std-sdcc99', '--opt-code-speed', ]  ) 


        Project_Helper.SetProgressMessageForNode(obj[0], '------------- C FLOS Lib: Compile C to object files ---------')
        # exit()
        
            
        self.lib_c_flos = env_lib.Library('i_flos_lib', obj)
        Project_Helper.SetProgressMessageForNode(self.lib_c_flos[0], '------------- C FLOS Lib: Add objects to Lib ---------')
        #pprint.pprint( lib)
        
    def Make_stdio_Lib(self):
        #return
        env_lib = self.v6_project.env.Clone()
        
        obj = env_lib.Object(  'stdio_v6z80p.c', 
                CCFLAGS     = env_lib['CCFLAGS'] + ['--std-sdcc99', '--opt-code-speed' ]  )                
        # check, if debug mode (for this lib) was requeted by user via scons arg (DEBUG_LIB_STDIO=1)
        debug = ARGUMENTS.get('DEBUG_LIB_STDIO', 0)
        if int(debug):
			env_lib.Append(CPPDEFINES = 'DEBUG_LIB_STDIO')        
                
        Project_Helper.SetProgressMessageForNode(obj[0], '------------- stdio Lib: Compile C to object files ---------')
            
        self.lib_stdio = env_lib.Library('stdio_v6z80p_lib', obj)        
        Project_Helper.SetProgressMessageForNode(self.lib_stdio[0], '------------- stdio Lib: Add objects to Lib ---------')
        
        
class V6_Project_SystemChecker():
    
    def Init(self, v6_project):
        self.v6_project = v6_project
        
        if self.Check_SDCC() == False:
            return False
        if self.Check_srec_cat() == False:
            return False
        if self.Check_pasmo() == False:
            return False           
        
    def Check_SDCC(self):
        # check, if sdcc is installed in system
        sdcc =  self.v6_project.env['CC']
        print 'Check for: sdcc. Executing: ' + sdcc
        pipe = SCons.Action._subproc(self.v6_project.env, [sdcc, '--version'],                                                       
                             stdin = 'devnull',                                                                    
                             stderr = 'devnull',                                                                   
                             stdout = subprocess.PIPE)                                                             
        if pipe.wait() != 0: 
            print 'Error: sdcc not found! '
            return False
                                                                                            
        #line = pipe.stdout.read().strip()                                                                                 
        #if line:                                                                                                          
        #    env['CXXVERSION'] = line                                                                                      
        line = pipe.stdout.readline()
                    
        match = re.search(r'[0-9]+(\.[0-9]+)+', line)                                                                      
        if match:                                                                                                          
            #self.v6_project.env['CXXVERSION'] = 
            self.sdcc_version = match.group(0)
        if self.sdcc_version[0] != '3':
            print 'Warn: SDCC 3.3 or later is required!'
            #return False
        
        # revision 
        match = re.search(r'(\#[0-9]+)+', line)                                                                      
        if match:                                                                                                                      
            self.sdcc_revision =  match.group(0)
            
        return True                

    def Check_srec_cat(self):
        # check, if srec_cat is installed in system
        str =  self.v6_project.platform.GetUtilFilename('srec_cat')
        print 'Check for: srec_cat. Executing: ' + str
        pipe = SCons.Action._subproc(self.v6_project.env, [str],                                                       
                             stdin = 'devnull',                                                                    
                             stderr = 'devnull',                                                                   
                             stdout = subprocess.PIPE)                                                             
        if pipe.wait() != 0: 
            print 'Error: ' + str + ' not found! '
            print 'Hint: On Linux, you will need to install the package called "srecord" (which include srec_cat program)'
            return False
        return True

    def Check_pasmo(self):
        # pasmo do output to stderr, insted of stdout (at least on my ubuntu 12.04)
        # return True       # uncomment this line, to bypass pasmo check (if pasmo detection code is not worked for you)
        
        # check, if pasmo is installed in system
        str =  'pasmo'
        print 'Check for: pasmo. Executing: ' + str
        pipe = SCons.Action._subproc(self.v6_project.env, [str],                                                       
                             stdin = 'devnull',                                                                    
                             stderr = subprocess.PIPE,                                                                   
                             stdout = 'devnull')                                                             
       
        str =''
        while 1:
            line = pipe.stderr.readline()                        
            str = str + line
            if not line: break
        
        match = re.search(r'.sage', str)    # looking for string 'Usage'

        #~ print match
        #~ exit()
                
        if match:
            print ''
        else: 
            print 'Error: ' + str + ' not found! '
            return False
        return True
        

			
        

           

# this class 
class V6_Project_MiscTools():
    def Generate_C_source_from_binary_file(self, target, source, label_name):
        env = DefaultEnvironment()
        platform = env['PLATFORM']
        
        command = 'echo // Machine generated. Dont edit. > $TARGET && echo  const >> $TARGET  && '
        if platform == 'win32':
            util_xd = self.v6_project.utilFilename_xd
            command += util_xd + ' -d' + label_name + ' $SOURCE >> $TARGET'
        else:                
            command += 'xxd' + ' -i  $SOURCE  >> $TARGET  '
            command += " && sed 's/char.*\[/char " + label_name + "[/' $TARGET > $TARGET.dir/tmp   && mv $TARGET.dir/tmp  $TARGET"
        node =  Command(target, source, command)  
        
        Project_Helper.SetProgressMessageForNode(node[0], '---- binary file to C source file ------')
        return node


    
            
                        
#screen = open('/dev/tty', 'w')
def progress_function(node):

    str_node = str(node)
    #count += 1
    #print('Node %4d: %s\r' % (count, node))
    #pprint.pprint (node)
    

    # print '--'
    # print node

    if(Project_Helper.IsNode_CanBeCheked_ForProgressMessage(node) == False):
        return


    mess = Project_Helper.GetProgressMessageForNode(node)
    if(mess != ''):
        print mess
        return

    
    if string.find(str_node, '.exe') >= 0:
        print "------------- IHX to BIN convertion ---------"
        return
    if string.find(str_node, '.ihx') >= 0:
        print "------------- Linking project -------------"
        return
        
    if string.find(str_node, 'myheap.rel') >= 0:
        print "---------------- Heap allocation -------------------"
        return
    if string.find(str_node, 'crt0_v6z80p.rel') >= 0:
        print "------------- CRT compile ---------"
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
        
    
        





