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

import sys
import socket
import struct
import time
import ctypes
import os
import numpy
import pandas as pd
import math
from gyroVisualize import *
import argparse
import json

sys.path.append(os.path.abspath('../../scripts'))
import portalJson

class gyro_stream:
    def __init__(self, lpf=False):
        self.times = 0
        self.tails = [[],[],[]]
        self.means = [0,0,0]
        self.calibrate_window = 0
        self.sample_freq_hz = 100
        self.lpf = lpf

    def radians(self, sample):
        # sensitivity of sample is 70 milli-degrees-per-second/digit.  
        # multiply sample by 70 to get milli-degrees-per-second                       
        # divide by sample_freq_hz to get milli-degrees
        # divide by 1000 to get degrees  
        return (math.radians(sample[0]*70.0/self.sample_freq_hz/1000.0),
                math.radians(-sample[1]*70.0/self.sample_freq_hz/1000.0),
                math.radians(-sample[2]*70.0/self.sample_freq_hz/1000.0))

    def next_samples(self,samples):
        self.times = self.times+1
        octave_length = 20
        window_sz = 10
        rv = []
        write_octave = True
        if (write_octave):
            octave_file = open("x.m", "w");
            octave_file.write("#! /usr/bin/octave --persist \nv = [");
        num_samples = len(samples)
        if (self.lpf):
            x = numpy.concatenate((self.tails[0],samples[0::3]),0)
            y = numpy.concatenate((self.tails[1],samples[1::3]),0)
            z = numpy.concatenate((self.tails[2],samples[2::3]),0)
            xs = pd.rolling_mean(pd.Series(x),window=window_sz)[window_sz:]
            ys = pd.rolling_mean(pd.Series(y),window=window_sz)[window_sz:]
            zs = pd.rolling_mean(pd.Series(z),window=window_sz)[window_sz:]
            self.tails[0] = x[-window_sz:]
            self.tails[1] = y[-window_sz:]
            self.tails[2] = z[-window_sz:]
        else:
            xs = samples[0::3]
            ys = samples[1::3]
            zs = samples[2::3]

        if (self.times <= octave_length):
            print(self.times)
                
        for x,y,z in zip(xs,ys,zs):
            #print "%d %d %d" % (x,y,z)
            if (self.times <= octave_length):
                self.calibrate_window += 1
                self.means[0] += x;
                self.means[1] += y;
                self.means[2] += z;
                if (write_octave):
                    octave_file.write("%d, %d, %d; \n" % (x,y,z));
            else:
                pos = (x-self.means[0],y-self.means[1],z-self.means[2])
                rv.append(self.radians(pos))
                #print "%d %d %d" %(pos[0],pos[1],pos[2])

        if (self.times == octave_length):
            for i in range (0,len(self.means)):
                self.means[i] = self.means[i]/self.calibrate_window
            print("x_mean:%d y_mean:%d, z_mean:%d\n" % (self.means[0],self.means[1],self.means[2]))
            if (write_octave):
                octave_file.write("];\n");
                octave_file.write("plot(v(:,1),color=\"r\");\n");
                octave_file.write("hold on;\n");
                octave_file.write("plot(v(:,2),color=\"g\");\n");
                octave_file.write("plot(v(:,3),color=\"b\");\n");
                octave_file.close()
                print("done writing octave_file")

        if (self.times > octave_length):
            return rv

                
smoothe = False
if __name__ == "__main__":
    argparser = argparse.ArgumentParser('Display gyroscope data')
    argparser.add_argument('-v', '--visualize', help='Display gyro orientation in 3D rendering', default=False, action='store_true')
    argparser.add_argument('-a', '--address', help='Device address', default=None)
    options = argparser.parse_args()
    spew = not options.visualize;
    visualize = options.visualize;
    print(options.address)
    if not options.address:
        options.address = os.environ['RUNPARAM']
    if (visualize):
        v  = gv()
    gs = gyro_stream()
    jp = portalJson.portal(options.address, 5000)
    summ = [0,0,0]
    try:
        while (True):
            samples = []
            for i in range(0,48):
                d = json.loads(jp.recv())
                samples.append(d['x'])
                samples.append(d['y'])
                samples.append(d['z'])
            poss = gs.next_samples(samples)
            if poss is not None:
                for pos in poss:
                    if (spew): print("%f %f %f" % (pos[0],pos[1],pos[2]))
                    summ[0] = summ[0]+pos[0]
                    summ[1] = summ[1]+pos[1]
                    summ[2] = summ[2]+pos[2]
                    if (visualize and smoothe):
                        v.update(summ, gs.sample_freq_hz)
                        time.sleep(1/gs.sample_freq_hz)
                if (visualize and (not smoothe)):
                    v.update(summ, gs.sample_freq_hz)
                if (not spew): print("%f %f %f" % (summ[0], summ[1], summ[2]))
    except KeyboardInterrupt:
        jp.shutdown()
        sys.exit() 





