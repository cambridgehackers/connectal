// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import FIFOF        :: *;
import Vector       :: *;
import GetPut       :: *;
import Connectable  :: *;
import MIMO         :: *;
import PCIE         :: *;
import DefaultValue :: *;
import ClientServer :: *;
import MemTypes     :: *;
import ConnectalConfig::*;

`include "ConnectalProjectConfig.bsv"

//
// Top interface: PCIe transaction level packets (TLPs)
// Bottom interface: MemMaster that sends read/write requests to an MemSlave
// Also sources interrupt MSIX requests
interface PcieToMem;
    interface Client#(TLPData#(16), TLPData#(16)) tlp;
    interface PhysMemMaster#(32,32) master;
endinterface

`ifdef XILINX
   `define AXI
`elsif SIMULATION
   `define AXI
`elsif ALTERA
   `define AVALON
`elsif VSIM
   `define AVALON
`endif


(* synthesize *)
module mkPcieToMem#(PciId my_id)(PcieToMem);
    Reg#(Bit#(7)) hitReg <- mkReg(0);
    FIFOF#(TLPMemoryIO3DWHeader) readHeaderFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) readDataFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) writeHeaderFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) writeDataFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPData#(16)) tlpOutFifo <- mkSizedFIFOF(8);
    Reg#(TLPTag) tlpTag <- mkReg(0);

    MIMOConfiguration mimoCfg = defaultValue;
    MIMO#(1,4,4,Bit#(32)) completionMimo <- mkMIMO(mimoCfg);
   Reg#(TLPLength)             readBurstCount <- mkReg(0);
   Reg#(LUInt#(4))     completionMimoDeqCount <- mkReg(0);
   Reg#(Bool)      readBurstCountGreaterThan4 <- mkReg(False);
   Reg#(Bool)                  readInProgress <- mkReg(False);
   Reg#(Bit#(7))               address <- mkReg(0);

   rule completionHeader if (!readInProgress && readDataFifo.notEmpty() && completionMimo.deqReadyN(1));
      let hdr = readDataFifo.first;
      TLPLength rbc = hdr.length;

      Vector#(4, Bit#(32)) dvec = unpack(0);
`ifdef AXI
      dvec = completionMimo.first();
      completionMimo.deq(1);
`elsif AVALON
      let quadWordAligned = isQuadWordAligned(getLowerAddr(hdr.addr, hdr.firstbe));
      // if quad-word aligned, insert bubble.
      if (!quadWordAligned) begin
         dvec = completionMimo.first();
         completionMimo.deq(1);
      end
`endif
      $display("completionHeader length=%d rbc=%d addr=%x", hdr.length, rbc, hdr.addr);
      TLPCompletionHeader completion = defaultValue;
      completion.format = MEM_WRITE_3DW_DATA;
      completion.pkttype = COMPLETION;
      completion.relaxed = hdr.relaxed;
      completion.nosnoop = hdr.nosnoop;
      completion.length = hdr.length;
      completion.tclass = hdr.tclass;
      completion.cmplid = my_id;
      completion.tag = truncate(hdr.tag);
      completion.bytecount = 4;
      completion.reqid = hdr.reqid;
      completion.loweraddr = getLowerAddr(hdr.addr, hdr.firstbe);
`ifdef AXI
      completion.data = byteSwap(dvec[0]);
`elsif AVALON
      if (!quadWordAligned) begin
         completion.data = (dvec[0]);
      end
      else begin
         completion.data = unpack(0);
      end
`endif
      TLPData#(16) tlp = defaultValue;
      tlp.data = pack(completion);
      tlp.sof = True;

`ifdef AXI
      tlp.eof = (rbc == 1) ? True : False;
`elsif AVALON
      tlp.eof = (rbc == 1 && !quadWordAligned) ? True : False;
`endif
      tlp.be = 16'hFFFF;
      tlp.hit = hitReg;
      tlpOutFifo.enq(tlp);

`ifdef AXI
      rbc = rbc - 1;
`elsif AVALON
      if (!quadWordAligned) begin
         rbc = rbc - 1;
      end
`endif
      readBurstCount <= rbc;
      completionMimoDeqCount <= truncate(min(4,unpack(rbc)));
      readInProgress <= (rbc != 0);
      readBurstCountGreaterThan4 <= (rbc > 4);
      if (rbc == 0) begin
	 readDataFifo.deq;
      end
   endrule

    function Bit#(16) tlpBe(TLPLength len);
       if (len == 0)
	  return 0;
       else if (len == 1)
	  return 16'hf000;
       else if (len == 2)
	  return 16'hff00;
       else if (len == 3)
	  return 16'hfff0;
       else
	  return 16'hffff;
    endfunction

   rule continuation if (readInProgress && completionMimo.deqReadyN(completionMimoDeqCount));
      let rbc = readBurstCount;
      TLPData#(16) tlp = defaultValue;
      Vector#(4, Bit#(32)) dvec = unpack(0);
      tlp.sof = False;
      dvec = completionMimo.first();
      completionMimo.deq(completionMimoDeqCount);

      if (readBurstCountGreaterThan4) begin
	 rbc = rbc - 4;
	 tlp.be = tlpBe(4);
	 tlp.eof = False;
      end
      else begin
	 tlp.be = tlpBe(rbc);
	 $display("tlp.data=%h tlp.be=%h", tlp.data, tlp.be);
	 tlp.eof = True;
	 rbc = 0;
      end

      readBurstCount <= rbc;
      completionMimoDeqCount <= truncate(min(4,unpack(rbc)));
      readBurstCountGreaterThan4 <= (rbc > 4);
      if (!readBurstCountGreaterThan4) begin
	 readDataFifo.deq();
	 readInProgress <= False;
      end
      for (Integer i = 0; i < 4; i = i + 1)
`ifdef AXI
	 tlp.data[(i+1)*32-1:i*32] = byteSwap(dvec[3-i]);
`elsif AVALON
	 tlp.data[(i+1)*32-1:i*32] = (dvec[3-i]);
         tlp.hit = hitReg;
`endif
      tlpOutFifo.enq(tlp);
   endrule

    interface Client        tlp;
    interface Put response;
        method Action put(TLPData#(16) tlp);
	    $display("PcieToMem.put tlp=%h", tlp);
	    TLPMemoryIO3DWHeader h = unpack(tlp.data);
	    hitReg <= tlp.hit;
	    TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
`ifdef AVALON
            // For Altera, the position of payload in a 3DW TLP depends on alignment.
            let quadWordAligned = isQuadWordAligned(getLowerAddr(hdr_3dw.addr, hdr_3dw.firstbe));
`endif
	    if (tlp.sof && hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
	       if (readHeaderFifo.notFull())
	          readHeaderFifo.enq(hdr_3dw);
	       else begin
		  // FIXME: should generate a response or host will lock up
	       end
	    end
	    else begin
               //FIXME: should rewrite to allow burst write.
               if (tlp.sof && writeHeaderFifo.notFull()) begin
		  writeHeaderFifo.enq(hdr_3dw);
               end
	    end
	endmethod
    endinterface
    interface Get request = toGet(tlpOutFifo);
    endinterface: tlp
    interface PhysMemMaster master;
    interface PhysMemWriteClient write_client;
        interface Get    writeReq;
	  method ActionValue#(PhysMemRequest#(32,32)) get();
	     let hdr = writeHeaderFifo.first;
	     writeHeaderFifo.deq;
	     writeDataFifo.enq(hdr);
	     let burstLen = extend(hdr.length << 2);
             $display("burstLen = %h", hdr.length << 2);
	     return PhysMemRequest { addr: extend(writeHeaderFifo.first.addr) << 2, burstLen: burstLen, tag: truncate(writeHeaderFifo.first.tag)
`ifdef BYTE_ENABLES
				    , firstbe: maxBound, lastbe: maxBound
`endif
};
	  endmethod
       endinterface
        interface Get writeData;
	  method ActionValue#(MemData#(32)) get();
	     let hdr <- toGet(writeDataFifo).get();
`ifdef AXI
	     let data = byteSwap(hdr.data);
`elsif AVALON
	     let data = hdr.data;
`endif
	     return MemData { data: data, tag: truncate(hdr.tag), last: True};
	  endmethod
       endinterface
        interface Put       writeDone;
	  method Action put(Bit#(MemTagSize) resp);
	  endmethod
       endinterface
     endinterface
    interface PhysMemReadClient read_client;
        interface Get    readReq;
	  method ActionValue#(PhysMemRequest#(32,32)) get();
	     let hdr = readHeaderFifo.first;
	     readHeaderFifo.deq;
	     //$display("req_ar hdr.length=%d hdr.addr=%h", hdr.length, hdr.addr);
	     readDataFifo.enq(hdr);
	     let burstLen = extend(hdr.length << 2);
	     return PhysMemRequest { addr: extend(readHeaderFifo.first.addr) << 2, burstLen: burstLen, tag: truncate(readHeaderFifo.first.tag)
`ifdef BYTE_ENABLES
				    , firstbe: maxBound, lastbe: maxBound
`endif
};
	    endmethod
       endinterface
        interface Put readData;
	  method Action put(MemData#(32) resp) if (completionMimo.enqReadyN(1));
	     Vector#(1, Bit#(32)) vec = cons(resp.data, nil);
	     completionMimo.enq(1, vec);
	  endmethod
	endinterface
    endinterface
    endinterface: master
endmodule: mkPcieToMem

interface MemInterrupt;
    interface Client#(TLPData#(16), TLPData#(16)) tlp;
    interface Put#(Tuple2#(Bit#(64),Bit#(32))) interruptRequest;
    interface Get#(Tuple2#(Bit#(64),Bit#(32))) interruptTrace;
endinterface

typedef struct {
   Bit#(64) addr;
   Bit#(32) data;
   Bool     mswIsZero;
   Bool     lswIsZero;
   } InterruptRequest deriving (Bits);

(* synthesize *)
module mkMemInterrupt#(PciId my_id)(MemInterrupt);
    FIFOF#(InterruptRequest) interruptRequestFifo <- mkFIFOF();
    FIFOF#(InterruptRequest) interruptTraceFifo <- mkSizedFIFOF(4);
    Reg#(Maybe#(Bit#(32))) interruptSecondHalf <- mkReg(tagged Invalid);
    Reg#(TLPTag) tlpTag <- mkReg(0);
    FIFOF#(TLPData#(16)) tlpOutFifo <- mkSizedFIFOF(8);

    function Bool isQuadWordAligned(Bit#(7) lower_addr);
       return (lower_addr[2:0]==3'b0);
    endfunction

    rule interruptTlpOut if (interruptRequestFifo.notEmpty &&& interruptSecondHalf matches tagged Invalid);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = True;
       tlp.eof = False;
       tlp.hit = 7'h00;
       tlp.be = 16'hffff;

       let deqInterruptRequestFifo = False;
       let sendInterrupt = False;

       let interruptRequest = interruptRequestFifo.first;
       let interruptAddr = interruptRequest.addr;
       let interruptData = interruptRequest.data;
       let mswIsZero = interruptRequest.mswIsZero;
       let lswIsZero = interruptRequest.lswIsZero;

`ifdef AXI
       let dataInSecondTlp = False;
`elsif AVALON
       let quadWordAligned = isQuadWordAligned(truncate(interruptAddr));
       let dataInSecondTlp = quadWordAligned;
`endif

       if (mswIsZero && lswIsZero) begin
	  // do not write to 0 -- it wedges the host
	  deqInterruptRequestFifo = True;
       end
       else if (mswIsZero) begin
          TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
          hdr_3dw.format = MEM_WRITE_3DW_DATA;
	  //hdr_3dw.pkttype = MEM_READ_WRITE;
          hdr_3dw.tag = tlpTag;
          hdr_3dw.reqid = my_id;
          hdr_3dw.length = 1;
          hdr_3dw.firstbe = '1;
          hdr_3dw.lastbe = '0;
          hdr_3dw.addr = interruptAddr[31:2];
`ifdef AXI
	  hdr_3dw.data = byteSwap(interruptData);
`elsif AVALON
	  hdr_3dw.data = interruptData;
`endif

	  tlp.data = pack(hdr_3dw);
          if (dataInSecondTlp) begin
	     tlp.eof = False;
             interruptSecondHalf <= tagged Valid interruptData;
          end
	  else begin
	     tlp.eof = True;
	     deqInterruptRequestFifo = True;
	  end
	  sendInterrupt = True;
       end
       else begin
	  TLPMemory4DWHeader hdr_4dw = defaultValue;
	  hdr_4dw.format = MEM_WRITE_4DW_DATA;
	  //hdr_4dw.pkttype = MEM_READ_WRITE;
	  hdr_4dw.tag = tlpTag;
	  hdr_4dw.reqid = my_id;
	  hdr_4dw.nosnoop = SNOOPING_REQD;
	  hdr_4dw.addr = interruptAddr[40-1:2];
	  hdr_4dw.length = 1;
	  hdr_4dw.firstbe = 4'hf;
	  hdr_4dw.lastbe = 0;
	  tlp.data = pack(hdr_4dw);

	  sendInterrupt = True;
	  interruptSecondHalf <= tagged Valid interruptData;
       end

       if (deqInterruptRequestFifo) begin
	  interruptRequestFifo.deq();
       end
       if (sendInterrupt)
	  tlpOutFifo.enq(tlp);
    endrule

    rule interruptTlpDataOut if (interruptSecondHalf matches tagged Valid .interruptData);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = False;
       tlp.eof = True;
       tlp.hit = 7'h00;
       tlp.be = 16'hf000;
`ifdef AXI
       tlp.data[7+8*15:8*12] = byteSwap(interruptData);
`elsif AVALON
       tlp.data[7+8*15:8*12] = interruptData;
`endif
       tlpOutFifo.enq(tlp);
       interruptSecondHalf <= tagged Invalid;
       interruptRequestFifo.deq();
    endrule

    interface Client        tlp;
    interface Put response;
        method Action put(TLPData#(16) tlp);
	endmethod
    endinterface
    interface Get request = toGet(tlpOutFifo);
    endinterface: tlp
    interface Put interruptRequest;
       method Action put(Tuple2#(Bit#(64),Bit#(32)) intr);
	  match { .addr, .data } = intr;
	  Bool mswIsZero = (addr[63:32] == 0);
	  Bool lswIsZero = (addr[31:0] == 0);
	  let interruptRequest = InterruptRequest { addr: addr, data: data, mswIsZero: mswIsZero, lswIsZero: lswIsZero };
          interruptRequestFifo.enq(interruptRequest);
	  if (interruptTraceFifo.notFull())
	      interruptTraceFifo.enq(interruptRequest);
       endmethod
    endinterface
    interface Get interruptTrace;
       method ActionValue#(Tuple2#(Bit#(64),Bit#(32))) get();
           let req = interruptTraceFifo.first();
           interruptTraceFifo.deq();
	   return tuple2(req.addr, req.data);
       endmethod
    endinterface
endmodule: mkMemInterrupt
