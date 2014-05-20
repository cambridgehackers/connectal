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

import AxiMasterSlave :: *;

//
// Top interface: PCIe transaction level packets (TLPs)
// Bottom interface: AXI3 Master that sends read/write requests to an Axi3Slave
// Also sources interrupt MSIX requests
interface AxiMasterEngine;
    interface Put#(TLPData#(16))   inFromTlp;
    interface Get#(TLPData#(16))   outToTlp;
    interface Axi3Master#(32,32,12) master;
    interface Put#(Tuple2#(Bit#(64),Bit#(32))) interruptRequest;
    interface Reg#(Bit#(12))       bTag;
endinterface

(* synthesize *)
module mkAxiMasterEngine#(PciId my_id)(AxiMasterEngine);
    FIFOF#(Tuple2#(Bit#(64),Bit#(32))) interruptRequestFifo <- mkSizedFIFOF(16);
    Reg#(Maybe#(Bit#(32))) interruptSecondHalf <- mkReg(tagged Invalid);
    Reg#(Bit#(7)) hitReg <- mkReg(0);
    Reg#(Bit#(4)) timerReg <- mkReg(0);
    FIFOF#(TLPMemoryIO3DWHeader) readHeaderFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) readDataFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) writeHeaderFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPMemoryIO3DWHeader) writeDataFifo <- mkSizedFIFOF(8);
    FIFOF#(TLPData#(16)) tlpOutFifo <- mkSizedFIFOF(8);
    Reg#(TLPTag) tlpTag <- mkReg(0);
    Reg#(Bit#(12)) bTagReg <- mkReg(0);

    MIMOConfiguration mimoCfg = defaultValue;
    MIMO#(1,4,16,Bit#(32)) completionMimo <- mkMIMO(mimoCfg);
   Reg#(TLPLength) readBurstCount <- mkReg(0);
   rule completionHeader if (readBurstCount == 0 && readDataFifo.notEmpty() && completionMimo.deqReadyN(1) &&& interruptSecondHalf matches tagged Invalid);
      let hdr = readDataFifo.first;
      TLPLength rbc = hdr.length;

      Vector#(4, Bit#(32)) dvec = completionMimo.first();
      completionMimo.deq(1);

      //$display("completionHeader length=%d rbc=%d addr=%x", hdr.length, rbc, hdr.addr);
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
      completion.data = byteSwap(dvec[0]);
      TLPData#(16) tlp = defaultValue;
      tlp.data = pack(completion);
      tlp.sof = True;
      tlp.eof = (rbc == 1) ? True : False;
      tlp.be = 16'hFFFF;
      tlp.hit = hitReg;
      tlpOutFifo.enq(tlp);

      rbc = rbc - 1;
      readBurstCount <= rbc;
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

   rule continuation if (readBurstCount > 0);
      let rbc = readBurstCount;
      let sendit = False;
      TLPData#(16) tlp = defaultValue;
      Vector#(4, Bit#(32)) dvec = unpack(0);
      tlp.sof = False;
      //$display("continuation rbc=%d", rbc);
      if (rbc > 4) begin
	 if (completionMimo.deqReadyN(4)) begin
	    rbc = rbc - 4;
	    dvec = completionMimo.first();
	    completionMimo.deq(4);
	    tlp.be = tlpBe(4);
	    tlp.eof = False;
	    sendit = True;
	 end
      end
      else begin
	 UInt#(3) deqCount = truncate(unpack(rbc));
	 if (completionMimo.deqReadyN(deqCount)) begin
	    dvec = completionMimo.first();
	    completionMimo.deq(deqCount);
	    tlp.be = tlpBe(rbc);
	    //$display("tlp.data=%h tlp.be=%h", tlp.data, tlp.be);
	    tlp.eof = True;
	    rbc = 0;
	    sendit = True;
	 end
      end

      readBurstCount <= rbc;
      if (rbc == 0) begin
	 readDataFifo.deq();
      end
      if (sendit) begin
	 for (Integer i = 0; i < 4; i = i + 1)
	    tlp.data[(i+1)*32-1:i*32] = byteSwap(dvec[3-i]);
	 tlpOutFifo.enq(tlp);
      end
   endrule
   rule txnTimer if (timerReg > 0);
      timerReg <= timerReg - 1;
   endrule

    rule interruptTlpOut if (interruptRequestFifo.notEmpty &&& interruptSecondHalf matches tagged Invalid);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = True;
       tlp.eof = False;
       tlp.hit = 7'h00;
       tlp.be = 16'hffff;

       let interruptRequested = True;
       let sendInterrupt = False;

       Bit#(64) interruptAddr = tpl_1(interruptRequestFifo.first);
       Bit#(32) interruptData = tpl_2(interruptRequestFifo.first);
       if (interruptAddr == '0) begin
	  // do not write to 0 -- it wedges the host
	  interruptRequested = False;
       end
       else if (interruptAddr[63:32] == '0) begin
          TLPMemoryIO3DWHeader hdr_3dw = defaultValue();
          hdr_3dw.format = MEM_WRITE_3DW_DATA;
	  //hdr_3dw.pkttype = MEM_READ_WRITE;
          hdr_3dw.tag = tlpTag;
          hdr_3dw.reqid = my_id;
          hdr_3dw.length = 1;
          hdr_3dw.firstbe = '1;
          hdr_3dw.lastbe = '0;
          hdr_3dw.addr = interruptAddr[31:2];
	  hdr_3dw.data = byteSwap(interruptData);
	  tlp.data = pack(hdr_3dw);
	  tlp.eof = True;
	  sendInterrupt = True;
	  interruptRequested = False;
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

       if (!interruptRequested)
	  interruptRequestFifo.deq();
       if (sendInterrupt)
	  tlpOutFifo.enq(tlp);
    endrule

    rule interruptTlpDataOut if (interruptSecondHalf matches tagged Valid .interruptData);
       TLPData#(16) tlp = defaultValue;
       tlp.sof = False;
       tlp.eof = True;
       tlp.hit = 7'h00;
       tlp.be = 16'hf000;
       tlp.data[7+8*15:8*12] = byteSwap(interruptData);
       tlpOutFifo.enq(tlp);
       interruptSecondHalf <= tagged Invalid;
       interruptRequestFifo.deq();
    endrule

    interface Put inFromTlp;
        method Action put(TLPData#(16) tlp);
	    //$display("AxiMasterEngine.put tlp=%h", tlp);
	    TLPMemoryIO3DWHeader h = unpack(tlp.data);
	    hitReg <= tlp.hit;
	    TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
	    if (hdr_3dw.format == MEM_READ_3DW_NO_DATA) begin
	       if (readHeaderFifo.notFull())
	          readHeaderFifo.enq(hdr_3dw);
	       else begin
		  // FIXME: should generate a response or host will lock up
	       end
	    end
	    else begin
	       if (writeHeaderFifo.notFull())
		  writeHeaderFifo.enq(hdr_3dw);
	    end
            timerReg <= truncate(32'hFFFFFFFF);
	endmethod
    endinterface: inFromTlp
    interface Get outToTlp = toGet(tlpOutFifo);
    interface Axi3Master master;
       interface Get req_aw;
	  method ActionValue#(Axi3WriteRequest#(32,12)) get() if (interruptSecondHalf matches tagged Invalid);
	     let hdr = writeHeaderFifo.first;
	     writeHeaderFifo.deq;
	     writeDataFifo.enq(hdr);
	     let axilen = hdr.length - 1;
	     return Axi3WriteRequest { address: extend(writeHeaderFifo.first.addr) << 2, len: truncate(axilen), id: extend(writeHeaderFifo.first.tag),
				       size: axiBusSize(32), burst: 1, prot: 0, cache: 'b011, lock:0, qos: 0 };
	  endmethod
       endinterface: req_aw
       interface Get resp_write;
	  method ActionValue#(Axi3WriteData#(32,12)) get();
	     writeDataFifo.deq;
	     let data = writeDataFifo.first.data;
	     data = byteSwap(data);
	     return Axi3WriteData { data: data, id: extend(writeDataFifo.first.tag), byteEnable: writeDataFifo.first.firstbe, last: 1 };
	  endmethod
       endinterface: resp_write
       interface Put resp_b;
	  method Action put(Axi3WriteResponse#(12) resp);
             bTagReg <= resp.id;
	  endmethod
       endinterface: resp_b
       interface Get req_ar;
	  method ActionValue#(Axi3ReadRequest#(32,12)) get();
	     let hdr = readHeaderFifo.first;
	     readHeaderFifo.deq;
	     //$display("req_ar hdr.length=%d hdr.addr=%h", hdr.length, hdr.addr);
	     readDataFifo.enq(hdr);
	     let axilen = hdr.length -1;
	     return Axi3ReadRequest { address: extend(readHeaderFifo.first.addr) << 2, len: truncate(axilen), id: extend(readHeaderFifo.first.tag),
				     size: axiBusSize(32), burst: 1, prot: 0, cache: 'b011, lock:0, qos: 0 };
	    endmethod
       endinterface: req_ar
       interface Put resp_read;
	  method Action put(Axi3ReadResponse#(32,12) resp) if (completionMimo.enqReadyN(1));
	     Vector#(1, Bit#(32)) vec = cons(resp.data, nil);
	     completionMimo.enq(1, vec);
	  endmethod
	endinterface: resp_read
    endinterface: master
    interface Put interruptRequest;
       method Action put(Tuple2#(Bit#(64),Bit#(32)) intr);
          interruptRequestFifo.enq(intr);
       endmethod
    endinterface
    interface Reg bTag = bTagReg;
endmodule: mkAxiMasterEngine
