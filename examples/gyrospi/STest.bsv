// Copyright (c) 2015 The Connectal Project

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
import ConnectalSpi::*;
import GetPut::*;

interface STestRequest;
   method Action request(Bit#(16) addr_data);
endinterface

interface STestIndication;
   method Action result(Bit#(16) val);
endinterface

interface STestPins;
   interface SpiMasterPins#(1) spi;
endinterface

interface STest;
   interface STestRequest request;
   interface STestPins pins;
endinterface

module mkSTest#(STestIndication indication)(STest);
   SPIMaster#(Bit#(16),1)  spiMaster <- mkSPIMaster(1000, True);
   Reg#(Bool) inUse <- mkReg(False);
   rule read_reg_resp;
      let rv <- spiMaster.response[0].get;
      indication.result(rv);
      inUse <= False;
   endrule
      
   interface STestRequest request;
      method Action request(Bit#(16) addr_data) if (!inUse);
         spiMaster.request[0].put(addr_data);
         inUse <= True;
      endmethod
   endinterface
   interface STestPins pins;
       interface SpiMasterPins spi = spiMaster.pins;
   endinterface
endmodule
