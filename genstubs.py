#!/usr/bin/python
import os, sys, shutil, string
import AST
import bsvgen
import xstgen
import cppgen
import syntax
import argparse
from util import createDirAndOpen

AST.Method.__bases__ += (cppgen.MethodMixin,bsvgen.MethodMixin)
AST.StructMember.__bases__ += (cppgen.StructMemberMixin,)
AST.Struct.__bases__ += (cppgen.StructMixin,bsvgen.NullMixin)
AST.EnumElement.__bases__ += (cppgen.EnumElementMixin,)
AST.Enum.__bases__ += (cppgen.EnumMixin,bsvgen.NullMixin)
AST.Type.__bases__ += (cppgen.TypeMixin,bsvgen.TypeMixin)
AST.Param.__bases__ += (cppgen.ParamMixin,)
AST.Interface.__bases__ += (cppgen.InterfaceMixin,bsvgen.InterfaceMixin,xstgen.InterfaceMixin)

argparser = argparse.ArgumentParser("Generate C++/BSV/Xilinx stubs for an interface.")

argparser.add_argument('bsvfile', help='BSV files to parse')
argparser.add_argument('-b', '--interface', help='BSV interface to generate stubs for')
argparser.add_argument('-p', '--project-dir', default='./xpsproj', help='xps project directory')

if __name__=='__main__':
    namespace = argparser.parse_args()
    print namespace

    project_dir = os.path.expanduser(namespace.project_dir)

    inputfile = namespace.bsvfile
    
    ##s0 = syntax.parse(open('GetPut.bsv').read())

    s = open(inputfile).read() + '\n'
    s1 = syntax.parse(s)

    corename = '%s_v1_00_a' % namespace.interface.lower()

    hname = os.path.join(project_dir, 'driver', '%s.h' % namespace.interface)
    h = createDirAndOpen(hname, 'w')
    cppname = os.path.join(project_dir, 'driver', '%s.cpp' % namespace.interface)
    bsvname = os.path.join(project_dir, 'pcores', corename, 'hdl', 'verilog',
                           '%sWrapper.bsv' % namespace.interface)
    vhdname = os.path.join(project_dir, 'pcores', corename, 'hdl', 'vhdl',
                           '%s.vhd' % namespace.interface)
    xmpname = os.path.join(project_dir, '%s.xmp' % namespace.interface.lower())
    mhsname = os.path.join(project_dir, '%s.mhs' % namespace.interface.lower())
    mpdname = os.path.join(project_dir, 'pcores', corename, 'data',
                           '%s_v2_1_0.mpd' % namespace.interface.lower())
    paoname = os.path.join(project_dir, 'pcores', corename, 'data',
                           '%s_v2_1_0.pao' % namespace.interface.lower())
    print 'Writing CPP header', hname
    print 'Writing CPP wrapper', cppname
    cpp = createDirAndOpen(cppname, 'w')
    cpp.write('#include "ushw.h"\n')
    cpp.write('#include "%s.h"\n' % namespace.interface)
    print 'Writing BSV wrapper', bsvname
    bsv = createDirAndOpen(bsvname, 'w')
    bsvgen.emitPreamble(bsv, sys.argv[1:])

    ## code generation pass
    for v in syntax.globaldecls:
        v.emitCDeclaration(h)
        v.emitCImplementation(cpp)
    if (syntax.globalvars.has_key(namespace.interface)):
        subinterface = syntax.globalvars[namespace.interface]

        for d in subinterface.decls:
            if d.type == 'Interface':
                if syntax.globalvars.has_key(d.name):
                    subintdef = syntax.globalvars[d.name]
                    print d.params
                    newint = subintdef.instantiate({'a': d.params[0]})
                    print newint
                    for sd in newint.decls:
                        sd.name = '%s.%s' % (d.name, sd.name)
                        subinterface.decls.append(sd)

        subinterface.emitCDeclaration(h)
        subinterface.emitCImplementation(cpp)

        subinterface.emitBsvImplementation(bsv)
        subinterface.writeMpd(mpdname)
        subinterface.writeMhs(mhsname)
        subinterface.writeXmp(xmpname)
        subinterface.writePao(paoname)
        subinterface.writeVhd(vhdname)
    if cppname:
        srcdir = os.path.join(os.path.dirname(sys.argv[0]), 'cpp')
        dstdir = os.path.dirname(cppname)
        for f in ['ushw.h', 'ushw.cpp']:
            shutil.copyfile(os.path.join(srcdir, f), os.path.join(dstdir, f))
    print '############################################################'
    print '## To build:'
    print '    cd %s; xps %s.xmp' % (project_dir, namespace.interface.lower())
