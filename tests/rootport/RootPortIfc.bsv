// Copyright (c) 2016 Connectal Project

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

import ConnectalConfig::*;

typedef enum { DMA_RX, DMA_TX, DMA_SG } DmaChannel deriving (Bits,Eq);

interface RootPortRequest;
   method Action read32(Bit#(32) addr);
   method Action write32(Bit#(32) addr, Bit#(32) data);
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action readCtl(Bit#(32) addr);
   method Action writeCtl(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action status();
endinterface

interface RootPortIndication;
   method Action readDone(Bit#(DataBusWidth) data);
   method Action writeDone();
   method Action status(Bit#(1) mmcm_lock);
endinterface

interface RootPortTrace;
   method Action traceDmaRequest(DmaChannel channel, Bool write, Bit#(16) objId, Bit#(DataBusWidth) offset, Bit#(16) burstLen, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceDmaData(DmaChannel channel, Bool write, Bit#(DataBusWidth) data, Bool last, Bit#(8) tag, Bit#(32) timestamp);
endinterface
