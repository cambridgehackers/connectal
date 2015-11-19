interface L_class_OC_Fifo;
endinterface
import "BVI" l_class_OC_Fifo =
module mkL_class_OC_Fifo(L_class_OC_Fifo);
    default_reset rst(nRST);
    default_clock clk(CLK);
    schedule () CF ();
endmodule
