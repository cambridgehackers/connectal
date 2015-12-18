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
   reg[31:0] element;
   reg full;
    assign deq__RDY =         (full);
    assign enq__RDY =         ((full) ^ 1);
    assign first =         (element);
    assign first__RDY =         (full);


    always @( posedge CLK) begin
      if (!nRST) begin
        element <= 0;
        full <= 0;
      end
      else begin
        if (deq__ENA) begin
        full <= 0;
        end; // End of deq
        if (enq__ENA) begin
        element <= enq_v;
        full <= 1;
        end; // End of enq
      end // nRST
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; deq__RDY;         (full);
//METAGUARD; enq__RDY;         ((full) ^ 1);
//METAGUARD; first__RDY;         (full);
//METAREAD; first; :element;
//METAWRITE; deq; :full;
//METAWRITE; enq; :element:full;
