// Copyright (c) 2013 Nokia, Inc.
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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
import EchoReq::*;
import EchoIndication::*;
import L_class_OC_Fifo1::*;

interface Echo;
   interface EchoRequest request;
   interface EchoIndicationPortalOutput lEchoIndicationOutput;
endinterface

(*synthesize*)
module mkEcho(Echo);
    EchoIndicationOutput myEchoIndicationOutput <- mkEchoIndicationOutput;
    EchoIndication indication = myEchoIndicationOutput.ifc;
    //FIFO#(Bit#(32)) delay <- mkSizedFIFO(8);
    L_class_OC_Fifo1 delay <- mkL_class_OC_Fifo1;
    rule heard;
        delay.deq;
        indication.heard(delay.first);
    endrule

    interface EchoIndicationPortalOutput lEchoIndicationOutput = myEchoIndicationOutput.portalIfc;
    interface EchoRequest request;
       method Action say(Bit#(32) v);
	  delay.enq(v);
       endmethod
    endinterface
endmodule
