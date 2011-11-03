"""SCons.Tool.sdcc

Tool-specific initialization for generic SDCC compilers. 
(Valen)

There normally shouldn't be any need to import this module directly.
It will usually be imported through the generic SCons.Tool.Tool()
selection method.
"""

#
# Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 The SCons Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

__revision__ = "src/engine/SCons/Tool/cc.py 5357 2011/09/09 21:31:03 bdeegan"

import SCons.Tool
import SCons.Defaults
import SCons.Util

CSuffixes = ['.c', '.m']
if not SCons.Util.case_sensitive_suffixes('.c', '.C'):
    CSuffixes.append('.C')

def add_common_cc_variables(env):
    """
    Add underlying common "C compiler" variables that
    are used by multiple tools (specifically, c++).
    """
    if '_CCCOMCOM' not in env:
        env['_CCCOMCOM'] = '$CPPFLAGS $_CPPDEFFLAGS $_CPPINCFLAGS'

    if 'CCFLAGS' not in env:
        env['CCFLAGS']   = SCons.Util.CLVar('')


def generate(env):
    """
    Add Builders and construction variables for C compilers to an Environment.
    """
    static_obj, shared_obj = SCons.Tool.createObjBuilders(env)

    for suffix in CSuffixes:
        static_obj.add_action(suffix, SCons.Defaults.CAction)
        static_obj.add_emitter(suffix, SCons.Defaults.StaticObjectEmitter)

    add_common_cc_variables(env)

#    env['CC']        = '/home/valen/Programs/sdcc/bin/sdcc'
    env['CC']        = 'sdcc'
    env['CFLAGS']    = SCons.Util.CLVar('')
    env['CCCOM']     = '$CC -o $TARGET -c $CFLAGS $CCFLAGS $_CCCOMCOM $SOURCES'

    env['CPPDEFPREFIX']  = '-D'
    env['CPPDEFSUFFIX']  = ''
    env['INCPREFIX']  = '-I'
    env['INCSUFFIX']  = ''
#    env['STATIC_AND_SHARED_OBJECTS_ARE_THE_SAME'] = 0

    env['CFILESUFFIX'] = '.c'

def exists(env):
    return env.Detect('sdcc')

# Local Variables:
# tab-width:4
# indent-tabs-mode:nil
# End:
# vim: set expandtab tabstop=4 shiftwidth=4:
