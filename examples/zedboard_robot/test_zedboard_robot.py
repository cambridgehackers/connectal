#!/usr/bin/env python

# Copyright (c) 2013 Quanta Research Cambridge, Inc.

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import struct
import sys
import os
sys.path.append(os.path.abspath('../gyro_simple'))

from sonarVisualize import *
from gyroVisualize  import *
from test_gyro      import *

visualize = False
spew = False
if __name__ == "__main__":
    if (visualize):
        g_v  = gv()
        s_v  = sv()
    gs = gyro_stream()
    sc = socket_client()
    try:
        while (True):
            gyro_ss = sc.sample()
            sonar_ss = sc.sample()
            poss = gs.next_samples(gyro_ss)
            sonar_distance = (struct.unpack('I',sonar_ss)[0])/147.0
            if (spew): print "sonar_distance: %f" % (sonar_distance)
            if poss is not None:
                for pos in poss:
                    if (visualize):
                        g_v.update(math.radians(pos[0]),math.radians(pos[1]),math.radians(pos[2]))
                        time.sleep(gs.perforate/800)
                        s_v.add_ray(math.radians(pos[2]),sonar_distance)
                    if (spew):
                        print "%f %f %f" % (pos[0],pos[1],pos[2])
    except KeyboardInterrupt:
        sc.s.close()
        sys.exit() 
