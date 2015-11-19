module top(input CLK, input nRST);
  always @( posedge CLK) begin
    if (!nRST) then begin
    end
    else begin
//processing _ZN14EchoIndication4echoEi
        stop_main_program <= 1;

    end; // nRST
  end; // always @ (posedge CLK)
endmodule 

