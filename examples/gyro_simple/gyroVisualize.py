##
## Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

from visual import *

class gv:
    def __init__(self):
        self.roll_bar = []
        self.pitch_bar = []
        self.main_window=display(title="Board Orientation", forward = (1,0,-0.25), width=500, up=(0,0,1), y=200, range=(1.2,1.2,1.2))
        self.aux_window = display(title='Roll/Pitch/Yaw',x=0, y=0, width=500, height=200,center=(0,0,0), background=(0,0,0), range=(1,1,1))

        self.aux_window.select()
        self.roll_bar.append(cylinder(pos=(-0.4,0,0),axis=(0.2,0,0),radius=0.01,color=color.red))
        self.roll_bar.append(cylinder(pos=(-0.4,0,0),axis=(-0.2,0,0),radius=0.01,color=color.red))
        self.pitch_bar.append(cylinder(pos=(0.1,0,0),axis=(0.2,0,0),radius=0.01,color=color.green))
        self.pitch_bar.append(cylinder(pos=(0.1,0,0),axis=(-0.2,0,0),radius=0.01,color=color.green))
        self.yaw_arrow = arrow(pos=(0.6,0,0),color=color.cyan,axis=(-0.2,0,0), shaftwidth=0.02, fixedwidth=1)

        label(pos=(-0.4,0.3,0),text="Roll",box=0,opacity=0)
        label(pos=(0.1,0.3,0),text="Pitch",box=0,opacity=0)
        label(pos=(0.55,0.3,0),text="Yaw",box=0,opacity=0)
        label(pos=(0.6,0.22,0),height=8,text="N",box=0,opacity=0,color=color.yellow)
        label(pos=(0.6,-0.22,0),height=8,text="S",box=0,opacity=0,color=color.yellow)
        label(pos=(0.38,0,0),height=8,text="W",box=0,opacity=0,color=color.yellow)
        label(pos=(0.82,0,0),height=8,text="E",box=0,opacity=0,color=color.yellow)

        self.main_window.select()
        arrow(color=color.green,axis=(1,0,0), shaftwidth=0.02, fixedwidth=1)
        arrow(color=color.green,axis=(0,-1,0), shaftwidth=0.02 , fixedwidth=1)
        arrow(color=color.green,axis=(0,0,-1), shaftwidth=0.02, fixedwidth=1)
        label(pos=(0,0,0.8),text="Board Orientation",box=0,opacity=0)
        label(pos=(1,0,0),text="X",box=0,opacity=0)
        label(pos=(0,-1,0),text="Y",box=0,opacity=0)
        label(pos=(0,0,-1),text="Z",box=0,opacity=0)
        self.platform = box(length=1, height=0.05, width=1, color=color.red)
        self.p_line = box(length=1,height=0.08,width=0.1,color=color.yellow)
        self.plat_arrow = arrow(color=color.green,axis=(1,0,0), shaftwidth=0.06, fixedwidth=1)

    def update(self, direction, sampling_period):
        (roll,pitch,yaw) = direction
        axis=(cos(pitch)*cos(yaw),-cos(pitch)*sin(yaw),sin(pitch)) 
        up=(sin(roll)*sin(yaw)+cos(roll)*sin(pitch)*cos(yaw),sin(roll)*cos(yaw)-cos(roll)*sin(pitch)*sin(yaw),-cos(roll)*cos(pitch))
        self.platform.axis=axis
        self.platform.up=up
        self.platform.length=1.0
        self.platform.width=0.65
        self.plat_arrow.axis=axis
        self.plat_arrow.up=up
        self.plat_arrow.length=0.8
        self.p_line.axis=axis
        self.p_line.up=up
        self.roll_bar[0].axis=(-0.2*cos(roll),0.2*sin(roll),0)
        self.roll_bar[1].axis=(0.2*cos(roll),-0.2*sin(roll),0)
        self.pitch_bar[0].axis=(-0.2*cos(pitch),0.2*sin(pitch),0)
        self.pitch_bar[1].axis=(0.2*cos(pitch),-0.2*sin(pitch),0)
        self.yaw_arrow.axis=(0.2*sin(yaw),0.2*cos(yaw),0)
        rate(sampling_period)



if __name__ == "__main__":
    v = gv()
    for i in range(1,1000):
        v.update(i,i,i)
        time.sleep(0.01)
