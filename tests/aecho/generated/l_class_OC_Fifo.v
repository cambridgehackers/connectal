module l_class_OC_Fifo (
    input CLK,
    input nRST,
    input deq__ENA,
    output deq__RDY,
    input enq__ENA,
    input [31:0]enq_v,
    output enq__RDY,
    output [31:0]first,
    output first__RDY);
    assign deq__RDY =         0;
    assign enq__RDY =         0;
    assign first =         0;
    assign first__RDY =         0;


    always @( posedge CLK) begin
      if (!nRST) begin
      end // nRST
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; deq__RDY;         0;
//METAGUARD; enq__RDY;         0;
//METAGUARD; first__RDY;         0;
