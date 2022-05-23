#!/usr/bin/env python3
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
import argparse
import re
import util

argparser = argparse.ArgumentParser("Extract BVI schedule lines from bsc-generated verilog.")
argparser.add_argument('vfile', help='Verilog files to process', nargs='+')
argparser.add_argument('-d', '--dir', help='Output directory', default='.')

if __name__=='__main__':
    options = argparser.parse_args()
    for vfilename in options.vfile:
        vf = open(vfilename, 'r')
        basename = os.path.basename(vfilename)
        (name, ext) = os.path.splitext(basename)
        bvifname = os.path.join(options.dir, '%s.bvi' % name)
        bvif = open(bvifname + '.new', 'w')
        bvif.write('// BVI Schedule from %s\n' % vfilename)
        inschedule = False
        for line in vf:
            if re.match('^// BVI format method schedule info:', line):
                inschedule = True
            elif re.match('^// Ports:', line):
                inschedule = False
            elif inschedule:
                # skip the comment characters
                bvif.write(line[2:])
            else:
                pass
            pass
        bvif.close()
        ## only update the file if it changed, to help out make
        util.replaceIfChanged(bvifname, bvifname + '.new')
        vf.close()
