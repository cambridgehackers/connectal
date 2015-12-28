#!/usr/bin/python
# Copyright (c) 2015 Connectal Project
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

import os, sys
import glob
import argparse
import re
import bsvpreprocess

default_bluespecdir=None
if 'BLUESPECDIR' in os.environ:
    default_bluespecdir = os.environ['BLUESPECDIR']

argparser = argparse.ArgumentParser("Writes a makefile for a dependence build of the BSV files.")
argparser.add_argument('bsvfile', help='BSV files to process', nargs='*')
argparser.add_argument('-D', '--bsvdefine', default=[], help='BSV define', action='append')
argparser.add_argument('--bsvpath', default=[], help='directories to add to bsc search path', action='append')
argparser.add_argument('--bluespecdir', default=default_bluespecdir, help='BSC bluespec dir')
argparser.add_argument('-o', '--output', help='Output Makefile', default='Makefile.bsv')
argparser.add_argument('--all', help='Generate entries for all BSV files on path.', default=False)

def getBsvPackages(bluespecdir):
    pkgs = []
    for f in glob.glob('%s/Prelude/*.bo' % bluespecdir):
        pkgs.append(os.path.splitext(os.path.basename(f))[0])
    return pkgs

makefiletemplate='''
%(name)s_BO  = obj/%(name)s.bo
%(name)s_DEP = %(dependences)s
%(name)s_INC = %(includes)s
%(name)s_BSV = %(bsvfilename)s

$(eval $(call BSV_BO_RULE, $(%(name)s_BO), $(%(name)s_BSV), $(%(name)s_DEP), $(%(name)s_INC)))
'''

synthmoduletemplate = '''
%(name)s_MOD = %(module)s
%(name)s_V   = verilog/%(module)s.v
%(name)s_BO  = obj/%(name)s.bo
%(name)s_BSV = %(bsvfilename)s
%(name)s_DEP = %(dependences)s
%(name)s_INC = %(includes)s

$(eval $(call BSV_V_RULE, $(%(name)s_MOD), $(%(name)s_V), $(%(name)s_BSV), $(%(name)s_DEP), $(%(name)s_INC)))
'''

if __name__=='__main__':
    options = argparser.parse_args()
    bsvpath = []
    for p in options.bsvpath:
        ps = p.split(':')
        bsvpath.extend(ps)
    bsvpackages = getBsvPackages(options.bluespecdir)

    if options.all:
        for d in bsvpath:
            for bsvfilename in glob.glob('%s/*.bsv' % d):
                if bsvfilename not in options.bsvfile:
                    options.bsvfile.append(bsvfilename)
    abspaths = {}
    for f in options.bsvfile:
        abspaths[os.path.basename(f)] = f

    makef = open(options.output, 'w')
    makef.write('# BSV dependences\n')
    makef.write('BSVDEFINES = %s\n' % ' '.join(['-D %s' % d for d in options.bsvdefine]))
    makef.write('BSVPATH = %s\n' % ':'.join(bsvpath))
    makef.write('\n')
    makef.write('OBJMAKEFILE_DEP = %s\n' % ' '.join(['$(wildcard %s/*.bsv)' % path for path in bsvpath]))
    makef.write('\n')
    for bsvfilename in options.bsvfile:
        vf = open(bsvfilename, 'r')
        basename = os.path.basename(bsvfilename)
        (name, ext) = os.path.splitext(basename)
        source = vf.read()
        preprocess = bsvpreprocess.preprocess(bsvfilename, source, options.bsvdefine, bsvpath)
        packages = []
        includes = []
        synthesizedModules = []
        synthesize = False
        for line in preprocess.split('\n'):
            #print 'bsvdepend: %s' % line
            m = re.match('//`include "([^\"]+)"', line)
            m1 = re.match('//`include(.*)', line)
            if m:
                iname = m.group(1)
                if iname in abspaths:
                    iname = abspaths[iname]
                else:
                    iname = 'obj/%s' % iname
                #print 'm:', m.group(1), iname
                includes.append(iname)
            elif m1:
                sys.stderr.write('bsvdepend %s: unhandled `include %s\n' % (bsvfilename, m1.group(1)))

            if re.match('^//', line):
                continue
            m = re.match('import ([A-Za-z0-9_]+)\w*', line)
            if m:
                pkg = m.group(1)
                if pkg not in packages and pkg not in bsvpackages:
                    packages.append(pkg)
            if synthesize:
                m = re.match('\s*module\s+([A-Za-z0-9_]+)', line)
                if m:
                    synthesizedModules.append(m.group(1))
                else:
                    sys.stderr.write('bsvdepend: in %s expecting module: %s\n' % (bsvfilename, line))
            synth = line.find('(* synthesize *)')
            attr = line.find('(* ')
            if synth >= 0:
                synthesize = True
            elif attr >= 0:
                pass # no change to synthesize
            else:
                synthesize = False
            pass
        makef.write(makefiletemplate % {
                'name': name,
                'bsvfilename': bsvfilename,
                'dependences': ' '.join(['obj/%s.bo' % pkg for pkg in packages]),
                'includes':    ' '.join(includes)
                })
        for mod in synthesizedModules:
            makef.write(synthmoduletemplate % {
                    'module': mod,
                    'name': name,
                    'bsvfilename': bsvfilename,
                    'dependences': ' '.join(['obj/%s.bo' % pkg for pkg in packages]),
                    'includes':    ' '.join(includes)
                    })
        pass
    makef.close()
    vf.close()
