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

import AxiStream::*;
import Vector::*;
import ConnectalConfig::*;
`include "ConnectalProjectConfig.bsv"

typedef `PcieDataBusWidth PcieDataBusWidth;

typedef enum { DMA_RX, DMA_TX, DMA_SG } DmaChannel deriving (Bits,Eq);

interface MemServerPortalRequest;
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(DataBusWidth) data);
endinterface

interface MemServerPortalIndication;
   method Action readDone(Bit#(DataBusWidth) data);
   method Action writeDone();
endinterface

interface NvmeRequest;
   method Action startTransfer(Bit#(8) opcode, Bit#(8) flags, Bit#(16) requestId, Bit#(64) startBlock, Bit#(32) numBlocks, Bit#(32) dsm);
   method Action msgOut(Bit#(32) value);
endinterface

interface NvmeIndication;
   method Action transferCompleted(Bit#(16) requestId, Bit#(64) sc, Bit#(32) cycles);
   method Action msgIn(Bit#(32) value);
endinterface

// internal interfaces
interface NvmeDriverRequest;
   method Action read32(Bit#(32) addr);
   method Action write32(Bit#(32) addr, Bit#(32) data);
   method Action read(Bit#(32) addr);
   method Action write(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action readCtl(Bit#(32) addr);
   method Action writeCtl(Bit#(32) addr, Bit#(DataBusWidth) data);
   method Action status();
   method Action trace(Bool enabled);
endinterface

interface NvmeDriverIndication;
   method Action readDone(Bit#(DataBusWidth) data);
   method Action writeDone();
   method Action status(Bit#(1) mmcm_lock, Bit#(32) dataCounter);
   method Action setupComplete();
endinterface

interface NvmeTrace;
   method Action traceDmaRequest(DmaChannel channel, Bool write, Bit#(16) objId, Bit#(64) offset, Bit#(16) burstLen, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceDmaData(DmaChannel channel, Bool write, Vector#(TDiv#(PcieDataBusWidth,32),Bit#(32)) data, Bool last, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceDmaDone(DmaChannel channel, Bit#(8) tag, Bit#(32) timestamp);
   method Action traceData(Vector#(TDiv#(PcieDataBusWidth,32),Bit#(32)) data, Bool last, Bit#(8) tag, Bit#(32) timestamp);
endinterface
