interface L_class_OC_Fifo;
    method Action deq();
    method Action enq(Bit#(32) v);
    method Bit#(32) first();
endinterface
import "BVI" l_class_OC_Fifo =
module mkL_class_OC_Fifo(L_class_OC_Fifo);
    default_reset rst(nRST);
    default_clock clk(CLK);
    method deq() enable(deq__ENA) ready(deq__RDY);
    method enq(enq_v) enable(enq__ENA) ready(enq__RDY);
    method first first() ready(first__RDY);
    schedule (deq, enq, first) CF (deq, enq, first);
endmodule
