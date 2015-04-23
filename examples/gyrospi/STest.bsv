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
   method Action write_reg(Bit#(8) addr, Bit#(8) val);
   method Action read_reg(Bit#(8) addr);
endinterface

interface STestIndication;
   method Action result(Bit#(16) val);
endinterface

interface STest;
   interface STestRequest request;
   interface SpiMasterPins pins;
endinterface

module mkSTest#(STestIndication indication)(STest);
   SPIMaster#(Bit#(16))  spiMaster <- mkSPIMaster(1000, True);
   rule read_reg_resp;
      let rv <- spiMaster.response.get;
      indication.result(rv);
   endrule
      
   interface STestRequest request;
      method Action write_reg(Bit#(8) addr, Bit#(8) val);
         spiMaster.request.put({1'b0,1'b0,addr[5:0],val});
      endmethod
      method Action read_reg(Bit#(8) addr);
         spiMaster.request.put({1'b1,1'b0,addr[5:0],8'h00});
      endmethod
   endinterface
   interface SpiMasterPins pins = spiMaster.pins;
endmodule
