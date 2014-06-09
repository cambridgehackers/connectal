// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

import FIFOF::*;
import GetPut::*;
import Vector::*;
import BRAM::*;

import MemTypes::*;
import Dma2BRAM::*;

interface NandSimRequest;
   method Action startRead(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) drampointer, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
endinterface

interface NandSimIndication;
   method Action readDone(Bit#(32) tag);
   method Action writeDone(Bit#(32) tag);
   method Action eraseDone(Bit#(32) tag);
endinterface

interface NandSim;
   interface NandSimRequest request;
   interface ObjectReadClient#(64) readClient;
   interface ObjectWriteClient#(64) writeClient;
endinterface

// Asz useded to be a type parameter to mkNandSim, but bsc couldn't handle that much polymorphism (mdk)
typedef 14 Asz;

module mkNandSim#(NandSimIndication indication, BRAMServer#(Bit#(Asz), Bit#(64)) br) (NandSim);


   BRAMReadClient#(Asz, 64) rc <- mkBRAMReadClient(br);
   BRAMWriteClient#(Asz, 64) wc <- mkBRAMWriteClient(br);
   
   Reg#(Bit#(Asz)) nandEraseAddr <- mkReg(0);
   Reg#(Bit#(Asz)) nandEraseLimit <- mkReg(0);
   Reg#(Bit#(Asz)) nandEraseCnt <- mkReg(0);

   rule eraseBram if (nandEraseAddr < nandEraseLimit);
      Bit#(64) v = fromInteger(-1);
      //$display("eraseBram: addr=%h limit=%h count=%h v=%h", nandEraseAddr, nandEraseLimit, nandEraseCnt, v);
      br.request.put(BRAMRequest{write:True,responseOnWrite:?,address:nandEraseAddr,datain:v});
      nandEraseAddr <= nandEraseAddr + 1;
      nandEraseCnt <= nandEraseCnt - 1;
      if (nandEraseCnt == 1)
	 indication.eraseDone(0);
   endrule
   
   rule writeDone;
      let rv <- rc.finish;
      indication.writeDone(0);
   endrule

   rule readDone;
      let rv <- wc.finish;
      indication.readDone(0);
   endrule
   
   // TODO: if this is ever a performance bottlenec, the mkBRAM[Read|Write]Client interafces should take
   //       the burstlen parameter for better memory throughput.  currently they use burst=1 (mdk)
   interface NandSimRequest request;
      /*!
      * Reads from NAND and writes to DRAM
      */
      method Action startRead(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) __bl);
	 let bram_start_idx = truncate(nandAddr>>3);
	 let bram_finish_idx = bram_start_idx+truncate((numBytes>>3)-1);
	 wc.start(pointer, extend(dramOffset), bram_start_idx, bram_finish_idx);
      endmethod

      /*!
      * Reads from DRAM and writes to NAND
      */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,Bit#(32) numBytes, Bit#(32) __bl);
	 let bram_start_idx = truncate(nandAddr>>3);
	 let bram_finish_idx = bram_start_idx+truncate((numBytes>>3)-1);
	 rc.start(pointer, extend(dramOffset), bram_start_idx, bram_finish_idx); 
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 nandEraseAddr <= truncate(nandAddr >> 3);
	 nandEraseLimit <= truncate((nandAddr + numBytes) >> 3);
	 nandEraseCnt <= truncate(numBytes >> 3);
      endmethod

   endinterface

   interface ObjectReadClient readClient = rc.dmaClient;
   interface ObjectWriteClient writeClient = wc.dmaClient;

endmodule
