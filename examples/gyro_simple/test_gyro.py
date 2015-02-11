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
import ctypes
import os
import numpy
import pandas as pd
import math
from gyroVisualize import *

write_octave = True
octave_length = 20
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((os.environ['RUNPARAM'], 1234))
llen = ctypes.sizeof(ctypes.c_int);
window_sz = 10
v = gv()

def sample():
    bytes_recd = 0
    while bytes_recd < llen:
        chunk = s.recv(llen)
        bytes_recd = len(chunk)
    blen = struct.unpack("@i", chunk)[0]
    bytes_recd = 0
    buffer = []
    while bytes_recd < blen:
        chunk = s.recv(blen)
        bytes_recd += len(chunk) 
        buffer.append(chunk)
    rv = buffer[0]
    for b in buffer[1:]:
        rv = rv + b
    return rv

def animate():    
    times = 0
    tails = [[],[],[]]
    means = [0.0,0.0,0.0]
    pos = [0.0,0.0,0.0]
    calibrate_window = 0
    if (write_octave):
        octave_file = open("x.m", "w");
        octave_file.write("#! /usr/bin/octave --persist \nv = [");
    try:
        while (True):
            times += 1
            ss = sample()
            num_samples = len(ss)/2
            samples = struct.unpack(''.join(['h' for i in range(0,num_samples)]),ss)
            x = numpy.concatenate((tails[0],samples[0::3]),0)
            y = numpy.concatenate((tails[1],samples[1::3]),0)
            z = numpy.concatenate((tails[2],samples[2::3]),0)
            xs = pd.rolling_mean(pd.Series(x),window=window_sz)[window_sz:]
            ys = pd.rolling_mean(pd.Series(y),window=window_sz)[window_sz:]
            zs = pd.rolling_mean(pd.Series(z),window=window_sz)[window_sz:]
            tails[0] = x[-window_sz:]
            tails[1] = y[-window_sz:]
            tails[2] = z[-window_sz:]
                

            if (times <= octave_length):
                print times

            for x,y,z in zip(xs,ys,zs):
                if (times <= octave_length):
                    calibrate_window += 1
                    means[0] += x;
                    means[1] += y;
                    means[2] += z;
                    if (write_octave):
                        octave_file.write("%8d, %8d, %8d; \n" % (x,y,z));
                else:
                    # sampling rate of 800 Hz. sensitivity is 70 mdps/digit
                    pos[0] += (x-means[0])*70.0/800.0/1000.0
                    pos[1] -= (y-means[1])*70.0/800.0/1000.0
                    pos[2] -= (z-means[2])*70.0/800.0/1000.0
                    v.update(math.radians(pos[0]),math.radians(pos[1]),math.radians(pos[2]))
                    
                
            if (times == octave_length):
                for i in range (0,len(means)):
                    means[i] = means[i]/calibrate_window
                print "x_mean:%f y_mean:%f, z_mean:%f\n" % (means[0],means[1],means[2])
                if (write_octave):
                    octave_file.write("];\n");
                    octave_file.write("plot(v(:,1),color=\"r\");\n");
                    octave_file.write("hold on;\n");
                    octave_file.write("plot(v(:,2),color=\"g\");\n");
                    octave_file.write("plot(v(:,3),color=\"b\");\n");
                    octave_file.close()
                    print "done writing octave_file"

    except KeyboardInterrupt:
        s.close()
        sys.exit() 


animate()





