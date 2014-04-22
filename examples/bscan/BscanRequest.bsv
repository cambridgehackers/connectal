
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

import BRAM   :: *;
import Bscan  :: *;
import GetPut :: *;

interface BscanIndication;
    method Action bscanGet(Bit#(32) v);
    //method Action addr(Bit#(32) v);
endinterface

interface BscanRequest;
   method Action bscanGet(Bit#(8) addr);
   method Action bscanPut(Bit#(8) addr, Bit#(32) v);
   method Action addr();
endinterface

module mkBscanRequest#(BscanIndication indication)(BscanRequest);

   Reg#(Bit#(8)) addrReg <- mkReg(0);

   BscanBram#(Bit#(8),Bit#(32)) bscanBram <- mkBscanBram(1, addrReg);
   //let bscan <- mkBscan(3);

    //rule bscanGetRule1;
       //let v <- bscan.update.get();
       //indication.bscanGet(v);
    //endrule

    rule bscanGetRule2;
       let v <- bscanBram.server.response.get();
       indication.bscanGet(v);
    endrule
   
   method Action bscanGet(Bit#(8) addr);
      bscanBram.server.request.put(BRAMRequest {write:False, responseOnWrite:False, address:addr, datain: ?});
   endmethod

   method Action bscanPut(Bit#(8) addr, Bit#(32) v);
      //bscan.capture.put(v);
      bscanBram.server.request.put(BRAMRequest {write:True, responseOnWrite:False, address:addr, datain: truncate(v)});
   endmethod
      
   //method Action addr();
      //indication.addr(extend(bscanBram.addr()));
   //endmethod

endmodule
