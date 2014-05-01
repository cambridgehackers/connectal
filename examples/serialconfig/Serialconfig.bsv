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

import FIFO::*;

interface SerialconfigIndication;
    method Action writeack(Bit#(32) a);
    method Action readdata(Bit#(32) a, Bit#(32) d );
endinterface

interface SerialconfigRequest;
   method Action read(Bit#(32) a);
   method Action write(Bit#(32) a, Bit#(32) d);
endinterface

typedef struct {
   Bit#(1) dowrite;
   Bit#(32) a;
   Bit#(32) d;
   } Cmd deriving(Bits);


module mkSerialconfigRequest#(SerialconfigIndication indication)(SerialconfigRequest);

    FIFO#(Cmd) cmd <- mkSizedFIFO(8);

    rule echo;
	cmd.deq;
       if (cmd.first.dowrite == 1)
          indication.writeack(cmd.first.a);
       else
          indication.readdata(cmd.first.a, cmd.first.d);
    endrule


   method Action read(Bit#(32) a);
      cmd.enq(Cmd{dowrite: 0, a: a, d: ?});
   endmethod
   
   method Action write(Bit#(32) a, Bit#(32) d);
      cmd.enq(Cmd{dowrite: 1, a: a, d: ?});
   endmethod
      
endmodule
