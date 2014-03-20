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
import PCIE         :: *;
import DefaultValue :: *;

import AxiMasterSlave :: *;

//
// Top interface: PCIe transaction level packets (TLPs)
// Bottom interface: AXI3 Master that sends read/write requests to an Axi3Slave
// Also sources interrupt MSIX requests
interface AxiMasterEngine;
    interface Put#(TLPData#(16))   tlp_in;
    interface Get#(TLPData#(16))   tlp_out;
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
    FIFOF#(TLPMemoryIO3DWHeader) readHeaderFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) readDataFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) writeHeaderFifo <- mkFIFOF;
    FIFOF#(TLPMemoryIO3DWHeader) writeDataFifo <- mkFIFOF;
    FIFOF#(TLPData#(16)) tlpOutFifo <- mkFIFOF;
    Reg#(TLPTag) tlpTag <- mkReg(0);
    Reg#(Bit#(12)) bTagReg <- mkReg(0);

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

    interface Put tlp_in;
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
    endinterface: tlp_in
    interface Get tlp_out = toGet(tlpOutFifo);
    interface Axi3Master master;
       interface Get req_aw;
	  method ActionValue#(Axi3WriteRequest#(32,12)) get() if (interruptSecondHalf matches tagged Invalid);
	     let hdr = writeHeaderFifo.first;
	     writeHeaderFifo.deq;
	     writeDataFifo.enq(hdr);
	     return Axi3WriteRequest { address: extend(writeHeaderFifo.first.addr) << 2, len: 0, id: extend(writeHeaderFifo.first.tag),
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
	     readDataFifo.enq(hdr);
	     return Axi3ReadRequest { address: extend(readHeaderFifo.first.addr) << 2, len: 0, id: extend(readHeaderFifo.first.tag),
				     size: axiBusSize(32), burst: 1, prot: 0, cache: 'b011, lock:0, qos: 0 };
	    endmethod
       endinterface: req_ar
       interface Put resp_read;
	  method Action put(Axi3ReadResponse#(32,12) resp) if (interruptSecondHalf matches tagged Invalid);
	        let hdr = readDataFifo.first;
		//FIXME: assumes only 1 word read per request
		readDataFifo.deq;

	        TLPCompletionHeader completion = defaultValue;
		completion.format = MEM_WRITE_3DW_DATA;
		completion.pkttype = COMPLETION;
		completion.relaxed = hdr.relaxed;
		completion.nosnoop = hdr.nosnoop;
		completion.length = 1;
		completion.tclass = hdr.tclass;
		completion.cmplid = my_id;
		completion.tag = truncate(resp.id);
		completion.bytecount = 4;
		completion.reqid = hdr.reqid;
		completion.loweraddr = getLowerAddr(hdr.addr, hdr.firstbe);
		completion.data = byteSwap(resp.data);
	        TLPData#(16) tlp = defaultValue;
		tlp.data = pack(completion);
		tlp.sof = True;
		tlp.eof = True;
		tlp.be = 16'hFFFF;
		tlp.hit = hitReg;
		tlpOutFifo.enq(tlp);
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
