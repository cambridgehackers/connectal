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

plt = setup_backend()
fig = plt.figure()
win = fig.canvas.manager.window

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((os.environ['RUNPARAM'], 1234))
msglen = ctypes.sizeof(ctypes.c_int);

def sample():
    ss = []
    for i in range(0,3):
        bytes_recd = 0
        while bytes_recd < msglen:
            chunk = s.recv(msglen)
            bytes_recd = len(chunk)
        ss.append(struct.unpack("@i", chunk)[0])
    return ss

def animate():
    N = 3
    rects = plt.bar(range(N), [abs(i)*2 for i in sample()], align='center')
    try:
        while (True):
            ss = sample()
            for rect, h in zip(rects, map(abs,ss)):
                rect.set_height(h)
                fig.canvas.draw()
    except KeyboardInterrupt:
        s.close()
        sys.exit() 

win.after(10, animate)
plt.show()







