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
import ConnectalConfig::*;
import Portal::*;
import Pipe::*;
import Vector::*;
import EchoReq::*;
import EchoIndication::*;

interface Echo;
   interface EchoRequest request;
   interface EchoIndicationPortalOutput lEchoIndicationOutput;
endinterface

interface EchoBVI;
   interface EchoRequest request;
   interface PortalSize messageSize;
   interface PipeOut#(Bit#(SlaveDataBusWidth)) indications;
   interface PortalInterrupt#(SlaveDataBusWidth) intr;
endinterface

import "BVI" EchoVerilog =
module mkEchoBVI(EchoBVI);
    default_clock clk();
    default_reset rst();
    interface EchoRequest request;
        method say(request_say_v) enable(EN_request_say) ready(RDY_request_say);
    endinterface
    interface PortalSize messageSize;
        method lEchoIndicationOutput_messageSize_size size(lEchoIndicationOutput_messageSize_size_methodNumber) ready(RDY_lEchoIndicationOutput_messageSize_size);
    endinterface

    interface PipeOut indications;
        method deq() enable(EN_lEchoIndicationOutput_indications_0_deq) ready(RDY_lEchoIndicationOutput_indications_0_deq);
        method lEchoIndicationOutput_indications_0_first first() ready(RDY_lEchoIndicationOutput_indications_0_first);
        method lEchoIndicationOutput_indications_0_notEmpty notEmpty() ready(RDY_lEchoIndicationOutput_indications_0_notEmpty);
    endinterface
    interface PortalInterrupt intr;
        method lEchoIndicationOutput_intr_status status() ready(RDY_lEchoIndicationOutput_intr_status);
        method lEchoIndicationOutput_intr_channel channel() ready(RDY_lEchoIndicationOutput_intr_channel);
    endinterface
endmodule

(*synthesize*)
module mkEcho(Echo);
    let echo <- mkEchoBVI;
    Vector#(1, PipeOut#(Bit#(SlaveDataBusWidth))) tmpInd;
    tmpInd[0] = echo.indications;
    interface EchoRequest request = echo.request;
    interface EchoIndicationPortalOutput lEchoIndicationOutput;
        interface PortalSize messageSize = echo.messageSize;
        interface Vector indications = tmpInd;
        interface PortalInterrupt intr = echo.intr;
    endinterface
endmodule
