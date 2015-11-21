interface L_class_OC_Echo;
    method Action rule_respond();
endinterface
import "BVI" l_class_OC_Echo =
module mkL_class_OC_Echo(L_class_OC_Echo);
    default_reset rst(nRST);
    default_clock clk(CLK);
    method rule_respond() enable(rule_respond__ENA) ready(rule_respond__RDY);
    schedule (rule_respond) CF (rule_respond);
endmodule
