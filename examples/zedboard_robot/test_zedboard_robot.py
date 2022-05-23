#!/usr/bin/env python3

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

from __future__ import print_function

import struct
import sys
import os
sys.path.append(os.path.abspath('../gyro_simple'))

from sonarVisualize import *
from gyroVisualize  import *
from test_gyro      import *

sys.path.append(os.path.abspath('../../scripts'))
import portalJson
import json

smoothe = False
if __name__ == "__main__":
    argparser = argparse.ArgumentParser('Display gyroscope data')
    argparser.add_argument('-vg', '--visualize_gyro', help='Display gyro orientation in 3D rendering', default=False, action='store_true')
    argparser.add_argument('-vs', '--visualize_sonar', help='Display maxsonar output in X/Y plane', default=False, action='store_true')
    argparser.add_argument('-a', '--address', help='Device address', default=None)
    options = argparser.parse_args()
    spew_gyro = not options.visualize_gyro;
    spew_sonar = not options.visualize_sonar;
    visualize_gyro = options.visualize_gyro;
    visualize_sonar = options.visualize_sonar;
    print(options.address)
    if not options.address:
        options.address = os.environ['RUNPARAM']
    if (visualize_gyro):
        g_v  = gv()
    if (visualize_sonar):
        s_v  = sv()
    gs = gyro_stream(smoothe)
    gjp = portalJson.portal(options.address, 5000)
    msjp = portalJson.portal(options.address, 5001)
    summ = [0,0,0]
    try:
        while (True):
            samples = []
            for i in range(0,48):
                d = json.loads(gjp.recv())
                samples.append(d['x'])
                samples.append(d['y'])
                samples.append(d['z'])
                d = json.loads(msjp.recv())
                sonar_distance = d['v']
            poss = gs.next_samples(samples)
            sonar_distance = sonar_distance/147.0
            if (spew_sonar): print("sonar_distance: %f" % (sonar_distance))
            if poss is not None:
                for pos in poss:
                    if (spew_gyro): print("%f %f %f" % (pos[0],pos[1],pos[2]))
                    summ[0] = summ[0]+pos[0]
                    summ[1] = summ[1]+pos[1]
                    summ[2] = summ[2]+pos[2]
                    if (visualize_gyro and smoothe):
                        g_v.update(pos, gs.sample_freq_hz)
                if (visualize_gyro and (not smoothe)):
                    g_v.update(summ, gs.sample_freq_hz)
                if (visualize_sonar):
                    s_v.add_ray(summ[2],sonar_distance)
    except KeyboardInterrupt:
        sc.s.close()
        sys.exit() 

