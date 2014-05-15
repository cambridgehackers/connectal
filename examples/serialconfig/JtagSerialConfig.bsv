// Copyright (c) 2014 Quanta Research Cambridge, Inc.
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

import JtagTap::*;

interface SerialconfigIndication;
   method Action sendack(Bit#(32) tms, Bit#(32) tdi);
   method Action recvack(Bit#(32) tdo);
   method Action stateack(Bit#(32) s1, Bit#(32) s2);
endinterface
      
interface SerialconfigRequest;
   method Action write(Bit#(32) tms, Bit#(32) tdi);
   method Action read();
   method Action getstate();
endinterface

module mkSerialconfigRequest#(SerialconfigIndication indication)(SerialconfigRequest);

   JtagTap tap1 <- mkJtagTap('hdeadbeef);
   JtagTap tap2 <- mkJtagTap('hfeedface);
   
   method Action read();
      indication.recvack(zeroExtend(tap2.tdo));
   endmethod
   
   method Action write(Bit#(32) tms, Bit#(32) tdi);
      tap1.tms(tms[0]);
      tap2.tms(tms[0]);
      tap1.tdi(tdi[0]);
      tap2.tdi(tap1.tdo);
      indication.sendack(zeroExtend(tms), zeroExtend(tdi));
   endmethod
   
   method Action getstate();
      indication.stateack(zeroExtend(pack(tap1.getstate)), zeroExtend(pack(tap2.getstate)));
   endmethod
   
endmodule
