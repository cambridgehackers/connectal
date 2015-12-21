
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
        method say(request_say_v) ready(RDY_request_say) enable(EN_request_say);
    endinterface
    interface PortalSize messageSize;
        method messageSize_size size(messageSize_size_methodNumber) ready(RDY_messageSize_size);
    endinterface
    interface PipeOut indications;
        method deq() enable(EN_indications_0_deq) ready(RDY_indications_0_deq);
        method indications_0_notEmpty notEmpty() ready(RDY_indications_0_notEmpty);
        method indications_0_first first() ready(RDY_indications_0_first);
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
