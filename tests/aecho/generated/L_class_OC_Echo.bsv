interface L_class_OC_Echo;
    method Action echoReq(Bit#(32) v);
    method Action respond_rule();
endinterface
import "BVI" l_class_OC_Echo =
module mkL_class_OC_Echo(L_class_OC_Echo);
    default_reset rst(nRST);
    default_clock clk(CLK);
    method echoReq(echoReq_v) enable(echoReq__ENA) ready(echoReq__RDY);
    method respond_rule() enable(respond_rule__ENA) ready(respond_rule__RDY);
    schedule (echoReq, respond_rule) CF (echoReq, respond_rule);
endmodule
