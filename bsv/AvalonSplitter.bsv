// Copyright (c) 2015 Connectal Project.

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

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import AvalonMasterSlave::*;

// AvalonMM interface is shared between read and write operations.
// There is an arbiter to control which operation get access to the Avalon Bus

interface AvalonArbiter#(numeric type addrWidth, numeric type dataWidth);
   interface Get#(AvalonMMRequest#(addrWidth, dataWidth)) toAvalon;
   interface Vector#(2, Put#(AvalonMMRequest#(addrWidth, dataWidth))) in;
endinterface

module mkAvalonArbiter(AvalonArbiter#(addrWidth, dataWidth));
   FIFO#(AvalonMMRequest#(addrWidth, dataWidth)) req_out_fifo <- mkFIFO();
   Vector#(2, FIFOF#(AvalonMMRequest#(addrWidth, dataWidth))) req_in_fifo <- replicateM(mkGFIFOF(False, True));
   Reg#(Maybe#(Bit#(1))) routeFrom <- mkReg(tagged Invalid);

   (* fire_when_enabled *)
   rule arbitrate_outgoing_request;
      if (routeFrom matches tagged Valid .port) begin
         if (req_in_fifo[port].notEmpty()) begin
            AvalonMMRequest#(addrWidth, dataWidth) req <- toGet(req_in_fifo[port]).get;
            req_out_fifo.enq(req);
            if (req.eof)
               routeFrom <= tagged Invalid;
         end
      end
      else begin
         Bool sentOne = False;
         for (Integer port=0; port<2; port=port+1) begin
            if (!sentOne && req_in_fifo[port].notEmpty()) begin
               AvalonMMRequest#(addrWidth, dataWidth) req <- toGet(req_in_fifo[port]).get;
               sentOne = True;
               if (req.sof) begin
                  req_out_fifo.enq(req);
                  if (!req.eof) begin
                     routeFrom <= tagged Valid fromInteger(port);
                  end
               end
            end
         end
      end
   endrule: arbitrate_outgoing_request
   Vector#(2, Put#(AvalonMMRequest#(addrWidth, dataWidth))) intemp;
   for (Integer i=0; i<2; i=i+1)
      intemp[i] = toPut(req_in_fifo[i]);
   interface in = intemp;
   interface Get toAvalon = toGet(req_out_fifo);
endmodule

