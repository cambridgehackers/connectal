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
   method Action sendack(bit tms, bit tdi);
   method Action recvack(bit tdo);
   method Action stateack(TapState s1, TapState s2);
endinterface
      
interface SerialconfigRequest;
   method Action write(bit tms, bit tdi);
   method Action read();
   method Action getstate();
endinterface

module mkSerialconfigRequest#(SerialconfigIndication indication)(SerialconfigRequest);

   JtagTap tap1 <- mkJtagTap('hdeadbeef);
   JtagTap tap2 <- mkJtagTap('hfeedface);
   
   method Action read();
      indicaton.recv(tap2.tdo);
   endmethod
   
   method Action write(bit tms, bit tdi);
      tap1.tms(tms);
      tap2.tms(tms);
      tap1.tdi(tdi);
      tap2.tdi(tap1.tdo);
      indication.sendack(tms, tdi);
   endmethod
   
   method Action getstate();
      indication.stateack(tap1.getstate, tap2.getstate);
   endmethod
   
endmodule
