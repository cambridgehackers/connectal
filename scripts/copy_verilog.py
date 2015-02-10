#!/usr/bin/python

import os, sys, re, shutil

parameterizedModuleRe = r'^\s+(\w+)\s*#'
plainModuleRe = r'^\s+(\w+)\s*(\w+)\('

def findVerilogModules(vinput):
    f = open(vinput)
    modules = {}
    for line in f:
        m = re.match(parameterizedModuleRe, line)
        if m:
            module = m.group(1)
            modules[module] = module
        m = re.match(plainModuleRe, line)
        if m:
            module = m.group(1)
            modules[module] = module
    return modules.keys()

def addPaoEntry(paoname, mod):
    print paoname, mod
    component = None
    pao = open(paoname, 'r')
    for line in pao:
        s = line.split(' ')
        if len(s) == 4:
            (lib,component,m,hdl) = s
            if m == mod:
                return
    pao.close()
    pao = open(paoname, 'a+')
    pao.write('lib %s %s verilog\n' % (component, mod))
    pao.close()

def updatePao(vinput, libdirs):
    destdir = os.path.dirname(vinput)
    if os.environ.has_key('BLUESPECDIR'):
        if 'ALTERA' in os.environ['BSVDEFINES_LIST']:
            libdirs.append(os.path.join(os.environ['BLUESPECDIR'], 'Verilog.Quartus'))
        if 'XILINX' in os.environ['BSVDEFINES_LIST']:
            libdirs.append(os.path.join(os.environ['BLUESPECDIR'], 'Verilog.Vivado'))
        libdirs.append(os.path.join(os.environ['BLUESPECDIR'], 'Verilog'))
    #print 'destdir', destdir
    #print 'libdirs', libdirs
    modules = findVerilogModules(vinput)
    #print modules
    for mod in modules:
        modv = '%s.v' % mod
        if not os.path.exists(os.path.join(destdir, modv)):
            for libdir in libdirs:
                if os.path.exists(os.path.join(libdir, modv)):
                    print 'found', os.path.join(libdir, modv)
                    print 'copying to: ', os.path.join(destdir, modv)
                    shutil.copyfile(os.path.join(libdir, modv),
                                    os.path.join(destdir, modv))
                    newmodules = findVerilogModules(os.path.join(libdir, modv))
                    for n in newmodules:
                        if not (n in modules):
                            modules.append(n)
                    break

if __name__=='__main__':
    updatePao(sys.argv[1], sys.argv[2:])
