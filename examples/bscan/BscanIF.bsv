
// Copyright (c) 2013 Nokia, Inc.
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

import BRAM         :: *;
import Bscan        :: *;
import GetPut       :: *;
import Connectable  :: *;
import DefaultValue :: *;
import Clocks       :: *;
import HostInterface:: *;

interface BscanIndication;
    method Action bscanGet(Bit#(64) v);
endinterface

interface BscanRequest;
   method Action bscanGet(Bit#(8) addr);
   method Action bscanPut(Bit#(8) addr, Bit#(64) v);
endinterface

interface BscanIF;
   interface BscanRequest request;
endinterface

module mkBscanIF#(HostInterface host, BscanIndication indication)(BscanIF);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   Reg#(Bit#(8)) addrReg <- mkReg(0);

   BscanBram#(Bit#(8),Bit#(64)) bscanBram <- mkBscanBram(123, addrReg, host.bscan);
   let bram <- mkBRAM2Server(defaultValue);
   mkConnection(bscanBram.bramClient, bram.portB);
   rule tdorule;
      host.bscan.tdo(bscanBram.data_out());
   endrule

   rule bscanGetRule2;
      let v <- bram.portA.response.get();
      indication.bscanGet(v);
   endrule
   
   interface BscanRequest request;
   method Action bscanGet(Bit#(8) addr);
      bram.portA.request.put(BRAMRequest {write:False, responseOnWrite:False, address:addr, datain: ?});
   endmethod
   
   method Action bscanPut(Bit#(8) addr, Bit#(64) v);
      bram.portA.request.put(BRAMRequest {write:True, responseOnWrite:False, address:addr, datain: truncate(v)});
   endmethod
   endinterface
endmodule
