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
import syntax

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
%(name)s_BSV = %(bsvfilename)s

$(eval $(call BSV_BO_RULE, $(%(name)s_BO), $(%(name)s_BSV), $(%(name)s_DEP)))

'''

if __name__=='__main__':
    options = argparser.parse_args()
    bsvpath = []
    for p in options.bsvpath:
        ps = p.split(':')
        bsvpath.extend(ps)
    bsvpackages = getBsvPackages(options.bluespecdir)
    makef = open(options.output, 'w')
    makef.write('# BSV dependences\n')
    makef.write('BSVDEFINES = %s\n' % ' '.join(['-D %s' % d for d in options.bsvdefine]))
    makef.write('BSVPATH = %s\n' % ':'.join(options.bsvpath))
    makef.write('\n')
    makef.write('# BSV files\n#\t')
    makef.write('\n#\t'.join(options.bsvfile))
    makef.write('\n')
    if options.all:
        for d in bsvpath:
            for bsvfilename in glob.glob('%s/*.bsv' % d):
                if bsvfilename not in options.bsvfile:
                    options.bsvfile.append(bsvfilename)
    for bsvfilename in options.bsvfile:
        print bsvfilename
        vf = open(bsvfilename, 'r')
        basename = os.path.basename(bsvfilename)
        (name, ext) = os.path.splitext(basename)
        source = vf.read()
        preprocess = syntax.preprocess(source, options.bsvdefine, bsvpath)
        packages = []
        for line in preprocess.split('\n'):
            m = re.match('import ([A-Za-z0-9_]+)\w*', line)
            if m:
                pkg = m.group(1)
                if pkg not in packages and pkg not in bsvpackages:
                    packages.append(pkg)
            pass
        makef.write(makefiletemplate % {
                'name': name,
                'bsvfilename': bsvfilename,
                'dependences': ' '.join(['obj/%s.bo' % pkg for pkg in packages]),
                })
        pass
    makef.close()
    vf.close()
