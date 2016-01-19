// Copyright (c) 2016 Connectal Project

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

import Connectable::*;

(* always_ready, always_enabled *)
interface AxiStreamMaster#(numeric type dsz);
    method Bit#(dsz)              tdata();
    method Bit#(TDiv#(dsz,8))     tkeep();
    method Bit#(1)                tlast();
    method Action                 tready(Bit#(1) v);
    method Bit#(1)                tvalid();
endinterface

(* always_ready, always_enabled *)
interface AxiStreamSlave#(numeric type dsz);
    method Action      tdata(Bit#(dsz) v);
    method Action      tkeep(Bit#(TDiv#(dsz,8)) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tvalid(Bit#(1) v);
endinterface

instance Connectable#(AxiStreamMaster#(dataWidth), AxiStreamSlave#(dataWidth));
   module mkConnection#(AxiStreamMaster#(dataWidth) from, AxiStreamSlave#(dataWidth) to)(Empty);
      rule rl_axi_stream;
	 to.tdata(from.tdata());
	 to.tkeep(from.tkeep());
	 to.tlast(from.tlast());
	 to.tvalid(from.tvalid());
	 from.tready(to.tready());
      endrule
   endmodule
endinstance
