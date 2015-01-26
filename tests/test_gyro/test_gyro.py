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
import pandas as pd

import matplotlib.pyplot as plt
import numpy as np
def setup_backend(backend='TkAgg'):
    import sys
    del sys.modules['matplotlib.backends']
    del sys.modules['matplotlib.pyplot']
    import matplotlib as mpl
    mpl.use(backend)  # do this before importing pyplot
    import matplotlib.pyplot as plt
    return plt


display_graph = True
if (display_graph):
    plt = setup_backend()
    fig = plt.figure()
    win = fig.canvas.manager.window
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((os.environ['RUNPARAM'], 1234))
llen = ctypes.sizeof(ctypes.c_int);

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
    print len(rv)
    return rv

def animate():
    if (display_graph):
        N = 3
        rects = plt.bar(range(N), [200,200,200], align='center')
    try:
        while (True):
            ss = sample()
            num_samples = len(ss)/2
            fmt = ""
            for i in range(0,num_samples):
                fmt = fmt+"h"
            samples = struct.unpack(fmt,ss)
            window_sz = 100
            xs = pd.rolling_mean(pd.Series(samples[0::3]),window=window_sz)[window_sz:]
            ys = pd.rolling_mean(pd.Series(samples[1::3]),window=window_sz)[window_sz:]
            zs = pd.rolling_mean(pd.Series(samples[2::3]),window=window_sz)[window_sz:]
            if (display_graph):
                for x,y,z in zip(xs,ys,zs):
                    for rect, h in zip(rects, map(abs,[x,y,z])):
                        rect.set_height(h)
                        fig.canvas.draw()
    except KeyboardInterrupt:
        s.close()
        sys.exit() 

if(display_graph):
    win.after(10, animate)
    plt.show()
else:
    animate()






