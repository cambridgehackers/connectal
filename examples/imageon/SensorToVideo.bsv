
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Imageon::*;
import HDMI::*;
import GetPut::*;
import FIFO::*;
import BRAMFIFO::*;
import YUV::*;

interface SensorToVideo;
    interface Put#(XsviData) in;
    interface Get#(Rgb888VideoData) out;
endinterface

module mkSensorToVideo(SensorToVideo);
    FIFO#(XsviData) xsviFifo <- mkSizedBRAMFIFO(64);
    interface Put in;
        method Action put(XsviData xsvi);
	    xsviFifo.enq(xsvi);
	endmethod
    endinterface
    interface Get out;
        method ActionValue#(Rgb888VideoData) get();
	    XsviData xsvi = xsviFifo.first;
	    xsviFifo.deq;
	    Bit#(10) v = xsvi.video_data;
	    let v8 = v[9:2];
	    return Rgb888VideoData {
	        vsync: xsvi.vsync,
	        hsync: xsvi.hsync,
		active_video: xsvi.active_video,
		r: v8,
		g: v8,
		b: v8
            };
	endmethod
    endinterface
endmodule
