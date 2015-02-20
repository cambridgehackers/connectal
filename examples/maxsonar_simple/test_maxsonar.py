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

from visual import *

class gv:
    def __init__(self):
        self.main_window=display(title="test_maxsonar", forward = (1,0,-0.25), width=500, up=(0,0,1), y=200, range=(1.2,1.2,1.2))
        self.main_window.select()
        arrow(color=color.green,axis=(1,0,0), shaftwidth=0.02, fixedwidth=1)
        arrow(color=color.green,axis=(0,-1,0), shaftwidth=0.02 , fixedwidth=1)
        arrow(color=color.green,axis=(0,0,-1), shaftwidth=0.02, fixedwidth=1)

    def update(self,roll,pitch,yaw):
        pass


if __name__ == "__main__":
    v = gv()
    for i in range(1,1000):
        v.update(i,i,i)
        time.sleep(0.01)
