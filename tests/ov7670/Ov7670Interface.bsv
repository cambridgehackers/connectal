
// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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

import SCCB::*;

interface Ov7670ControllerRequest;
   method Action setFramePointer(Bit#(32) frameId);
   method Action i2cRequest(Bit#(8) bus, Bool write, Bit#(7) slaveaddr, Bit#(8) address, Bit#(8) data);
   method Action setReset(Bit#(1) rval);
   method Action setPowerDown(Bit#(1) pwdn);
endinterface

interface Ov7670ControllerIndication;
   method Action i2cResponse(Bit#(8) bus, Bit#(8) data);
   method Action vsync(Bit#(32) cycles, Bit#(1) href);
   method Action data(Bit#(1) first, Bit#(1) gap, Bit#(8) pxl);
   method Action data4(Bit#(32) pxls);
   method Action frameStarted(Bit#(1) first);
   method Action frameTransferred();
endinterface

interface Ov7670Pins;
   interface SCCB_Pins i2c0;
   interface SCCB_Pins i2c1;
   interface SCCB_Pins i2c2;
   interface Clock xclk;
   interface Clock pclk_deleteme_unused_clock;
   method bit reset();
   method bit pwdn();
   method Action pclk(Bit#(1) v);
   method Action pxl(Bit#(1) vsync, Bit#(1) href, Bit#(8) data);
endinterface
