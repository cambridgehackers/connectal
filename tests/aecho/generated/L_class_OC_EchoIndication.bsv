interface L_class_OC_EchoIndication;
endinterface
import "BVI" l_class_OC_EchoIndication =
module mkL_class_OC_EchoIndication(L_class_OC_EchoIndication);
    default_reset rst(nRST);
    default_clock clk(CLK);
    schedule () CF ();
endmodule
