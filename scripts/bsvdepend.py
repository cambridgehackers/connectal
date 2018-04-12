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
import bsvdependencies

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
    (bsvdep,bsvpath) = bsvdependencies.bsvDependencies(options.bsvfile,
                                                       options.all,
                                                       options.bluespecdir,
                                                       options.bsvpath,
                                                       options.bsvdefine)

    makef = open(options.output, 'w')
    makef.write('# BSV dependences\n')
    for bsvdef in options.bsvdefine:
        makef.write('#  -D%s\n' % bsvdef)
    makef.write('OBJMAKEFILE_DEP = %s\n' % ' '.join(['$(wildcard %s/*.bsv)' % path for path in bsvpath]))
    makef.write('\n')
    for bsvfilename,packages,includes,synthesizedModules in bsvdep:
        basename = os.path.basename(bsvfilename)
        (name, ext) = os.path.splitext(basename)
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
