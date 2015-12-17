module l_class_OC_Module (
    input CLK,
    input nRST);
  unsigned VERILOG_long long unused_data_to_force_inheritance;
    always @( posedge CLK) begin
      if (!nRST) begin
        unused_data_to_force_inheritance <= 0;
      end
      else begin
      end; // nRST
    end; // always @ (posedge CLK)
endmodule 

