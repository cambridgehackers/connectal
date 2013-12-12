
interface RingBuffer;
   method Action set(Bit#(2) regist, Bit#(40) addr);
   method Bit#(40) get(Bit#(2) regist);
//   method Get#(CommandStruct);
//   method Put#(StatusStruct);
endinterface

module mkRingBuffer(RingBuffer);
   
   Reg#(Bit#(40)) bufferbase <- mkReg(0);
   Reg#(Bit#(40)) bufferend <- mkReg(0);
   Reg#(Bit#(40)) bufferfirst <- mkReg(0);
   Reg#(Bit#(40)) bufferlast <- mkReg(0);
   
   method Action set(Bit#(2) regist, Bit#(40) addr);
      if (regist == 0) bufferbase <= addr;
      else if (regist == 1) bufferend <= addr;
      else if (regist == 2) bufferfirst <= addr;
      else bufferlast <= addr;
   endmethod
   
   method Bit#(40) get(Bit#(2) regist);
      if (regist == 0) return (bufferbase);
      else if (regist == 1) return (bufferend);
      else if (regist == 2) return (bufferfirst);
      else return(bufferlast);
   endmethod
endmodule
