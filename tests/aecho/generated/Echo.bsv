
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
        method messageSize_size size(messageSize_size_methodNumber) ready(RDY_messageSize_size);
    endinterface
    interface PipeOut indications;
        method deq() enable(EN_ind_deq) ready(RDY_ind_deq);
        method ind_first first() ready(RDY_ind_first);
        method ind_notEmpty notEmpty() ready(RDY_ind_notEmpty);
    endinterface
    interface PortalInterrupt intr;
        method intr_status status() ready(RDY_intr_status);
        method intr_channel channel() ready(RDY_intr_channel);
    endinterface
endmodule

(*synthesize*)
module mkEcho(Echo);
    let bvi <- mkEchoBVI;
    Vector#(1, PipeOut#(Bit#(SlaveDataBusWidth))) tmpInd;
    tmpInd[0] = bvi.indications;
    interface EchoRequest request = bvi.request;
    interface EchoIndicationPortalOutput lEchoIndicationOutput;
        interface PortalSize messageSize = bvi.messageSize;
        interface Vector indications = tmpInd;
        interface PortalInterrupt intr = bvi.intr;
    endinterface
endmodule
