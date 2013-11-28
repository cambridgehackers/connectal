
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

import HDMI::*;
import GetPut::*;
import FIFO::*;
import BRAMFIFO::*;
import YUV::*;

interface SensorToVideo;
    interface Put#(Bit#(10)) in;
    interface Get#(Bit#(24)) out;
endinterface

module mkSensorToVideo(SensorToVideo);
    FIFO#(Bit#(10)) xsviFifo <- mkSizedBRAMFIFO(64);
    interface Put in;
        method Action put(Bit#(10) xsvi);
	    xsviFifo.enq(xsvi);
	endmethod
    endinterface
    interface Get out;
        method ActionValue#(Bit#(24)) get();
	    Bit#(10) v = xsviFifo.first;
	    xsviFifo.deq;
	    let v8 = v[9:2];
	    return {v8, v8, v8};
	endmethod
    endinterface
endmodule
