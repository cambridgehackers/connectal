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
   method Action push(Bit#(8) num);
   method Action pop(Bit#(8) num);
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
   
   Reg#(Bit#(40)) rbufferbase <- mkReg(0);
   Reg#(Bit#(40)) rbufferend <- mkReg(0);
   Reg#(Bit#(40)) rbufferfirst <- mkReg(0);
   Reg#(Bit#(40)) rbufferlast <- mkReg(0);
   Reg#(Bit#(40)) rbuffermask <- mkReg(0);
   Reg#(Bool) renable <- mkReg(False);
   
   interface RingBufferConfig configifc;
   method Action set(Bit#(2) regist, Bit#(40) addr);
      if (regist == 0) rbufferbase <= addr;
      else if (regist == 1) rbufferend <= addr;
      else if (regist == 2) rbufferfirst <= addr;
      else if (regist == 3) rbufferlast <= addr;
      else if (regist == 4) rbuffermask <= addr;
      else renable <= (addr[0] != 0);
   endmethod
   
   method Bit#(40) get(Bit#(2) regist);
      if (regist == 0) return (rbufferbase);
      else if (regist == 1) return (rbufferend);
      else if (regist == 2) return (rbufferfirst);
      else if (regist == 3) return (rbufferlast);
      else if (regist == 4) return (rbuffermask);
      else return(zeroExtend(pack(renable)));
   endmethod
   endinterface

   method Bool notEmpty();
   return (rbufferfirst != rbufferlast);
   endmethod

   method Bool notFull();
   return (((rbufferfirst + 64) & rbuffermask) != rbufferlast);
   endmethod

   method Action push(Bit#(8) num);
   rbufferfirst <= (rbufferfirst + zeroExtend(num)) & rbuffermask;
   endmethod

   method Action pop(Bit#(8) num);
   rbufferlast <= (rbufferlast + zeroExtend(num)) & rbuffermask;
   endmethod
 
   interface Reg bufferfirst = rbufferfirst;
   interface Reg bufferlast = rbufferlast;
   interface Reg enable = renable;

endmodule
