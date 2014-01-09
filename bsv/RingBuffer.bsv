// This is a fifo implmented with a ring buffer in main memory.
//
// SW->HW version
//  enqueue data in memory
//  update write pointer with portal request
// The hardware side activates when the write pointer is different than
// the read pointer, and copies data into an output BRAM fifo
//
// Software is responsible for knowing where the read pointer is,
// either by explicitly reading it with a portal-request -> portal indication
// or by other means
// 
// Configuration.  

interface RingBuffer;
   method Bool notEmpty();
   method Bool notFull();
   method Action push(UInt#(8) num);
   method Action pop(UInt#(8) num);
   interface Reg#(Bit#(40)) bufferfirst;
   interface Reg#(Bit#(40)) bufferlast;
   interface Reg#(Bool) enable;
   interface RingBufferConfig configifc;
endinterface

interface RingBufferConfig;
   method Action set(Bit#(2) regist, Bit#(40) addr);
   method Bit#(40) get(Bit#(2) regist);
endinterface


module mkRingBuffer(RingBuffer);
   
   Reg#(Bit#(40)) bufferbase <- mkReg(0);
   Reg#(Bit#(40)) bufferend <- mkReg(0);
   Reg#(Bit#(40)) bufferfirst <- mkReg(0);
   Reg#(Bit#(40)) bufferlast <- mkReg(0);
   Reg#(Bit#(40)) buffermask <- mkReg(0);
   Reg#(Bool) hwenable <- mkReg(False);
   
   interface RingBufferConfig configifc;
   method Action set(Bit#(2) regist, Bit#(40) addr);
      if (regist == 0) bufferbase <= addr;
      else if (regist == 1) bufferend <= addr;
      else if (regist == 2) bufferfirst <= addr;
      else if (regist == 3) bufferlast <= addr;
      else if (regist == 4) buffermask <= addr;
      else hwenable <= (addr[0] != 0);
   endmethod
   
   method Bit#(40) get(Bit#(2) regist);
      if (regist == 0) return (bufferbase);
      else if (regist == 1) return (bufferend);
      else if (regist == 2) return (bufferfirst);
      else if (regist == 3) return (bufferlast);
      else if (regist == 4) return (buffermask);
      else return(hwenable);
   endmethod
   endinterface

   method Bool notEmpty();
   return (bufferfirst != bufferlast);
   endmethod

   method Bool notFull();
   return (((bufferfirst + 64) & buffermask) != bufferlast);
   endmethod

   method Action push(UInt#(8) num);
   bufferfirst <= (bufferfirst + num) & buffermask;
   endmethod

   method Action pop(UInt#(8) num);
   bufferlast <= (bufferlast + num) & buffermask;
   endmethod
 
   interface Reg bufferFirst = bufferFirst;
   interface Reg bufferLast = bufferlast;
   interface Reg enable = hwenable;

endmodule
