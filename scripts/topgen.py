#!/usr/bin/python
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

import os, sys, shutil, string
import argparse
#import subprocess
#import glob
#import time
#import syntax
import util
#import boardinfo
#import pprint
#import json

argparser = argparse.ArgumentParser("Generate Top.bsv for an project.")
argparser.add_argument('-p', '--project-dir', help='project directory')
argparser.add_argument('-v', '--verbose', help='Display verbose information messages', action='store_true')

noisyFlag=True

topTemplate='''
import Vector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
%(generatedImport)s

typedef enum {%(ifEnum)s} IfcNames deriving (Eq,Bits);

module mkConnectalTop#(HostType host)(StdConnectalTop#(PhysAddrWidth));
%(portalInstantiate)s

   Vector#(%(portalCount)s,StdPortal) portals;
%(portalList)s
   let ctrl_mux <- mkSlaveMux(portals);
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
   //interface leds = echoRequestInternal.leds;
   interface Empty pins;
   endinterface
endmodule : mkConnectalTop
'''

if __name__=='__main__':
    options = argparser.parse_args()

    if options.verbose:
        noisyFlag = True
    if not options.project_dir:
        print "topgen: -p option missing"
        sys.exit(1)

    project_dir = os.path.abspath(os.path.expanduser(options.project_dir))
    topFilename = project_dir + 'Top.xxx'
    if noisyFlag:
        print 'Writing Top:', topFilename
    wrappers = [['EchoRequest', 'EchoRequestInternal'], ['Swallow', 'Swallow']]
    proxies = [['EchoIndication', 'EchoRequestInternal']]
    userFiles = ['Echo', 'SwallowIF']
    #importfiles = proxies + wrappers + userFiles

    portalInstantiate = []
    portalList = []
    portalCount = 0
    instantiatedModules = []
    importfiles = []
    for p in proxies:
        pmap = {'name': p[0], 'consume': p[1], 'count': portalCount}
        portalList.append('   portals[%(count)s] = l%(name)sProxy.portalIfc;' % pmap)
        portalInstantiate.append('   %(name)sProxy l%(name)sProxy <- mk%(name)sProxy(%(name)s);' % pmap)
        portalInstantiate.append('   %(consume)s l%(consume)s <- mk%(consume)s(l%(name)sProxy.ifc);' % pmap)
        instantiatedModules.append(pmap['name'])
        instantiatedModules.append(pmap['consume'])
        portalCount = portalCount + 1
        importfiles.append(pmap['name'] + 'Proxy')
        importfiles.append(pmap['consume'])
    for p in wrappers:
        pmap = {'name': p[0], 'produce': p[1], 'count': portalCount}
        portalList.append('   portals[%(count)s] = l%(name)sWrapper.portalIfc;' % pmap)
        if pmap['produce'] not in instantiatedModules:
            portalInstantiate.append('   %(produce)s l%(produce)s <- mk%(produce)s();' % pmap)
            instantiatedModules.append(pmap['produce'])
            importfiles.append(pmap['produce'])
        importfiles.append(pmap['name'])
        portalInstantiate.append('   %(name)s l%(name)sWrapper <- mk%(name)sWrapper(%(name)s, l%(produce)s.ifc);' % pmap)
        instantiatedModules.append(pmap['name'] + 'Wrapper')
        portalCount = portalCount + 1

    topsubsts = {'ifEnum': ','.join(p[0] for p in wrappers + proxies),
                 'generatedImport': '\n'.join(['import %s::*;' % p for p in importfiles]),
                 'portalInstantiate' : '\n'.join(portalInstantiate),
                 'portalList': '\n'.join(portalList),
                 'portalCount': portalCount,
                 }
    print 'TOPFN', topFilename
    top = util.createDirAndOpen(topFilename, 'w')
    top.write(topTemplate % topsubsts)
    top.close()
