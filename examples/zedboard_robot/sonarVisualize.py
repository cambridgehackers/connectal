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

from visual import *
import math

class sv:
    def __init__(self):
        self.main_window=display(title="test_maxsonar", forward=(0,0,-1), width=500, up=(0,1,0), range=(1.2,1.2,1.2))
        self.main_window.select()
        self.cnt = 0

    def label_last(self):
        label(pos=self.last,text="%d"%(self.cnt),box=0,opacity=0)
        self.cnt = self.cnt+1

    def add_line(self,start,end):
        curve(pos=[start,end])
        self.last = end
        self.label_last()

    def extend_line(self,end):
        curve(pos=[self.last,end])
        self.last = end
        self.label_last()

    def add_ray(self,heading,length):
        end_point_x = length*math.cos(heading)
        end_point_y = length*math.sin(heading)
        curve(pos=[(0,0), (end_point_x/100,end_point_y/50)])

if __name__ == "__main__":
    v = sv()
    v.add_line((0,0,0),(1,1,0))
    v.extend_line((1,0,0))
    v.extend_line((0,0,0))

    v.add_ray(0.1,1);
    v.add_ray(0.1,1);
    v.add_ray(0.1,1);
    v.add_ray(0.1,1);
    v.add_ray(0.1,1);
    v.add_ray(0.1,1);
