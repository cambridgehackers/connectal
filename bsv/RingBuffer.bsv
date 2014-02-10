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
import Dma::*;

interface RingBuffer;
   method Bool notEmpty();
   method Bool notFull();
   method Action push(Bit#(8) num);
   method Action pop(Bit#(8) num);
   interface Reg#(Bit#(DmaOffsetSize)) bufferfirst;
   interface Reg#(Bit#(DmaOffsetSize)) bufferlast;
   interface Reg#(Bool) enable;
   interface RingBufferConfig configifc;
   interface Reg#(DmaPointer) memhandle;
endinterface

interface RingBufferConfig;
   method Action set(Bit#(3) regist, Bit#(DmaOffsetSize) addr);
   method Bit#(DmaOffsetSize) get(Bit#(3) regist);
endinterface


module mkRingBuffer(RingBuffer);
   
   Reg#(Bit#(DmaOffsetSize)) rbufferbase <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) rbufferend <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) rbufferfirst <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) rbufferlast <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize)) rbuffermask <- mkReg(0);
   Reg#(DmaPointer) rmemhandle <- mkReg(0);
   Reg#(Bool) renable <- mkReg(False);
   
   interface RingBufferConfig configifc;
   method Action set(Bit#(3) regist, Bit#(DmaOffsetSize) addr);
      if (regist == 0) rbufferbase <= truncate(addr);
      else if (regist == 1) rbufferend <= truncate(addr);
      else if (regist == 2) rbufferfirst <= truncate(addr);
      else if (regist == 3) rbufferlast <= truncate(addr);
      else if (regist == 4) rbuffermask <= truncate(addr);
      else if (regist == 5) rmemhandle <= truncate(addr);
      else renable <= (addr[0] != 0);
   endmethod
   
   method Bit#(DmaOffsetSize) get(Bit#(3) regist);
      if (regist == 0) return (zeroExtend(rbufferbase));
      else if (regist == 1) return (zeroExtend(rbufferend));
      else if (regist == 2) return (zeroExtend(rbufferfirst));
      else if (regist == 3) return (zeroExtend(rbufferlast));
      else if (regist == 4) return (zeroExtend(rbuffermask));
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
