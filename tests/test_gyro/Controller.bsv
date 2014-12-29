
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
   method Action write_reg(Bit#(32) addr, Bit#(32) val);
   method Action read_reg_req(Bit#(32) addr);
endinterface

interface GyroCtrlIndication;
   method Action read_reg_resp(Bit#(32) val);
endinterface

interface Controller;
   interface GyroCtrlRequest req;
   interface SpiPins spi;
   interface LEDS leds;
endinterface

module mkController#(GyroCtrlIndication ind)(Controller);

   SPI#(Bit#(16)) spiController <- mkSPI(1000, True);
   
   rule spi_response;
      let rv <- spiController.response.get;
      ind.read_reg_resp(extend(rv[7:0]));
   endrule
   
   interface GyroCtrlRequest req;
      method Action write_reg(Bit#(32) addr, Bit#(32) val);
	 spiController.request.put({1'b0,1'b0,addr[5:0],val[7:0]});
      endmethod
      method Action read_reg_req(Bit#(32) addr);
	 spiController.request.put({1'b1,1'b0,addr[5:0],8'h00});
      endmethod
   endinterface
   interface LEDS leds;
      method Bit#(LedsWidth) leds() = 0;
   endinterface
   interface SpiPins spi = spiController.pins;

endmodule
