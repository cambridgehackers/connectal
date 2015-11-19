interface L_class_OC_EchoTest;
    method Action rule_drive();
endinterface
import "BVI" l_class_OC_EchoTest =
module mkL_class_OC_EchoTest(L_class_OC_EchoTest);
    default_reset rst(nRST);
    default_clock clk(CLK);
    method rule_drive() enable(rule_drive__ENA) ready(rule_drive__RDY);
    schedule (rule_drive) CF (rule_drive);
endmodule
