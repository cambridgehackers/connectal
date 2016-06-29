
import GetPut::*;
import FIFOF::*;
import Pipe::*;

interface SerialRequest;
   method Action tx(Bit#(8) c);
endinterface

interface SerialIndication;
   method Action rx(Bit#(8) c);
endinterface

interface SerialPort;
   interface PipeOut#(Bit#(8)) out;
   interface PipeIn#(Bit#(8)) in;
endinterface   
interface Serial;
   interface SerialRequest request;
   interface SerialPort port;
endinterface

module mkSerial#(SerialIndication indication)(Serial);
   FIFOF#(Bit#(8)) infifo <- mkSizedFIFOF(16);
   FIFOF#(Bit#(8)) outfifo <- mkSizedFIFOF(16);
   rule rl_in;
      let ch <- toGet(infifo).get();
      indication.rx(ch);
   endrule
   interface SerialRequest request;
      method Action tx(Bit#(8) c);
	 //$display("%h", c);
	 outfifo.enq(c);
      endmethod
   endinterface
   interface SerialPort port;
      interface PipeOut out = toPipeOut(outfifo);
      interface PipeIn  in  = toPipeIn(infifo);
   endinterface
endmodule
