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

`include "ConnectalProjectConfig.bsv"
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import ClientServer::*;
import GetPut::*;
import ConnectalConfig::*;
import ConnectalMemTypes::*;
import MemWriteEngine::*;
import Pipe::*;
import AddressGenerator::*;

typedef TDiv#(DataBusWidth,32) WordsPerBeat;

interface MemwriteRequest;
   method Action startWrite(Bit#(32) pointer, Bit#(32) numWords, Bit#(32) numReqs, Bit#(32) burstLen, Bit#(8) byteEnable);
endinterface

interface MemwriteIndication;
   method Action writeDone(Bit#(32) v);
   method Action writeProgress(Bit#(32) v);
endinterface

interface Memwrite;
   interface MemwriteRequest request;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) dmaClients;
endinterface

module  mkMemwrite#(MemwriteIndication indication) (Memwrite);
   Reg#(SGLId)   pointer <- mkReg(0);
   Reg#(Bit#(32))        numReqs <- mkReg(0);
   Reg#(Bit#(32))        numDone <- mkReg(0);
   Reg#(Bit#(MemOffsetSize)) reqOffset <- mkReg(0);
   Reg#(Bit#(3))                   tag <- mkReg(0);
   Reg#(Bit#(32))             numWords <- mkReg(0);
   Reg#(Bit#(BurstLenSize)) burstLenBytes <- mkReg(0);
   Reg#(Bit#(32))              srcGens <- mkReg(3);
   Reg#(Bit#(8))            byteEnable <- mkReg('hff);

   AddressGenerator#(32, DataBusWidth) addrGenerator <- mkAddressGenerator();
   FIFO#(MemRequest) reqFifo <- mkSizedFIFO(4);
   FIFO#(PhysMemRequest#(32,DataBusWidth)) preqFifo <- mkSizedFIFO(4);
   FIFO#(MemData#(DataBusWidth))   dataFifo <- mkSizedBRAMFIFO(1024);
   FIFO#(Bit#(MemTagSize)) doneFifo <- mkSizedFIFO(4);

   let verboseProgress = False;

`ifdef BYTE_ENABLES
   Bit#(TDiv#(DataBusWidth,8)) firstbe = maxBound;
   Bit#(TDiv#(DataBusWidth,8)) lastbe = maxBound;
   // just apply the byteEnable to the first and last 32-bit word of a burst
   firstbe[3:0] = byteEnable[3:0];
   lastbe[valueOf(ByteEnableSize)-1:valueOf(ByteEnableSize)-4] = byteEnable[7:4];
`endif

   rule start if (numReqs != 0);
`ifdef BYTE_ENABLES
      $display("Memwrite.start firstbe=%h lastbe=%h", firstbe, lastbe);
`endif
      reqFifo.enq(MemRequest { sglId: pointer, offset: reqOffset, burstLen: burstLenBytes, tag: extend(tag)
`ifdef BYTE_ENABLES
			      , firstbe: firstbe, lastbe: lastbe
`endif
			      });
      preqFifo.enq(PhysMemRequest { addr: 0, burstLen: burstLenBytes, tag: extend(tag)
`ifdef BYTE_ENABLES
				       , firstbe: firstbe, lastbe: lastbe
`endif
				   });
      numReqs <= numReqs - 1;
      reqOffset <= reqOffset + extend(burstLenBytes);
      tag <= tag + 1;
      //$display("start numReqs", numReqs);
   endrule

   rule preq;
      let preq <- toGet(preqFifo).get();
      addrGenerator.request.put(preq);
   endrule

   rule finish;
      let donetag <- toGet(doneFifo).get();
      //$display("finished num todo=%d", numDone);
      if (numDone == 1) begin
         indication.writeDone(0);
      end
      numDone <= numDone - 1;
      if (verboseProgress)
	 indication.writeProgress(extend(donetag));
   endrule

   rule src if (numWords != 0);
      let b <- addrGenerator.addrBeat.get();

      function Bit#(32) plusi(Integer i); return srcGens + fromInteger(i); endfunction
      Vector#(WordsPerBeat, Bit#(32)) v = genWith(plusi);
      dataFifo.enq(MemData { data: pack(v), tag: b.tag, last: b.last});
      srcGens <= srcGens+fromInteger(valueOf(WordsPerBeat));
      numWords <= numWords - fromInteger(valueOf(WordsPerBeat));
   endrule

   MemWriteClient#(DataBusWidth) dmaClient = (interface MemWriteClient;
      interface Get writeReq = toGet(reqFifo);
      interface Get writeData = toGet(dataFifo);
      interface Put writeDone = toPut(doneFifo);
   endinterface );

   interface MemwriteRequest request;
       method Action startWrite(Bit#(32) wp, Bit#(32) nw, Bit#(32) nreq, Bit#(32) bl, Bit#(8) be);
	  //$dumpvars();
          $display("startWrite pointer=%d numWords=%d (%d) numReqs=%d burstLen=%d", pointer, nw, nreq*bl, nreq, bl);
          pointer <= wp;
          numWords  <= nw;
          burstLenBytes <= truncate(bl);
	  numReqs <= nreq;
	  numDone <= nreq;

	  reqOffset <= 0;
	  srcGens <= 3;
	  byteEnable <= be;
       endmethod
   endinterface
   interface dmaClients = vec(dmaClient);

endmodule

