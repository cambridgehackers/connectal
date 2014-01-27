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
   interface Reg#(DmaAddrSize) bufferfirst;
   interface Reg#(DmaAddrSize) bufferlast;
   interface Reg#(Bool) enable;
   interface RingBufferConfig configifc;
   interface Reg#(DmaMemHandle) memhandle;
endinterface

interface RingBufferConfig;
   method Action set(Bit#(2) regist, Bit#(40) addr);
   method Bit#(40) get(Bit#(2) regist);
endinterface


module mkRingBuffer(RingBuffer);
   
   Reg#(Bit#(DmaAddrSize)) rbufferbase <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) rbufferend <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) rbufferfirst <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) rbufferlast <- mkReg(0);
   Reg#(Bit#(DmaAddrSize)) rbuffermask <- mkReg(0);
   Reg#(DmaMemHandle) rmemhandle <- mkReg(0);
   Reg#(Bool) renable <- mkReg(False);
   
   interface RingBufferConfig configifc;
   method Action set(Bit#(2) regist, Bit#(40) addr);
      if (regist == 0) rbufferbase <= addr;
      else if (regist == 1) rbufferend <= addr;
      else if (regist == 2) rbufferfirst <= addr;
      else if (regist == 3) rbufferlast <= addr;
      else if (regist == 4) rbuffermask <= addr;
      else if (regist == 5) rmemhandle <= truncate(addr);
      else renable <= (addr[0] != 0);
   endmethod
   
   method Bit#(40) get(Bit#(2) regist);
      if (regist == 0) return (rbufferbase);
      else if (regist == 1) return (rbufferend);
      else if (regist == 2) return (rbufferfirst);
      else if (regist == 3) return (rbufferlast);
      else if (regist == 4) return (rbuffermask);
      else if (regist == 5) return (zeroExtend(rmemhandle));
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
   interface Reg memhandle = rmemhandle;

endmodule
