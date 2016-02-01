module l_class_OC_Fifo (
    input CLK,
    input nRST,
    input in_enq__ENA,
    input [31:0]in_enq_v,
    output in_enq__RDY,
    input out_deq__ENA,
    output out_deq__RDY,
    output [31:0]out_first,
    output out_first__RDY);
    wire in_enq__RDY_internal;
    wire in_enq__ENA_internal = in_enq__ENA && in_enq__RDY_internal;
    assign in_enq__RDY = in_enq__RDY_internal;
    wire out_deq__RDY_internal;
    wire out_deq__ENA_internal = out_deq__ENA && out_deq__RDY_internal;
    assign out_deq__RDY = out_deq__RDY_internal;
    assign in_enq__RDY_internal = 0;
    assign out_deq__RDY_internal = 0;
    assign out_first = 0;
    assign out_first__RDY_internal = 0;
endmodule 

//METAGUARD; in_enq__RDY;         0;
//METAGUARD; out_deq__RDY;         0;
//METAGUARD; out_first__RDY;         0;
