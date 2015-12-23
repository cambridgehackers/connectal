module l_class_OC_Echo (
    input CLK,
    input nRST,
    input respond_rule__ENA,
    output respond_rule__RDY,
    input say__ENA,
    input [31:0]say_v,
    output say__RDY,
    output ind$heard__ENA,
    output [31:0]ind$heard_v,
    input ind$heard__RDY);
    wire respond_rule__RDY_internal;
    wire respond_rule__ENA_internal = respond_rule__ENA && respond_rule__RDY_internal;
    assign respond_rule__RDY = respond_rule__RDY_internal;
    wire say__RDY_internal;
    wire say__ENA_internal = say__ENA && say__RDY_internal;
    assign say__RDY = say__RDY_internal;
    wire fifo$deq__RDY;
    wire fifo$first__RDY;
    l_class_OC_Fifo1 fifo (
        CLK,
        nRST,
        respond_rule__ENA_internal,
        fifo$deq__RDY,
        say__ENA_internal,
        say_v,
        say__RDY,
        ind$heard_v,
        fifo$first__RDY);
    reg[31:0] pipetemp;
    assign ind$heard__ENA = respond_rule__ENA_internal;
    assign respond_rule__RDY_internal = (fifo$first__RDY & fifo$deq__RDY) & ind$heard__RDY;

    always @( posedge CLK) begin
      if (!nRST) begin
        pipetemp <= 0;
      end // nRST
    end // always @ (posedge CLK)
endmodule 

//METAGUARD; respond_rule__RDY;         (fifo$first__RDY & fifo$deq__RDY) & ind$heard__RDY;
//METAGUARD; say__RDY;         fifo$enq__RDY;
//METAINVOKE; respond_rule; :fifo$deq:ind$heard:fifo$first;
//METAINVOKE; say; :fifo$enq;
//METAINTERNAL; fifo; l_class_OC_Fifo1;
//METAEXTERNAL; ind; l_class_OC_EchoIndication;
