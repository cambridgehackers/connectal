module l_class_OC_EchoTest (
    input CLK,
    input nRST,
    output rule_drive__RDY,
    input rule_drive__ENA);

  ;
   reg[31:0] x;
  always @( posedge CLK) begin
    if (!nRST) begin
    end
    else begin
        // Method: rule_drive__RDY
    rule_drive__RDY_tmp__1 = ((*((echo)->fifo)).enq__RDY);
        rule_drive__RDY = rule_drive__RDY_tmp__1;

        // Method: rule_drive
        if (rule_drive__ENA) begin
        ((*((echo)->fifo)).enq);
        end; // End of rule_drive

    end; // nRST
  end; // always @ (posedge CLK)
endmodule 

