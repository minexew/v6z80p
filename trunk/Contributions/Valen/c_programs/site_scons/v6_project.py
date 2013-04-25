import os
import string
import re
import subprocess
import pprint
import time
import datetime
import ConfigParser             # to read ini file
from SCons.Script import *

class V6_Project(object):
    def __init__(self):
                      
        if 'v6z80pdir' not in os.environ:
            print 'Error: v6z80pdir env var is not set!'
            print '(for example, on my system this var have value  ~/sharedFolder1/v6z80p_SVN)'
            exit()
            
            
        self.v6_dir  = os.environ['v6z80pdir']
        self.basedir = os.environ['v6z80pdir'] + '/Contributions/Valen/c_programs/'
        
        self.base_variant_dir = 'build/v6/c_programs/'
        
        self.depend  = V6_Project_Dependencies()
        self.depend.Init(self)
        
        self.checker         = V6_Project_SystemChecker()
        self.options_handler = V6_Project_OptionsHandler()  
        self.misc_tools      = V6_Project_MiscTools()
        
        self.utilFilename_xd     = self.GetUtilFilename('xd')
        self.utilFilename_sendv6 = self.GetUtilFilename('sendv6')
        
        # this files (objects) will be passed to link command
        # NOTE: CRT object file (crt0_v6z80p) must be first in this list!! 
        ## c_support/crt/obj/crt0_v6z80p.rel     c_support/os_interface_for_c/obj/i_flos.rel c_support/os_proxy/obj/flos_proxy_code.rel        
        #self.link_objects = Split("""                                                
        #""")
        #for i in range(len(self.link_objects)):
            #self.link_objects[i] = self.basedir + self.link_objects[i]
        
    #self._stack = None   
    #def get_stack(self):
        #return self._stack
    #def set_stack(self, stack):
        #self._stack = stack        
        ##self.env.Append(CPPDEFINES = [{'OWN_SP' : self._stack}])
        ##print 'dddddddddddddddddddddd'
    #stack = property(get_stack, set_stack) 


    def Init(self):
      
        
        
        
        return True
    
    """This func will be called from SConscript file."""
    def FLOS_Program(self, objs):       
        objs[0].my_progress_message = '------------- Compile user files ---------'
        
        obj_heap = self.MakeHeapObj()
        self.obj_proj_info = self.Make_ProjectInfo_Obj()
        # 
        
        #variant_dir =  Dir('.').get_abspath()
        variant_dir =  Dir('.').path    #'src/pong/obj'
        #print ' ======= ' + variant_dir
        
        # NOTE: CRT object file (crt0_v6z80p) must be first in this sources list!!!
        file_ihx = self.env.Program(self.name , self.depend.obj_crt + self.depend.obj_iflos
                    + self.depend.obj_flosproxy
                    + obj_heap + objs, LINKFLAGS=self.env['LINKFLAGS'] + self.linkopt,
                      
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
        srec_util = self.GetUtilFilename('srec_cat')
        
        command1 = srec_util + ' $SOURCE -intel -offset -0x5000   -o $TARGET -binary'
        return self.env.Command(self.name + '.exe', file_ihx, command1)         #, "cp $SOURCE $TARGET")
    
    def MakeHeapObj(self):
        file1 = self.basedir + 'c_support/myheap.s'

        subst = Environment(tools = ['textfile'])
        # generate asm file, concatenate another asm file with a string
        heap_size = 0
        if hasattr(self, 'heapsize'):
            heap_size = self.heapsize
        asm_heap = subst.Textfile(target = 'myheap.s',              
                                source = [self.env.File(file1), heap_size], 
                                LINESEPARATOR=' ')
        self.env.Depends(asm_heap, 'SConscript')
        
        # compile asm to obj
        env_sdasz80 = self.env_sdasz80        
        obj_heap = env_sdasz80.Object('myheap' + env_sdasz80['OBJSUFFIX'], asm_heap)     #"cp $SOURCE $TARGET")
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


        env['CPPPATH'] =  [self.basedir + 'inc/']
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
                            

        
        env.Append( SENDV6_UTIL = self.v6_dir + '/Contributions/Daniel/Linux_tools/sendv6/' + self.utilFilename_sendv6,
                    SENDV6_PORT = self.options_handler.config.get('SendV6', 'port'),
                    SLEEP_UTIL  = 'sleep')
        
        #print env['CC']
        #print env['ENV']['PATH']
        self.env = env
        
        self.env_pasmo   = self.env.Clone(tools=['pasmo'],      CPPPATH = '')
        self.env_sdasz80 = self.env.Clone(tools=['sdasz80'],    CPPPATH = '')

    def GetEnv_SDCC(self):
        return self.env
        
    def GetUtilFilename(self, strName):
        env = DefaultEnvironment()
        platform = env['PLATFORM']
        
        # for now, even in linux we just use win32 exe file (because someone (valen :) is too lazy to download the source http://www.fourmilab.ch/xd/ and build xd utility )
        # (sure, wine is required)
        if strName == 'xd':
            return self.basedir + 'c_support/tools/xd.exe' 

        if strName == 'sendv6':                   
            if platform == 'win32':
                return os.path.join(self.v6_dir, 'Contributions/Daniel/Linux_tools/sendv6')
            else:                
                return 'sendv6'
            
                         
        if platform == 'win32':
            # in win32 we have all utils in this dir
            util = self.basedir + 'c_support/tools/' + strName
        else:
            # on non win systems, you need to install req. utils
            util = strName
        return util
            
    def Upload(self, upload_target):     #, is_upload_always):
        # Note: Why we need pause a few seconds, between file uploads :
        # when FILERX is writing the last sended 32KB buffer to disk, it may be about 1.5-2 seconds to complete disk write,
        # but (on the side of fast PC), the sendv6 exits immidiatly  and will re-run again, and thus will fail to connect to v6,
        # because on v6 board, FILERX is still in disk write mode (not in listening mode).
        
        upload_command = 'cd ${SOURCE.dir} && $SENDV6_UTIL $SENDV6_PORT ${SOURCE.file}  &&  $SLEEP_UTIL 2'    
        #upload_command = 'sendv6 S0 $SOURCE'       # (via COM1, 'S0' - part of linux specific name ttyS0 of COM1)
        
        upload = self.env.Alias('upload_' + self.name + '_' + str(upload_target[0]), upload_target, upload_command)
        if 1:        #is_upload_always:
            AlwaysBuild(upload)
        upload[0].my_progress_message = '------------- Upload file to V6 -------------'
        
        upload2 = self.env.Alias('upload_' + self.name, upload)
        Alias('upload_all', upload)


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
        obj[0].my_progress_message = '------------- C FLOS Lib: Compile C to object files ---------'
        
            
        self.lib_c_flos = env_lib.Library('i_flos_lib', obj)
        self.lib_c_flos[0].my_progress_message = '------------- C FLOS Lib: Add objects to Lib ---------'
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
        
        obj[0].my_progress_message = '------------- stdio Lib: Compile C to object files ---------'
        
            
        self.lib_stdio = env_lib.Library('stdio_v6z80p_lib', obj)
        self.lib_stdio[0].my_progress_message = '------------- stdio Lib: Add objects to Lib ---------'        
        
        
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
        if self.sdcc_version[0] == '2':
            print 'Warn: SDCC 3.0 or later is recommended!'
        
        # revision 
        match = re.search(r'(\#[0-9]+)+', line)                                                                      
        if match:                                                                                                                      
            self.sdcc_revision =  match.group(0)
            
        return True                

    def Check_srec_cat(self):
        # check, if srec_cat is installed in system
        str =  self.v6_project.GetUtilFilename('srec_cat')
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
        
# this class know how to handle specific ini file options
class V6_Project_OptionsHandler():
    
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
        node[0].my_progress_message = '---- binary file to C source file ------'
        return node
         
                        
#screen = open('/dev/tty', 'w')
def progress_function(node):
    str_node = str(node)
    #count += 1
    #print('Node %4d: %s\r' % (count, node))
    #pprint.pprint (node)
    
    if node.is_up_to_date():
        #print 'node: ' + str(node)
        return

    if hasattr(node, 'my_progress_message'):
        print node.my_progress_message
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
        
    
        
# register our own progress function
Progress(progress_function)




