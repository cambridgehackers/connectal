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

import FIFO         :: *;
import FIFOF        :: *;
import GetPut       :: *;
import Connectable  :: *;
import PCIE         :: *;
import DefaultValue :: *;
import MIMO         :: *;
import MIFO         :: *;
import Vector       :: *;
import ClientServer :: *;
import MemTypes     :: *;
import Probe        :: *;
import ConfigCounter ::*;

typedef struct {
   TLPData#(16) tlp;
   TLPLength    dwCount;
   Bool         is3dw;
   Bool         isHeaderOnly;
   } TlpWriteHeaderInfo deriving (Bits);

interface MemSlaveEngine#(numeric type buswidth);
    interface Client#(TLPData#(16), TLPData#(16)) tlp;
    interface PhysMemSlave#(40,buswidth) slave;
    method Bool tlpOutFifoNotEmpty();
    interface Reg#(Bool) use4dw;
endinterface: MemSlaveEngine

`ifdef XILINX
   `define AXI
`elsif BSIM
   `define AXI
`elsif ALTERA
   `define AVALON
`endif

typedef 64 WriteDataMimoSize;
typedef TAdd#(1,TLog#(WriteDataMimoSize)) WriteDataBurstLenSize;
module mkMemSlaveEngine#(PciId my_id)(MemSlaveEngine#(buswidth))
   provisos (Div#(buswidth, 8, busWidthBytes),
	     Div#(buswidth, 32, busWidthWords),
	     Bits#(Vector#(busWidthWords, Bit#(32)), buswidth),
            Log#(busWidthBytes,beatShift),
	     Add#(aaa, 32, buswidth),
	     Add#(bbb, buswidth, 256),
	     Add#(ccc, TMul#(8, busWidthWords), 64),
	     Add#(ddd, TMul#(32, busWidthWords), 256),
	     Add#(eee, busWidthWords, 8),
	     Add#(1, a__, busWidthWords),
	     Add#(busWidthWords, b__, 4),
	     Add#(c__, busWidthWords, WriteDataMimoSize)
      );

    let beat_shift = fromInteger(valueOf(beatShift));

    FIFOF#(TLPData#(16)) tlpOutFifo <- mkFIFOF;
    FIFOF#(TLPData#(16)) tlpInFifo <- mkFIFOF;
    FIFOF#(TlpWriteHeaderInfo) tlpWriteHeaderFifo <- mkFIFOF;

    Reg#(Bit#(7)) hitReg <- mkReg(0);
    Reg#(Bool) use4dwReg <- mkReg(True);

    // default configuration for MIMO is for guarded enq() and deq().
    // However, the implicit guard only checks for space for 1 element for enq(), and availability of 1 element for deq().
    MIMOConfiguration mimoCfg = defaultValue;
   MIFO#(4,busWidthWords,16,Bit#(32)) completionMimo <- mkMIFO();
   MIFO#(4,busWidthWords,16,TLPTag) completionTagMimo <- mkMIFO();

   mimoCfg.bram_based = True;
   mimoCfg.unguarded = True;
    MIMO#(busWidthWords,4,WriteDataMimoSize,Bit#(32)) writeDataMimo <- mkMIMO(mimoCfg);
    ConfigCounter#(8) writeDataCnt <- mkConfigCounter(0);
    Reg#(Bit#(WriteDataBurstLenSize)) writeBurstCount <- mkReg(0);
    FIFO#(Bit#(WriteDataBurstLenSize)) writeBurstCountFifo <- mkFIFO();
    Reg#(TLPLength)  writeDwCount <- mkReg(0); // how many 4 byte (double) words to send
    Reg#(LUInt#(4))    tlpDwCount <- mkReg(0); // how many to send in the next tlp (at most 4)
    Reg#(Bool)            lastTlp <- mkReg(False); // if the next tlp sent is the last one
    Reg#(Bool)    writeInProgress <- mkReg(False);
    FIFOF#(TLPTag) writeTag <- mkSizedFIFOF(16);
    FIFOF#(TLPTag) doneTag <- mkSizedFIFOF(16);

    Reg#(Bool) quadAlignedTlpHandled <- mkReg(True);

   Wire#(Bool) writeHeaderTlpWire <- mkDWire(False);
   Probe#(Bool) writeHeaderAvailableProbe <- mkProbe;
   Wire#(Bool) writeDataMimoEnqWire <- mkDWire(False);
   Probe#(Bool) writeDataMimoEnqProbe <- mkProbe;
   let    writeDataMimoCountProbe <- mkProbe;
   let writeDataMimoEnqReadyProbe <- mkProbe;
   Probe#(Bool) writeInProgressProbe <- mkProbe;
   Probe#(Bit#(10)) writeBurstCountProbe <- mkProbe;
   rule updateProbe0;
      writeDataMimoCountProbe    <= writeDataMimo.count();
      writeDataMimoEnqReadyProbe <= writeDataMimo.enqReadyN(fromInteger(valueOf(busWidthWords)));
   endrule
   rule updateProbe2;
      writeHeaderAvailableProbe <= writeHeaderTlpWire;
      writeDataMimoEnqProbe <= writeDataMimoEnqWire;
   endrule

   Reg#(Bool) writeDataCntAboveThreshold <- mkReg(False);
   Reg#(Bool) writeDataMimoHasRoom <- mkReg(False);
   rule updateWriteDataMimoHasRoom;
      writeDataMimoHasRoom <= (writeDataCnt.read <= fromInteger(valueOf(WriteDataMimoSize) - valueOf(busWidthWords)));
   endrule
   rule noheader if (!tlpWriteHeaderFifo.notEmpty());
      writeDataCntAboveThreshold <= False;
   endrule
   rule updateWriteDataCntAboveThreshold if (writeInProgress || !writeDataCntAboveThreshold);
      writeDataCntAboveThreshold <= (writeDataCnt.read >= truncate(unpack(tlpWriteHeaderFifo.first.dwCount)));
   endrule
   (* descending_urgency = "writeHeaderTlp,updateWriteDataCntAboveThreshold" *)
   rule writeHeaderTlp if (!writeInProgress && writeDataCntAboveThreshold);
      // update for next cycle
      writeDataCntAboveThreshold <= (writeDataCnt.read >= truncate(unpack(tlpWriteHeaderFifo.first.dwCount)));

      writeHeaderTlpWire <= True;
      let info <- toGet(tlpWriteHeaderFifo).get();
      let tlp     = info.tlp;
      let dwCount = info.dwCount;
      let is3dw   = info.is3dw;
      let isHeaderOnly = info.isHeaderOnly;

      TLPMemory4DWHeader hdr_4dw = unpack(tlp.data);

      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      if (is3dw) begin
	 if (hdr_3dw.format != MEM_WRITE_3DW_DATA)
	    $display("MemSlaveEngine: expecting MEM_WRITE_3DW_DATA, got %d", hdr_3dw.format);
	 Vector#(4, Bit#(32)) v = unpack(0);
         tlp.sof = True;
`ifdef AXI
         v = writeDataMimo.first();
	 writeDataMimo.deq(1);
	 hdr_3dw.data = byteSwap(v[0]);
         tlp.eof = (dwCount == 1) ? True : False;
         dwCount = dwCount - 1;
         writeDataCnt.decrement(1);
`elsif AVALON
         let quadWordAligned = isQuadWordAligned(getLowerAddr(hdr_3dw.addr, hdr_3dw.firstbe));
         // if quad-word aligned, insert bubble.
         if (!quadWordAligned) begin
            v = writeDataMimo.first();
            writeDataMimo.deq(1);
            hdr_3dw.data = v[0];
         end
         else begin
            hdr_3dw.data = unpack(0);
         end
         tlp.eof = (dwCount == 1 && !quadWordAligned) ? True : False;
         if (!quadWordAligned) begin
            dwCount = dwCount - 1;
            writeDataCnt.decrement(1);
         end
`endif
	 tlp.be = 16'hffff;
	 tlp.data = pack(hdr_3dw);
      end
      else begin
         quadAlignedTlpHandled <= isQuadWordAligned(getLowerAddr(truncate(unpack(hdr_4dw.addr)), hdr_4dw.firstbe));
	 tlp.be = 16'hffff;
      end

      tlpOutFifo.enq(tlp);
      $display("writeHeaderTlp dwCount=%d", dwCount);
      writeDwCount <= dwCount;
      tlpDwCount <= truncate(min(4,unpack(dwCount)));
      lastTlp <= (dwCount <= 4);
      writeInProgress <= (dwCount != 0);
      writeInProgressProbe <= (dwCount != 0);
      if (isHeaderOnly) begin
	 doneTag.enq(writeTag.first());
	 writeTag.deq();
      end

   endrule

   rule writeTlps if (writeInProgress); // already verified  writeDataMimo.deqReadyN(tlpDwCount)) for this transaction
      TLPData#(16) tlp = defaultValue;
      tlp.sof = False;
      Vector#(4, Bit#(32)) v = unpack(0);
      Integer currDwCount = 4;

`ifdef AVALON
      if (!quadAlignedTlpHandled) begin
         currDwCount = 3; // 3 Data Dwords in this cycle.
         quadAlignedTlpHandled <= True;
      end
`endif

      // The MIMO implicit guard only checks for availability of 1 element
      // so we explicitly check for the number of elements required
      writeDataMimo.deq(tlpDwCount);
      v = writeDataMimo.first();
      let dwCount = writeDwCount - extend(pack(tlpDwCount));
      writeDwCount <= dwCount;
      tlpDwCount <= truncate(min(fromInteger(currDwCount),unpack(dwCount)));
      writeDataCnt.decrement(unpack(extend(pack(tlpDwCount))));
      lastTlp <= (dwCount <= 4);
      if (tlpDwCount == 4)
	 tlp.be = 16'hffff;
      else if (tlpDwCount == 3)
	 tlp.be = 16'hfff0;
      else if (tlpDwCount == 2)
	 tlp.be = 16'hff00;
      else if (tlpDwCount == 1)
	 tlp.be = 16'hf000;
      tlp.eof = lastTlp;
      if (lastTlp) begin
	 writeInProgress <= False;
	 writeInProgressProbe <= False;
	 doneTag.enq(writeTag.first());
	 writeTag.deq();
	 $display("writeDwCount=%d will be zero", writeDwCount);
      end

      for (Integer i = 0; i < currDwCount; i = i + 1) begin
`ifdef AXI
	 tlp.data[(i+1)*32-1:i*32] = byteSwap(v[(currDwCount-1)-i]);
`elsif AVALON
	 tlp.data[(i+1)*32-1:i*32] = v[(currDwCount-1)-i];
`endif
      end

      tlpOutFifo.enq(tlp);
   endrule

   Reg#(TLPTag) lastTag <- mkReg(0);
   FIFOF#(TLPData#(16)) tlpDecodeFifo <- mkFIFOF();
   Reg#(TLPLength) wordCountReg <- mkReg(0);
   rule tlpInRule;
      let tlp <- toGet(tlpInFifo).get();
      tlpDecodeFifo.enq(tlp);
   endrule

   rule handleTlpRule;
      let tlp = tlpDecodeFifo.first;
      Bool handled = False;
      TLPMemoryIO3DWHeader h = unpack(tlp.data);
      hitReg <= tlp.hit;
      TLPMemoryIO3DWHeader hdr_3dw = unpack(tlp.data);
      TLPCompletionHeader hdr_completion = unpack(tlp.data);
      Vector#(4, Bit#(32)) vec = unpack(0);
      Vector#(4, Bit#(32)) tlpvec = unpack(tlp.data);
      let wordCount = wordCountReg;
`ifdef AXI
      let dataInSecondTlp = False;
`elsif AVALON
      let quadWordAligned = isQuadWordAligned(getLowerAddr(hdr_3dw.addr, hdr_3dw.firstbe));
      let dataInSecondTlp = quadWordAligned;
`endif
      if (!tlp.sof) begin
	 vec = reverse(tlpvec);
	 // The MIMO implicit guard only checks for space to enqueue 1 element
	 // so we explicitly check for the number of elements required
	 // otherwise elements in the queue will be overwritten.
	 if (completionMimo.enqReady()
	    && completionTagMimo.enqReady())
	    begin
	       UInt#(3) count = 4;
	       if (tlp.eof) begin
		  count = truncate(unpack(wordCountReg));
	       end
	       wordCount = wordCountReg - extend(pack(count));
	       completionMimo.enq(count, vec);
	       Vector#(4, TLPTag) tagvec = replicate(lastTag);
	       completionTagMimo.enq(count, tagvec);
	       handled = True;
	    end
      end
      else if (hdr_3dw.format == MEM_WRITE_3DW_DATA
	       && hdr_3dw.pkttype == COMPLETION
	       && completionMimo.enqReady()
	       && completionTagMimo.enqReady()) begin
            TLPTag tag = hdr_completion.tag;
            lastTag <= tag;
            if (!dataInSecondTlp) begin
               vec[0] = hdr_3dw.data;
               wordCount = hdr_3dw.length - 1;
               completionMimo.enq(1, vec);
               completionTagMimo.enq(1, replicate(tag));
            end
	    handled = True;
      end
      wordCountReg <= wordCount;
      $display("tlpIn handled=%d tlp=%h\n", handled, tlp);
      if (handled) begin
	 tlpDecodeFifo.deq();
      end
   endrule

   FIFO#(PhysMemRequest#(40)) readReqFifo <- mkFIFO();
   rule readReqRule if (!writeInProgress && !writeDataMimo.deqReady());
      let req <- toGet(readReqFifo).get();
      let burstLen = req.burstLen >> beat_shift;
      let addr = req.addr;
      let arid = req.tag;

      TLPData#(16) tlp = defaultValue;
      tlp.sof = True;
      tlp.eof = True;
      tlp.hit = 7'h00;
      TLPLength tlplen = fromInteger(valueOf(busWidthWords))*extend(burstLen);
      if (addr[39:32] != 0) begin
	 TLPMemory4DWHeader hdr_4dw = defaultValue;
	 hdr_4dw.format = MEM_READ_4DW_NO_DATA;
	 hdr_4dw.tag = extend(arid);
	 hdr_4dw.reqid = my_id;
	 hdr_4dw.nosnoop = SNOOPING_REQD;
	 hdr_4dw.addr = addr[40-1:2];
	 hdr_4dw.length = tlplen;
	 hdr_4dw.firstbe = 4'hf;
	 hdr_4dw.lastbe = (tlplen > 1) ? 4'hf : 0;
	 tlp.data = pack(hdr_4dw);
	 tlp.be = 16'hffff;
      end
      else begin
	 TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
	 hdr_3dw.format = MEM_READ_3DW_NO_DATA;
	 hdr_3dw.tag = extend(arid);
	 hdr_3dw.reqid = my_id;
	 hdr_3dw.nosnoop = SNOOPING_REQD;
	 hdr_3dw.addr = addr[32-1:2];
	 hdr_3dw.length = tlplen;
	 hdr_3dw.firstbe = 4'hf;
	 hdr_3dw.lastbe = (tlplen > 1) ? 4'hf : 0;
	 tlp.data = pack(hdr_3dw);
	 tlp.be = 16'hfff0;
      end
      tlpOutFifo.enq(tlp);
   endrule

    interface Client        tlp;
        interface request = toGet(tlpOutFifo);
        interface response = toPut(tlpInFifo);
    endinterface
    interface PhysMemSlave slave;
   interface PhysMemWriteServer write_server; 
      interface Put writeReq;
         method Action put(PhysMemRequest#(40) req); // if (writeBurstCount == 0);
	    Bit#(WriteDataBurstLenSize) burstLen = truncate(req.burstLen >> beat_shift);
	    let addr = req.addr;
	    let awid = req.tag;
	    let writeIs3dw = False;

	    TLPLength tlplen = fromInteger(valueOf(busWidthWords))*extend(burstLen);
	    TLPData#(16) tlp = defaultValue;
	    tlp.sof = True;
	    tlp.eof = False;
	    tlp.hit = 7'h00;
	    tlp.be = 16'hffff;

	    $display("slave.writeAddr tlplen=%d burstLen=%d", tlplen, burstLen);
	    if ((addr >> 32) != 0) begin
	       TLPMemory4DWHeader hdr_4dw = defaultValue;
	       hdr_4dw.format = MEM_WRITE_4DW_DATA;
	       hdr_4dw.tag = extend(awid);
	       hdr_4dw.reqid = my_id;
	       hdr_4dw.nosnoop = SNOOPING_REQD;
	       hdr_4dw.addr = addr[40-1:2];
	       hdr_4dw.length = tlplen;
	       hdr_4dw.firstbe = 4'hf;
	       hdr_4dw.lastbe = (tlplen > 1) ? 4'hf : 0;
	       tlp.data = pack(hdr_4dw);
	    end
	    else begin
	       writeIs3dw = True;
	       TLPMemoryIO3DWHeader hdr_3dw = defaultValue;
	       hdr_3dw.format = MEM_WRITE_3DW_DATA;
	       hdr_3dw.tag = extend(awid);
	       hdr_3dw.reqid = my_id;
	       hdr_3dw.nosnoop = SNOOPING_REQD;
	       hdr_3dw.addr = addr[32-1:2];
	       hdr_3dw.length = tlplen;
	       hdr_3dw.firstbe = 4'hf;
	       hdr_3dw.lastbe = (tlplen > 1) ? 4'hf : 0;

	       tlp.be = 16'hfff0; // no data word in this TLP

	       tlp.data = pack(hdr_3dw);
	    end
	    tlpWriteHeaderFifo.enq(TlpWriteHeaderInfo {tlp: tlp, dwCount: tlplen, is3dw: writeIs3dw, isHeaderOnly: (writeIs3dw && tlplen == 1) });
	    writeBurstCountFifo.enq(burstLen);
	    writeTag.enq(extend(awid));
         endmethod
	endinterface
      interface Put writeData;
         method Action put(MemData#(buswidth) wdata)
	    provisos (Bits#(Vector#(busWidthWords, Bit#(32)), busWidth)) if (writeDataMimoHasRoom); //.enqReadyN(fromInteger(valueOf(busWidthWords))));

	    let burstLen = writeBurstCount;
	    if (burstLen == 0) begin
	       burstLen <- toGet(writeBurstCountFifo).get();
	    end
	    writeBurstCount <= extend(burstLen-1);
	    writeBurstCountProbe <= extend(burstLen-1);

	    Vector#(busWidthWords, Bit#(32)) v = unpack(wdata.data);
	    writeDataMimo.enq(fromInteger(valueOf(busWidthWords)), v);
            writeDataCnt.increment(fromInteger(valueOf(busWidthWords)));
	    writeDataMimoEnqWire <= True;
         endmethod
       endinterface
      interface Get writeDone;
         method ActionValue#(Bit#(MemTagSize)) get();
	      let tag = doneTag.first();
	      doneTag.deq();
	      return truncate(tag);
           endmethod
	endinterface
   endinterface
   interface PhysMemReadServer read_server;
      interface Put readReq;
         method Action put(PhysMemRequest#(40) req);
	    readReqFifo.enq(req);
         endmethod
       endinterface
      interface Get     readData;
         method ActionValue#(MemData#(buswidth)) get() if (completionMimo.deqReady()
							   && completionTagMimo.deqReady());
	      let data_v = completionMimo.first;
	      let tag_v = completionTagMimo.first;
	      completionMimo.deq();
	      completionTagMimo.deq();
              Bit#(buswidth) v = 0;
              for (Integer i = 0; i < valueOf(busWidthWords); i = i+1) begin
`ifdef AXI
		 v[(i+1)*32-1:i*32] = byteSwap(data_v[i]);
`elsif AVALON
		 v[(i+1)*32-1:i*32] = data_v[i];
`endif
              end
	      return MemData { data: v, tag: truncate(tag_v[0]), last: True};
           endmethod
	endinterface
   endinterface
    endinterface: slave
   method Bool tlpOutFifoNotEmpty() = tlpOutFifo.notEmpty;
   interface Reg use4dw = use4dwReg;
endmodule: mkMemSlaveEngine

