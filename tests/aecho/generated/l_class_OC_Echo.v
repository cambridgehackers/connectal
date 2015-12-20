module l_class_OC_Echo (
    input CLK,
    input nRST,
    input respond_rule__ENA,
    output respond_rule__RDY,
    input say__ENA,
    input [31:0]say_v,
    output say__RDY,
    output ind$echo__ENA,
    output [31:0]ind$echo$v,
    input ind$echo__RDY);
wire fifo$CLK, fifo$nRST;
wire fifo$deq__ENA;
wire fifo$deq__RDY;
wire fifo$enq__ENA;
wire [31:0]fifo$enq_v;
wire fifo$enq__RDY;
wire [31:0]fifo$first;
wire fifo$first__RDY;
    l_class_OC_Fifo1 fifo (
        fifo$CLK,
        fifo$nRST,
        fifo$deq__ENA,
        fifo$deq__RDY,
        fifo$enq__ENA,
        fifo$enq_v,
        fifo$enq__RDY,
        fifo$first,
        fifo$first__RDY);
   reg[31:0] pipetemp;
    assign respond_rule__RDY =         (fifo$first__RDY) & (fifo$deq__RDY) & (ind$echo__RDY);
    assign say__RDY =         (fifo$enq__RDY);
        assign fifo$deq__ENA = respond_rule__ENA ? 1 : 0;
        assign ind$echo__ENA = respond_rule__ENA ? 1 : 0;
            assign ind$echo_v = respond_rule__ENA ? (fifo$first) : 0;

        assign fifo$enq__ENA = say__ENA ? 1 : 0;
            assign fifo$enq_v = say__ENA ? say_v : 0;

    always @( posedge CLK) begin
      if (!nRST) begin
        pipetemp <= 0;
      end // nRST
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; respond_rule__RDY;         (fifo$first__RDY) & (fifo$deq__RDY) & (ind$echo__RDY);
//METAGUARD; say__RDY;         (fifo$enq__RDY);
//METAINTERNAL; fifo; l_class_OC_Fifo1;
//METAEXTERNAL; ind; l_class_OC_EchoIndication;
//METAINVOKE; respond_rule; :fifo$deq:ind$echo:fifo$first;
//METAINVOKE; say; :fifo$enq;
