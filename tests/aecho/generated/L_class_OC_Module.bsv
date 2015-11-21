interface L_class_OC_Module;
endinterface
import "BVI" l_class_OC_Module =
module mkL_class_OC_Module(L_class_OC_Module);
    default_reset rst(nRST);
    default_clock clk(CLK);
    schedule () CF ();
endmodule
