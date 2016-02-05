module l_class_OC_Fifo1 (
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
    reg[31:0] element;
    reg full;
    assign in_enq__RDY_internal = full ^ 1;
    assign out_deq__RDY_internal = full;
    assign out_first = element;
    assign out_first__RDY_internal = full;

    always @( posedge CLK) begin
      if (!nRST) begin
        element <= 0;
        full <= 0;
      end // nRST
      else begin
        if (in_enq__ENA_internal) begin
            element <= in_enq_v;
            full <= 1;
        end; // End of in_enq
        if (out_deq__ENA_internal) begin
            full <= 0;
        end; // End of out_deq
      end
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; in_enq__RDY;         full ^ 1;
//METAGUARD; out_deq__RDY;         full;
//METAGUARD; out_first__RDY;         full;
//METAWRITE; in_enq; :;element:;full;
//METAWRITE; out_deq; :;full;
//METAREAD; out_first; :;element;
