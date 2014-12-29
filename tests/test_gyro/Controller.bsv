
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

import GetPut::*;
import Vector::*;

import Leds::*;
import ConnectalSpi::*;

interface GyroCtrlRequest;
   method Action write_reg(Bit#(8) addr, Bit#(8) val);
   method Action read_reg_req(Bit#(8) addr);
   method Action start_sampling(Bit#(32) freq);
endinterface

interface GyroCtrlIndication;
   method Action read_reg_resp(Bit#(16) val);
endinterface

interface Controller;
   interface GyroCtrlRequest req;
   interface SpiPins spi;
   interface LEDS leds;
endinterface



module mkController#(GyroCtrlIndication ind)(Controller);

   SPI#(Bit#(16)) spiController <- mkSPI(1000, True);
   Reg#(Bit#(32)) sampleFreq <- mkReg(0);
   Reg#(Bit#(32)) sampleCnt  <- mkReg(0);
   
   let out_X_L = 'h28;
   let out_X_H = 'h29;
   let out_Y_L = 'h2A;
   let out_Y_H = 'h2B;
   let out_Z_L = 'h2C;
   let out_Z_H = 'h2D;

   rule spi_response;
      let rv <- spiController.response.get;
      ind.read_reg_resp(rv);
   endrule
   
   rule sample (sampleFreq > 0);
      let new_sampleCnt = sampleCnt+1; 
      if (sampleCnt == sampleFreq) begin
	 spiController.request.put({1'b1,1'b1,out_X_L,8'h00});
	 new_sampleCnt = 0;
      end
      else if (sampleCnt == sampleFreq-1) 
	 spiController.request.put({1'b1,1'b1,out_Y_L,8'h00});
      else if (sampleCnt == sampleFreq-2) 
	 spiController.request.put({1'b1,1'b1,out_Z_L,8'h00});
      else
	 noAction;
      sampleCnt <= new_sampleCnt;
   endrule
   
   interface GyroCtrlRequest req;
      method Action write_reg(Bit#(8) addr, Bit#(8) val);
	 spiController.request.put({1'b0,1'b0,addr[5:0],val});
      endmethod
      method Action read_reg_req(Bit#(8) addr);
	 spiController.request.put({1'b1,1'b0,addr[5:0],8'h00});
      endmethod
      method Action start_sampling(Bit#(32) freq);
	 sampleFreq <= freq;
      endmethod
   endinterface
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = 0;
   endinterface
   interface SpiPins spi = spiController.pins;

endmodule
