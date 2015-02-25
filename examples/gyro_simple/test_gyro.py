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


class socket_client:
    def __init__(self, devaddr):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((devaddr, 1234))
        self.llen = ctypes.sizeof(ctypes.c_int);
    def sample(self):
        bytes_recd = 0
        while bytes_recd < self.llen:
            chunk = self.s.recv(self.llen)
            bytes_recd = len(chunk)
        blen = struct.unpack("@i", chunk)[0]
        bytes_recd = 0
        buffer = []
        while bytes_recd < blen:
            chunk = self.s.recv(blen)
            bytes_recd += len(chunk) 
            buffer.append(chunk)
        rv = buffer[0]
        for b in buffer[1:]:
            rv = rv + b
        return rv


class gyro_stream:
    def __init__(self):
        self.times = 0
        self.tails = [[],[],[]]
        self.means = [0.0,0.0,0.0]
        self.calibrate_window = 0
        self.perforate = 3

    def next_samples(self,ss):
        smoothe = True;
        octave_length = 20
        window_sz = 10
        pos = [0.0,0.0,0.0]
        rv = []
        write_octave = True
        if (write_octave):
            octave_file = open("x.m", "w");
            octave_file.write("#! /usr/bin/octave --persist \nv = [");
            self.times += 1
            num_samples = len(ss)/2
            samples = struct.unpack(''.join(['h' for i in range(0,num_samples)]),ss)
            if (smoothe):
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
                print self.times
                
            xs = xs[::self.perforate]
            ys = ys[::self.perforate]
            zs = zs[::self.perforate]

            for x,y,z in zip(xs,ys,zs):
                if (self.times <= octave_length):
                    self.calibrate_window += 1
                    self.means[0] += x;
                    self.means[1] += y;
                    self.means[2] += z;
                    if (write_octave):
                        octave_file.write("%8d, %8d, %8d; \n" % (x,y,z));
                else:
                    # sampling rate of 800 Hz. sensitivity is 70 mdps/digit
                    pos[0] += self.perforate*(x-self.means[0])*70.0/800.0/1000.0
                    pos[1] -= self.perforate*(y-self.means[1])*70.0/800.0/1000.0
                    pos[2] -= self.perforate*(z-self.means[2])*70.0/800.0/1000.0
                    rv.append(pos)
                
            if (self.times == octave_length):
                for i in range (0,len(self.means)):
                    self.means[i] = self.means[i]/self.calibrate_window
                print "x_mean:%f y_mean:%f, z_mean:%f\n" % (self.means[0],self.means[1],self.means[2])
                if (write_octave):
                    octave_file.write("];\n");
                    octave_file.write("plot(v(:,1),color=\"r\");\n");
                    octave_file.write("hold on;\n");
                    octave_file.write("plot(v(:,2),color=\"g\");\n");
                    octave_file.write("plot(v(:,3),color=\"b\");\n");
                    octave_file.close()
                    print "done writing octave_file"
            if (self.times > octave_length):
                return rv


visualize = True
spew = False
if __name__ == "__main__":
    argparser = argparse.ArgumentParser('Display gyroscope data')
    argparser.add_argument('-v', '--visualize', help='Display gyro orientation in 3D rendering', default=False, action='store_true')
    argparser.add_argument('-a', '--address', help='Device address', default=None)
    options = argparser.parse_args()
    spew = not options.visualize;
    visualize = options.visualize;
    print options.address
    if not options.address:
        options.address = os.environ['RUNPARAM']
    if (visualize):
        v  = gv()
    gs = gyro_stream()
    sc = socket_client(options.address)
    try:
        print 'here', time.clock()
        t = time.clock()
        while (True):
            ss = sc.sample()
            poss = gs.next_samples(ss)
            if poss is not None:
                printsample = False
                #print time.clock(), t, (time.clock() - t) > 0.5
                if (time.clock() - t) > 0.01:
                    printsample = True
                    t = time.clock()
                for pos in poss:
                    if (visualize):
                        v.update(math.radians(pos[0]),math.radians(pos[1]),math.radians(pos[2]))
                        time.sleep(gs.perforate/800)
                    if (spew and printsample):
                            print "%f %f %f" % (pos[0],pos[1],pos[2])
                            printsample = False
    except KeyboardInterrupt:
        sc.s.close()
        sys.exit() 





