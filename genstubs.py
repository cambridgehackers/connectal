#!/usr/bin/python
import os, sys, shutil, string
import AST
import bsvgen
import xstgen
import cppgen
import syntax
import argparse


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
argparser.add_argument('-o', '--output-dir', default='.', help='output directory')

def createDirAndOpen(f, m):
    (d, name) = os.path.split(f)
    if not os.path.exists(d):
        os.makedirs(d)
    return open(f, m)

if __name__=='__main__':
    namespace = argparser.parse_args()
    print namespace

    output_dir = os.path.expanduser(namespace.output_dir)

    inputfile = namespace.bsvfile
    
    ##s0 = syntax.parse(open('GetPut.bsv').read())

    s = open(inputfile).read() + '\n'
    s1 = syntax.parse(s)

    hname = os.path.join(output_dir, 'driver', '%s.h' % namespace.interface)
    h = createDirAndOpen(hname, 'w')
    cppname = os.path.join(output_dir, 'driver', '%s.cpp' % namespace.interface)
    bsvname = os.path.join(output_dir, 'hdl', 'verilog', '%sWrapper.bsv' % namespace.interface)
    vhdname = os.path.join(output_dir, 'hdl', 'vhdl', '%s.vhd' % namespace.interface)
    mhsname = os.path.join(output_dir, '%s.mhs' % namespace.interface.lower())
    mpdname = os.path.join(output_dir, 'data', '%s_v2_1_0.mpd' % namespace.interface.lower())
    paoname = os.path.join(output_dir, 'data', '%s_v2_1_0.pao' % namespace.interface.lower())
    cpp = createDirAndOpen(cppname, 'w')
    cpp.write('#include "ushw.h"\n')
    cpp.write('#include "%s.h"\n' % namespace.interface)
    bsv = createDirAndOpen(bsvname, 'w')
    bsvgen.emitPreamble(bsv, sys.argv[1:])
    mpd = createDirAndOpen(mpdname, 'w')
    mhs = createDirAndOpen(mhsname, 'w')
    if not os.path.exists(paoname):
        pao = createDirAndOpen(paoname, 'w')
    else:
        pao = None
    vhd = createDirAndOpen(vhdname, 'w')

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
        subinterface.emitMpd(mpd)
        subinterface.emitMhs(mhs)
        if pao:
            subinterface.emitPao(pao)
        subinterface.emitVhd(vhd)
    if cppname:
        srcdir = os.path.dirname(sys.argv[0]) + '/cpp'
        dstdir = os.path.dirname(cppname)
        for f in ['ushw.h', 'ushw.cpp']:
            shutil.copyfile(os.path.join(srcdir, f), os.path.join(dstdir, f))
