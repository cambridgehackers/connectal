#!/usr/bin/env python3
## Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

from __future__ import print_function

import os, sys, shutil, string
import argparse
import subprocess
import glob
import time
import syntax
import util
import boardinfo
import pprint
import json
import re

supported_os = ['android', 'ubuntu']
supported_stl = ['stlport_static', 'stlport_shared', 'gnustl_static', 'gnustl_shared', 'c++_static', 'c++_shared', 'gabi++_static', 'gabi++_shared']

argparser = argparse.ArgumentParser("Generate C++/BSV/Xilinx stubs for an interface.")
argparser.add_argument('bsvfile', help='BSV files to parse', nargs='+')
argparser.add_argument('-B', '--board', help='Target Board for compilation', default='zc702')
argparser.add_argument('-O', '--OS', choices=supported_os, help='Target operating system', default=None)
argparser.add_argument('-interfaces', '--interfaces', help='BSV interface', action='append', default=[])
argparser.add_argument(      '--project-dir', help='xps project directory', default='./xpsproj')
argparser.add_argument(      '--pinfo', help='Project description file (json)', default=None)
argparser.add_argument(      '--protobuf', help='Interface description in protobuf', action='append', default=[])
argparser.add_argument('-s', '--source', help='C++ source files', action='append', default=[])
argparser.add_argument(      '--source2', help='C++ second program source files', action='append', default=[])
argparser.add_argument(      '--cflags', help='CFLAGS', action='append', default=[])
argparser.add_argument(      '--cxxflags', help='CXXFLAGS', action='append', default=[])
argparser.add_argument(      '--pinout', help='project pinout file', action='append', default=[])
argparser.add_argument(      '--shared', help='Make a shared library', action='store_true')
argparser.add_argument(      '--nohardware', help='Do not generate hardware for the design', action='store_true')
argparser.add_argument(      '--contentid', help='Specify 64-bit contentid for PCIe designs')
argparser.add_argument('-I', '--cinclude', help='Specify C++ include directories', action='append', default=[])
argparser.add_argument('-V', '--verilog', help='Additional verilog sources', action='append', default=[])
argparser.add_argument(      '--modelsim', help='Additional modelsim sources', action='append', default=[])
argparser.add_argument(      '--xci', help='Additional IP sources', action='append', default=[])
argparser.add_argument(      '--qip', help='Additional QIP sources', action='append', default=[])
argparser.add_argument(      '--qsf', help='Altera Quartus settings', action='append', default=[])
argparser.add_argument(      '--chipscope', help='Onchip scope settings', action='append', default=[])
argparser.add_argument('-C', '--constraint', help='Additional constraint files', action='append', default=[])
argparser.add_argument(      '--implconstraint', help='Physical constraint files', action='append', default=[])
argparser.add_argument(      '--unmanaged-implconstraint', help='Unmanaged physical constraint files', action='append', default=[])
argparser.add_argument('-M', '--make', help='Run make on the specified targets', action='append', default=[])
argparser.add_argument('-D', '--bsvdefine', help='BSV define', action='append', default=[])
argparser.add_argument('-D2', '--bsvdefine2', help='BSV define2', action='append', default=[])
argparser.add_argument(      '--pin-binding', help='pin binding translations for generate-constraints.py', action='append', default=[])
argparser.add_argument('-l', '--clib', help='C++ libary', action='append', default=[])
argparser.add_argument('-S', '--clibfiles', help='C++ libary file', action='append', default=[])
argparser.add_argument('-L', '--clibdir', help='C++ libary', action='append', default=[])
argparser.add_argument('-T', '--tcl', help='Vivado tcl script', action='append', default=[])
argparser.add_argument('-m', '--bsimsource', help='Bsim C++ source files', action='append', default=[])
argparser.add_argument(      '--verilatorflags', help='Options to verilator project flags', action='append', default=[])
argparser.add_argument('-b', '--bscflags', help='Options to pass to the BSV compiler', action='append', default=[])
argparser.add_argument('--xelabflags', help='Options to pass to the xelab compiler', action='append', default=[])
argparser.add_argument('--xsimflags', help='Options to pass to the xsim simulator', action='append', default=[])
argparser.add_argument('--awsflags', help='Options to pass to aws_build_dcp_from_cl.sh', action='append', default=[])
argparser.add_argument('--ipdir', help='Directory in which to store generated IP')
argparser.add_argument('-q', '--qtused', help='Qt used in simulator test application', action='store_true')
argparser.add_argument('--stl', help='STL implementation to use for Android builds', default=None, choices=supported_stl)
argparser.add_argument('--android-platform', help='Android platform to use for Android builds', type=int, default='16')
argparser.add_argument('--android-toolchain', help='NDK toolchain to use for Android builds', default='4.9')
argparser.add_argument('--floorplan', help='Floorplan XDC', default=None)
argparser.add_argument('-P', '--partition-module', help='Modules to separately synthesize/place/route', action='append', default=[])
argparser.add_argument('--cachedir', help='Cache directory for fpgamake to use', default=None)
argparser.add_argument('--nocache', help='dont use buildcache with fpgamake', action='store_true')
argparser.add_argument('-v', '--verbose', help='Display verbose information messages', action='store_true')
argparser.add_argument(      '--dump_map', help='List of portals passed to pcieflat for PCIe trace debug info')
argparser.add_argument('--nonstrict', help='If nonstrict, pass -Wall to gcc, otherwise -Werror', default=False, action='store_true')
argparser.add_argument('--prtop', help='Filename of previously synthesized top level for partial reconfiguration', default=None)
argparser.add_argument('--prvariant', help='name of a variant for partial reconfiguration', action='append', default=[])
argparser.add_argument('--reconfig', help='partial reconfig module names', action='append', default=[])
argparser.add_argument('--bsvpath', help='directories to add to bsc search path', action='append', default=[])
argparser.add_argument('--mainclockperiod', help='Clock period of default clock, in nanoseconds', type=int, default=10)
argparser.add_argument('--derivedclockperiod', help='Clock period of derivedClock, in nanoseconds', type=float, default=5.0)
argparser.add_argument('--pcieclockperiod', help='Clock period of PCIE clock, in nanoseconds', type=int, default=None)
argparser.add_argument('--run-args', help='Argument to pass via RUN_ARGS when running application', action='append', default=[])

noisyFlag=False

tclReadVerilogTemplate='read_verilog [ glob %(verilog)s%(pattern)s ]'
tclReadXciTemplate='''
generate_target {Synthesis} [get_files %(xci)s]
read_ip %(xci)s
'''

tclboardTemplate='''
set partname {%(partname)s}
set boardname {%(boardname)s}
## for compatibility with older fpgamake. will be removed.
set xbsvipdir {%(ipdir)s}
set ipdir {%(ipdir)s}
set connectaldir {%(connectaldir)s}
set need_pcie {%(need_pcie)s}
set connectal_dut {%(Dut)s}
%(tcldefines)s
'''

tclzynqrewireclock = '''
foreach {pat} {CLK_GATE_hdmi_clock_if CLK_*deleteme_unused_clock* CLK_GATE_*deleteme_unused_clock* RST_N_*deleteme_unused_reset*} {
    foreach {net} [get_nets -quiet $pat] {
        puts "disconnecting net $net"
        disconnect_net -net $net -objects [get_pins -quiet -of_objects $net]
    }
}
'''

fpgamakeRuleTemplate='''
export VERILOG_PATH=verilog %(verilog)s $(BLUESPEC_VERILOG)
MODELSIM_FILES= %(modelsim)s
FPGAMAKE=$(CONNECTALDIR)/../fpgamake/fpgamake
fpgamake.mk: $(VFILE) Makefile prepare_bin_target
	$(Q)if [ -f ../synth-ip.tcl ]; then vivado -mode batch -source ../synth-ip.tcl; fi
	$(Q)$(FPGAMAKE) $(FPGAMAKE_VERBOSE) -o fpgamake.mk --board=%(boardname)s --part=%(partname)s %(partitions)s --floorplan=%(floorplan)s %(xdc)s %(xci)s %(sourceTcl)s %(qsf)s %(chipscope)s -t $(MKTOP) %(FPGAMAKE_DEFINE)s %(cachedir)s -b hw/mkTop.bit %(prtop)s %(reconfig)s $(VERILOG_PATH)

synth.%%:fpgamake.mk
	$(MAKE) -f fpgamake.mk Synth/$*/$*-synth.dcp

hw/mkTop.bit: prepare_bin_target %(genxdc_dep)s fpgamake.mk
	$(Q)mkdir -p hw
	$(Q)$(MAKE) -f fpgamake.mk
ifneq ($(XILINX),)
	$(Q)rsync -rav --include="*/" --include="*.rpt" --exclude="*" Impl/ bin
else ifneq ($(ALTERA),)
	$(Q)cp -f $(MKTOP).sof bin
endif

%(genxdc)s

'''

makefileTemplate='''

##    run: run the program
##         pass parameters to software via 'make RUN_ARGS= run'
RUN_ARGS?=%(run_args)s

export DTOP=%(project_dir)s
CONNECTALDIR=%(connectaldir)s
BSVPATH = %(bsvpath)s

BOARD=%(boardname)s
PROJECTDIR=%(project_dir)s
MKTOP=%(topbsvmod)s
OS=%(OS)s
TOOLCHAIN?=%(toolchain)s
DUT=%(dut)s

export INTERFACES = %(interfaces)s
BSVFILES = %(bsvfiles)s
XCIFILES = %(xcifiles)s

BSCFLAGS_PROJECT = %(bscflags)s
SIM_CXX_PROJECT = %(bsimsource)s
VERILATOR_PROJECT_ARGS = %(verilatorflags)s
CFLAGS_PROJECT = %(cflags)s
CXXFLAGS_PROJECT = %(cxxflags)s
XELABFLAGS = %(xelabflags)s
XSIMFLAGS  = %(xsimflags)s
AWSFLAGS   = %(awsflags)s
TOPBSVFILE = %(topbsvfile)s
BSVDEFINES = %(bsvdefines)s
QTUSED = %(qtused)s
export BSVDEFINES_LIST = %(bsvdefines_list)s
export DUT_NAME = %(Dut)s
%(runsource2)s
%(shared)s
%(nohardware)s
%(protobuf)s

%(mdefines)s
%(dump_map)s

include $(CONNECTALDIR)/scripts/Makefile.connectal.build

%(bitsmake)s
'''

variantTemplate='''
extratarget::
	$(MAKE) -C ../variant%(varname)s
'''

androidmk_template='''
include $(CLEAR_VARS)
DTOP?=%(project_dir)s
CONNECTALDIR?=%(connectaldir)s
LOCAL_ARM_MODE := arm
include $(CONNECTALDIR)/scripts/Makefile.connectal.application
LOCAL_SRC_FILES := %(source)s $(PORTAL_SRC_FILES)

LOCAL_PATH :=
LOCAL_MODULE := %(android_local_module)s
LOCAL_MODULE_TAGS := optional
LOCAL_LDLIBS := -llog %(clibdirs)s %(clibs)s %(clibfiles)s
LOCAL_CPPFLAGS := "-march=armv7-a"
LOCAL_CFLAGS := %(cflags)s %(werr)s
LOCAL_CXXFLAGS := %(cxxflags)s %(werr)s
LOCAL_CFLAGS2 := $(cdefines2)s

include $(%(android_build_type)s)
'''

androidmk2_template='''
include $(CLEAR_VARS)
LOCAL_CPPFLAGS := "-march=armv7-a"
LOCAL_CFLAGS := %(cflags)s %(werr)s
LOCAL_CXXFLAGS := %(cxxflags)s %(werr)s
LOCAL_SRC_FILES= %(source2)s
LOCAL_MODULE := android.exe2
include $(BUILD_EXECUTABLE)
'''

genxdc_template='''

PIN_BINDING=%(pin_binding)s

%(genxdc_dep)s: %(pinout_dep_file)s $(CONNECTALDIR)/boardinfo/%(boardname)s.json
	mkdir -p %(project_dir)s/sources
	$(CONNECTALDIR)/scripts/generate-constraints.py -f %(fpga_vendor)s $(PIN_BINDING) -o %(genxdc_dep)s --boardfile $(CONNECTALDIR)/boardinfo/%(boardname)s.json %(pinout_file)s
'''

linuxmakefile_template='''
CONNECTALDIR?=%(connectaldir)s
DTOP?=%(project_dir)s

TOOLCHAIN?=%(toolchain)s
ifneq ($(TOOLCHAIN),)
CC=$(TOOLCHAIN)gcc
CXX=$(TOOLCHAIN)g++
endif
CFLAGS_COMMON = -O -g %(cflags)s -Wall %(werr)s %(cxxflags)s
CFLAGS = $(CFLAGS_COMMON)
CFLAGS2 = %(cdefines2)s

include $(DTOP)/Makefile.autotop
include $(CONNECTALDIR)/scripts/Makefile.connectal.application
SOURCES = %(source)s $(PORTAL_SRC_FILES)
SOURCES2 = %(source2)s $(PORTAL_SRC_FILES)
XSOURCES = $(CONNECTALDIR)/cpp/XsimTop.cpp $(PORTAL_SRC_FILES)
LDLIBS := %(clibdirs)s %(clibs)s %(clibfiles)s -lpthread

ubuntu.exe: $(SOURCES)
	$(Q)$(CXX) $(CFLAGS) -o ubuntu.exe $(SOURCES) $(LDLIBS)
	$(Q)[ ! -f ../bin/mkTop.bin.gz ] || $(TOOLCHAIN)objcopy --add-section fpgadata=../bin/mkTop.bin.gz ubuntu.exe

connectal.so: $(SOURCES)
	$(Q)$(CXX) -shared -fpic $(CFLAGS) -o connectal.so $(SOURCES) $(LDLIBS)

ubuntu.exe2: $(SOURCES2)
	$(Q)$(CXX) $(CFLAGS) $(CFLAGS2) -o ubuntu.exe2 $(SOURCES2) $(LDLIBS)

xsim: $(XSOURCES)
	$(CXX) $(CFLAGS) -o xsim $(XSOURCES)
'''

if __name__=='__main__':
    connectaldir = os.path.dirname((os.path.normpath(os.path.abspath(sys.argv[0])+'/../')))
    options = argparser.parse_args()

    boardname = options.board.lower()
    option_info = boardinfo.attribute(boardname, 'options')

    if options.pinfo:
        pinstr = open(options.pinfo).read()
        pinout = json.loads(pinstr)
        for key in pinout['options']:
            if isinstance(option_info[key], (list)):
                option_info[key] += pinout['options'][key]
            else:
                option_info[key] = pinout['options'][key]

    # parse additional options together with sys.argv
    if option_info['CONNECTALFLAGS']:
        options=argparser.parse_args(option_info['CONNECTALFLAGS'] + sys.argv[1:])

    if options.verbose:
        noisyFlag = True
    if not options.xsimflags:
        options.xsimflags = ['-R']

    if noisyFlag:
        pprint.pprint(option_info)
    project_dir = os.path.abspath(os.path.expanduser(options.project_dir))

    # remove intermediate files generated by parser generator
    # this is necessary due to silent failures when syntax.py is compiled
    os.path.exists('./out/parser.out')   and os.remove('./out/parser.out')
    os.path.exists('./out/parsetab.pyc') and os.remove('./out/parsetab.pyc')
    os.path.exists('./out/parsetab.py')  and os.remove('./out/parsetab.py')

    bsvdefines = options.bsvdefine
    bsvdefines.append('project_dir=$(DTOP)')
    print(bsvdefines)
    bsvdefines.append('MainClockPeriod=%d' % options.mainclockperiod)
    bsvdefines.append('DerivedClockPeriod=%f' % options.derivedclockperiod)
    if options.pcieclockperiod:
        bsvdefines.append('PcieClockPeriod=%d' % options.pcieclockperiod)
    print(bsvdefines)

    rewireclockstring = tclzynqrewireclock
    if 'rewireclockstring' in option_info and option_info['rewireclockstring'] != '':
        rewireclockstring = option_info['rewireclockstring']

    dutname = 'mk' + option_info['TOP']
    topbsv = connectaldir + '/bsv/' + option_info['TOP'] + '.bsv'
    if not os.path.isfile(topbsv):
        topbsv = project_dir + "/../" + option_info['TOP'] + '.bsv'
        if not os.path.isfile(topbsv):
            print("ERROR: File %s not found" % (option_info['TOP'] + '.bsv'))
            sys.exit(1)

    need_pcie = None
    if 'need_pcie' in option_info:
        need_pcie = option_info['need_pcie']

    partname = option_info['partname']
    if noisyFlag:
        print('makefilegen: partname', partname)
    if not 'os' in options:
        options.os = option_info['os']

    bdef = option_info.get('bsvdefines')
    if bdef:
        bsvdefines += bdef

    # 'constraints' is a list of files
    cstr = option_info.get('constraints')
    if cstr:
        ## preserve the order of items
        options.constraint = [os.path.join(connectaldir, item) for item in cstr] + options.constraint
    cstr = option_info.get('implconstraints')
    if cstr:
        ## preserve the order of items
        options.implconstraint = [os.path.join(connectaldir, item) for item in cstr] + options.implconstraint
    cstr = option_info.get('unmanaged-implconstraints')
    if cstr:
        ## preserve the order of items
        options.unmanaged_implconstraint= [os.path.join(connectaldir, item) for item in cstr] + options.unmanaged_implconstraint

    bsvdefines += ['BOARD_'+boardname]


    # bsvdefines is a list of definitions, not a dictionary, so need to include the "=1"
    if 'ALTERA=1' in bsvdefines:
        fpga_vendor = 'altera'
        suffix = 'sdc'
    elif 'XILINX=1' in bsvdefines:
        fpga_vendor = 'xilinx'
        suffix = 'xdc'
        options.tcl.append(os.path.join(connectaldir, 'constraints', 'xilinx', 'cdc.tcl'))
    else:
        fpga_vendor = None
        suffix = None

    print('fpga_vendor', fpga_vendor)
    if fpga_vendor:
        options.verilog.append(os.path.join(connectaldir, 'verilog', fpga_vendor))
    options.verilog.append(os.path.join(connectaldir, 'verilog'))

    if noisyFlag:
        pprint.pprint(options.__dict__)

    tclboardname = os.path.join(project_dir, 'board.tcl')
    tclsynthname = os.path.join(project_dir, '%s-synth.tcl' % dutname.lower())
    makename = os.path.join(project_dir, 'Makefile')

    androidmkname = os.path.join(project_dir, 'jni', 'Android.mk')
    linuxmkname = os.path.join(project_dir, 'jni', 'Ubuntu.mk')

    if noisyFlag:
        print('Writing Android.mk', androidmkname)
    substs = {
        #android
        'project_dir': project_dir,
        #ubuntu
        'sourceincludes': ' '.join(['-I%s' % os.path.dirname(os.path.abspath(sf)) for sf in options.source]) if options.source else '',
        #common
        'source': ' '.join([os.path.abspath(sf) for sf in options.source]) if options.source else '',
        'source2': ' '.join([os.path.abspath(sf) for sf in options.source2]) if options.source2 else '',
        'connectaldir': connectaldir,
        'clibs': ' '.join(['-l%s' % l for l in options.clib]),
        'clibfiles': ' '.join(['%s' % l for l in options.clibfiles]),
        'clibdirs': ' '.join([ '-L%s' % os.path.abspath(l) for l in options.clibdir ]),
        'cdefines': '', #' '.join([ '-D%s' % d for d in bsvdefines ]),
        'cdefines2': '', #' '.join([ '-D%s' % d for d in options.bsvdefine2 ]),
        'cincludes': ' '.join([ '-I%s' % os.path.abspath(i) for i in options.cinclude ]),
        'werr': '-Werror' if not options.nonstrict else '-Wall'
    }
    includelist = ['-I$(DTOP)/jni', '-I$(CONNECTALDIR)', \
                   '-I$(CONNECTALDIR)/cpp', '-I$(CONNECTALDIR)/lib/cpp', \
                   #'%(sourceincludes)s',
                   '%(cincludes)s']
    substs['toolchain'] = option_info['toolchain'] if 'toolchain' in option_info else ''
    substs['cflags'] = util.escapequotes('%s %s' % ((' '.join(includelist) % substs), ' '.join(options.cflags)))
    substs['cxxflags'] = util.escapequotes('%s %s' % ((' '.join(includelist) % substs), ' '.join(options.cxxflags)))
    substs['android_build_type'] = 'BUILD_SHARED_LIBRARY' if options.shared else 'BUILD_EXECUTABLE'
    substs['android_local_module'] = 'connectal' if options.shared else 'android.exe'
    f = util.createDirAndOpen(androidmkname, 'w')
    f.write(androidmk_template % substs)
    if options.source2:
        f.write(androidmk2_template % substs)
    f.close()
    f = util.createDirAndOpen(linuxmkname, 'w')
    f.write(linuxmakefile_template % substs)
    f.close()
    if options.stl or options.android_platform or options.android_toolchain:
            f = util.createDirAndOpen(os.path.join(project_dir, 'jni', 'Application.mk'), 'w')
            if options.stl:
                f.write('APP_STL                 := %s\n' % options.stl)
            if options.android_platform:
                f.write('APP_PLATFORM             := android-%s\n' % options.android_platform)
            if options.android_toolchain:
                f.write('NDK_TOOLCHAIN_VERSION    := %s\n' % options.android_toolchain)
            f.close()

    tclsubsts = {'dut': dutname.lower(),
                 'Dut': dutname,
                 'rewire_clock': rewireclockstring,
                 'project_dir': project_dir,
                 'partname': partname,
                 'boardname': boardname,
                 'connectaldir': connectaldir,
                 'read_verilog': '\n'.join([tclReadVerilogTemplate
                                            % { 'verilog': os.path.abspath(f),
                                                'pattern': '/*.*v' if os.path.isdir(f) else ''} for f in options.verilog]),
                 'read_xci': '\n'.join([tclReadXciTemplate
                                        % { 'xci': f } for f in options.xci]),
                 'need_pcie': need_pcie,
                 'tcldefines': '\n'.join(['set %s {%s}' % (var,val) for (var,val) in map(util.splitBinding, bsvdefines)]),
                 'ipdir': os.path.abspath(options.ipdir) if options.ipdir else connectaldir
                 }
    tcl = util.createDirAndOpen(tclboardname, 'w')
    tcl.write(tclboardTemplate % tclsubsts)
    tcl.close()

    if noisyFlag:
        print('Writing Makefile', makename)
    make = util.createDirAndOpen(makename + '.new', 'w')

    genxdc_dep = ''
    if options.pinout:
        genxdc_dep = '%s/sources/pinout-%s.xdc' % (project_dir,boardname)
        options.constraint.append(genxdc_dep)
        options.implconstraint.append(genxdc_dep)
    else:
       options.pinout = []

    # ignore partition_module until altera flow support generate separate netlist.
    if (fpga_vendor == 'altera'):
        options.partition_module = []

    if options.nocache:
        cachearg = '--cachedir=""'
    else:
        cachearg = '--cachedir=%s' % os.path.abspath(options.cachedir) if options.cachedir else ''
    substs = {'partitions': ' '.join(['-s %s' % p for p in options.partition_module]),
                                         'boardname': boardname,
                                         'partname': partname,
                     'fpga_vendor': fpga_vendor,
                                         'project_dir' : project_dir,
                                         'pinout_file' : ' '.join([('--pinoutfile ' + os.path.abspath(p)) for p in options.pinout]),
                                         'pinout_dep_file' : ' '.join([os.path.abspath(p) for p in options.pinout]),
                                         'genxdc_dep' : genxdc_dep,
                                         'floorplan': os.path.abspath(options.floorplan) if options.floorplan else '',
                                         'xdc': ' '.join(['--constraint=%s' % os.path.abspath(xdc) for xdc in options.constraint]
                                                         + ['--implconstraint=%s' % os.path.abspath(xdc) for xdc in options.implconstraint]
                                                         + ['--unmanaged-implconstraint=%s' % os.path.abspath(xdc) for xdc in options.unmanaged_implconstraint]),
                                         'xci': ' '.join(['--xci=%s' % os.path.abspath(xci) for xci in options.xci]),
                                         'qsf': ' '.join(['--qsf=%s' % os.path.abspath(qsf) for qsf in options.qsf]),
                                         'chipscope': ' '.join(['--chipscope=%s' % os.path.abspath(chipscope) for chipscope in options.chipscope]),
                                         'sourceTcl': ' '.join(['--tcl=%s' % os.path.abspath(tcl) for tcl in options.tcl]),
                                         'verilog': ' '.join([os.path.abspath(f) for f in options.verilog]),
                                         'modelsim': ' '.join([os.path.abspath(f) for f in options.modelsim]),
                                         'cachedir': cachearg,
                                         'pin_binding' : ' '.join(['-b %s' % s for s in options.pin_binding]),
                                         'reconfig' : ' '.join(['--reconfig=%s' % rname for rname in options.reconfig]),
                                         'prtop' : ('--prtop=%s' % options.prtop) if options.prtop else ''
                                         }
    substs['genxdc'] = (genxdc_template % substs) if options.pinout else ''
    substs['FPGAMAKE_DEFINE'] = '-D BSV_POSITIVE_RESET' if 'BSV_POSITIVE_RESET' in options.bsvdefine else ''
    bitsmake=fpgamakeRuleTemplate % substs

    ## make list of unique bsvpaths, in the order they were given
    unique_bsvpaths = []
    for l in [[os.path.dirname(os.path.abspath(bsvfile)) for bsvfile in (options.bsvfile + [project_dir])],
              [os.path.abspath(bsvpath) for bsvpath in options.bsvpath],
              [os.path.join(connectaldir, 'bsv')],
              [os.path.join(connectaldir, 'lib/bsv')],
              [os.path.join(connectaldir, 'generated/xilinx')],
              [os.path.join(connectaldir, 'generated/altera')]]:
        for p in l:
            if p not in unique_bsvpaths:
                unique_bsvpaths.append(p)

    if options.protobuf:
        protolist = [os.path.abspath(fn) for fn in options.protobuf]
    make.write(makefileTemplate % {'connectaldir': connectaldir,
                                   'bsvpath': ':'.join(unique_bsvpaths),
                                   'bsvdefines': util.foldl((lambda e,a: e+' -D '+a), '', bsvdefines),
                                   'boardname': boardname,
                                   'OS': options.os,
                                   'qtused': 'cd jni; qmake ../..; make' if options.qtused else '',
                                   'interfaces': ' '.join(options.interfaces),
                                   'bsvfiles': ' '.join([ os.path.abspath(bsvfile) for bsvfile in options.bsvfile]),
                                   'xcifiles': ' '.join([ os.path.abspath(xci) for xci in options.xci]),
                                   'bsimsource': ' '.join([os.path.abspath(bsimsource) for bsimsource in options.bsimsource]) if options.bsimsource else '',
                                   'includepath': ' '.join(['-I%s' % os.path.dirname(os.path.abspath(source)) for source in options.source]) if options.source else '',
                                   'runsource2': 'RUNSOURCE2=1' if options.source2 else '',
                                   'project_dir': project_dir,
                                   'topbsvfile' : topbsv,
                                   'topbsvmod'  : dutname,
                                   'dut' : dutname.lower(),
                                   'Dut': dutname,
                                   'clibs': ' '.join(['-l%s' % l for l in options.clib]),
                                   'cdefines': '', #' '.join([ '-D%s' % d for d in bsvdefines ]),
                                   'mdefines': '\n'.join(['%s=%s' % (var,val or var) for (var,val) in map(util.splitBinding, bsvdefines)]),
                                   'dump_map': ('export PORTAL_DUMP_MAP=' + options.dump_map + '\n') if options.dump_map else '',
                                   'bscflags': ' '.join(options.bscflags),
                                   'xelabflags': ' '.join(options.xelabflags),
                                   'xsimflags': ' '.join(options.xsimflags),
                                   'awsflags': ' '.join(options.awsflags),
                                   'verilatorflags': ' ' .join(options.verilatorflags),
                                   'cflags': ' ' .join(options.cflags),
                                   'cxxflags': ' ' .join(options.cxxflags),
                                   'bsvdefines_list': ' '.join(bsvdefines),
                                   'shared': 'CONNECTAL_SHARED=1' if options.shared else '',
                                   'nohardware': 'CONNECTAL_NOHARDWARE=1' if options.nohardware else '',
                                   'protobuf': ('export PROTODEBUG=%s' % ' '.join(protolist)) if options.protobuf else '',
                                   'bitsmake': bitsmake,
                                   'run_args': ' '.join(options.run_args),
                                   'toolchain': option_info['toolchain'] if 'toolchain' in option_info else ''
                                   })
    if not options.prtop:
        for name in options.prvariant:
            make.write(variantTemplate % {'varname': name})
    make.close()
    util.replaceIfChanged(makename, makename + '.new')

    configbsvname = os.path.join(project_dir, 'generatedbsv', 'ConnectalProjectConfig.bsv')
    configbsv = util.createDirAndOpen(configbsvname + '.new', 'w')
    for (var, val) in map(util.splitBinding, bsvdefines):
        configbsv.write('`define %(var)s %(val)s\n' % { 'var': var, 'val': val })
    configbsv.close()
    util.replaceIfChanged(configbsvname, configbsvname + '.new')

    confighname = os.path.join(project_dir, 'jni', 'ConnectalProjectConfig.h')
    configh = util.createDirAndOpen(confighname + '.new', 'w')
    configh.write('#ifndef _ConnectalProjectConfig_h\n')
    configh.write('#define _ConnectalProjectConfig_h\n')
    configh.write('\n')
    for (var, val) in map(util.splitBinding, bsvdefines):
        if re.match("^[0-9]+(.[0-9]*)?$", val):
            configh.write('#define %(var)s %(val)s\n' % { 'var': var, 'val': val })
        else:
            configh.write('#define %(var)s "%(val)s"\n' % { 'var': var, 'val': val })
    configh.write('\n')
    configh.write('#endif // _ConnectalProjectConfig_h\n')
    configh.close()
    util.replaceIfChanged(confighname, confighname + '.new')

    if options.make:
        os.chdir(project_dir)
        os.putenv('PWD', subprocess.check_output(['pwd'])[0:-1])
        subprocess.call(['make'] + options.make)
