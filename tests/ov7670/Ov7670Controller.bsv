
// Copyright (c) 2015 Quanta Research Cambridge, Inc.

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
import ClientServer::*;
import I2C::*;
import Ov7670Interface::*;

interface Ov7670Controller;
   interface Ov7670ControllerRequest request;
   interface Ov7670Pins pins;
endinterface

module mkOv7670Controller#(Ov7670ControllerIndication ind)(Ov7670Controller);

   I2CController#(1) i2c <- mkI2CController();
   Reg#(bit) resetReg <- mkReg(0);
   rule i2c_response_rule;
      let response <- i2c.users[0].response.get();
      ind.probeResponse(response.data);
   endrule

   interface Ov7670ControllerRequest request;
      method Action probe(Bool write, Bit#(7) slaveaddr, Bit#(8) address, Bit#(8) data);
	 i2c.users[0].request.put(I2CRequest {write: write, slaveaddr: slaveaddr, address: address, data: data});
      endmethod
      method Action setReset(Bit#(1) rval);
	 resetReg <= rval;
      endmethod
   endinterface
   interface Ov7670Pins pins;
      interface I2C_Pins i2c = i2c.i2c;
      method bit reset() = resetReg;
   endinterface
endmodule
