module l_class_OC_Fifo1 (
    input CLK,
    input nRST,
    input deq__ENA,
    output deq__RDY,
    input enq__ENA,
    input [31:0]enq_v,
    output enq__RDY,
    output [31:0]first,
    output first__RDY);
    wire deq__RDY_internal;
    wire deq__ENA_internal = deq__ENA && deq__RDY_internal;
    assign deq__RDY = deq__RDY_internal;
    wire enq__RDY_internal;
    wire enq__ENA_internal = enq__ENA && enq__RDY_internal;
    assign enq__RDY = enq__RDY_internal;
    reg[31:0] element;
    reg full;
    assign deq__RDY_internal = full;
    assign enq__RDY_internal = full ^ 1;
    assign first = element;
    assign first__RDY_internal = full;

    always @( posedge CLK) begin
      if (!nRST) begin
        element <= 0;
        full <= 0;
      end // nRST
      else begin
        if (deq__ENA_internal) begin
            full <= 0;
        end; // End of deq
        if (enq__ENA_internal) begin
            element <= enq_v;
            full <= 1;
        end; // End of enq
      end
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; deq__RDY;         full;
//METAGUARD; enq__RDY;         full ^ 1;
//METAGUARD; first__RDY;         full;
//METAWRITE; deq; :full;
//METAWRITE; enq; :element:full;
//METAREAD; first; :element;
