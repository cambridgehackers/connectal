

interface UartRequest;
   method Action tx(Bit#(8) c);
endinterface

interface UartIndication;
   method Action rx(Bit#(8) c);
endinterface


interface Uart;
   interface UartRequest request;
endinterface

module mkUart#(UartIndication indication)(Uart);
   interface UartRequest request;
      method Action tx(Bit#(8) c);
	 $display("%h", c);
      endmethod
   endinterface
endmodule
