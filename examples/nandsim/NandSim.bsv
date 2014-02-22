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
import GetPutF::*;
import Vector::*;
import BRAM::*;

import Dma::*;

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
   interface DmaReadClient#(64) readClient;
   interface DmaWriteClient#(64) writeClient;
endinterface

module mkNandSim#(NandSimIndication indication, BRAMServer#(Bit#(asz), Bit#(64)) br) (NandSim)
   provisos (Add#(a__, asz, 32));

   Reg#(DmaPointer) dramRdPointer <- mkReg(0);
   Reg#(Bit#(32)) dramRdCnt <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))      dramRdOffset <- mkReg(0);
   Reg#(Bit#(6)) dramRdTag <- mkReg(0);
   Reg#(Bit#(asz)) nandRdAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandRdLimit <- mkReg(0);

   Reg#(DmaPointer) dramWrPointer <- mkReg(0);
   Reg#(Bit#(32)) dramWrCnt <- mkReg(0);
   Reg#(Bit#(32)) dramWrDone <- mkReg(0);
   Reg#(Bit#(DmaOffsetSize))      dramWrOffset <- mkReg(0);
   Reg#(Bit#(6)) dramWrTag <- mkReg(0);
   Reg#(Bit#(asz)) nandWrAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandWrLimit <- mkReg(0);

   Reg#(Bit#(asz)) nandEraseAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandEraseLimit <- mkReg(0);
   Reg#(Bit#(asz)) nandEraseCnt <- mkReg(0);

   Reg#(Bit#(8)) burstLen <- mkReg(8);
   Reg#(Bit#(8)) dramWrBurstLen <- mkReg(8);
   Reg#(Bit#(DmaOffsetSize)) deltaOffset <- mkReg(8*8);

   rule readBram if (nandRdAddr < nandRdLimit);
      br.request.put(BRAMRequest{write:False,responseOnWrite:?,address:nandRdAddr,datain:?});
      nandRdAddr <= nandRdAddr + 1;
   endrule

   rule eraseBram if (nandEraseAddr < nandEraseLimit);
      Bit#(64) v = fromInteger(-1);
      $display("eraseBram: addr=%h limit=%h count=%h v=%h", nandEraseAddr, nandEraseLimit, nandEraseCnt, v);
      br.request.put(BRAMRequest{write:True,responseOnWrite:?,address:nandEraseAddr,datain:v});
      nandEraseAddr <= nandEraseAddr + 1;
      nandEraseCnt <= nandEraseCnt - 1;
      if (nandEraseCnt == 1)
	 indication.eraseDone(0);
   endrule

   interface NandSimRequest request;
   /*!
   * Reads from NAND and writes to DRAM
   */
      method Action startRead(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,
			      Bit#(32) numBytes, Bit#(32) bl);
         dramWrPointer <= pointer;
	 dramWrOffset <= extend(dramOffset);
         dramWrCnt <= numBytes>>3;
         dramWrDone <= numBytes>>3;
	 nandRdAddr <= truncate(nandAddr >> 3);
	 nandRdLimit <= truncate((nandAddr + numBytes) >> 3);
         burstLen <= truncate(bl);
         deltaOffset <= 8*extend(bl);
      endmethod
   /*!
   * Reads from DRAM and writes to NAND
   */
      method Action startWrite(Bit#(32) pointer, Bit#(32) dramOffset, Bit#(32) nandAddr,
			       Bit#(32) numBytes, Bit#(32) bl);
         dramRdPointer <= pointer;
         dramRdOffset <= extend(dramOffset);
         dramRdCnt <= numBytes>>3;
	 nandWrAddr <= truncate(nandAddr >> 3);
	 nandWrLimit <= truncate((nandAddr + numBytes) >> 3);
         dramWrBurstLen <= truncate(bl);
         deltaOffset <= 8*extend(bl);
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 nandEraseAddr <= truncate(nandAddr >> 3);
	 nandEraseLimit <= truncate((nandAddr + numBytes) >> 3);
	 nandEraseCnt <= truncate(numBytes >> 3);
      endmethod

   endinterface

   interface DmaReadClient readClient;
      interface GetF readReq;
         method ActionValue#(DmaRequest) get() if (dramRdCnt > 0);
            dramRdCnt <= dramRdCnt-extend(burstLen);
            dramRdOffset <= dramRdOffset + deltaOffset;
            if (dramRdCnt <= extend(burstLen))
               indication.writeDone(0); // read from DRAM is write to NAND
            //else if (dramRdCnt[5:0] == 6'b0)
            //   indication.readReq(dramRdCnt);
            return DmaRequest { pointer: dramRdPointer, offset: dramRdOffset, burstLen: burstLen, tag: truncate(dramRdOffset) };
         endmethod
         method Bool notEmpty();
            return dramRdCnt > 0;
         endmethod
      endinterface : readReq
      interface PutF readData;
         method Action put(DmaData#(64) d);
	    $display("readData/nandWrite nandWrAddr=%h d=%h tag=%h", nandWrAddr, d.data, d.tag);
	    br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:nandWrAddr, datain:d.data});
	    nandWrAddr <= nandWrAddr+1;
         endmethod
         method Bool notFull();
            return True;
         endmethod
      endinterface : readData
   endinterface
   interface DmaWriteClient writeClient;
      interface GetF writeReq;
	 method ActionValue#(DmaRequest) get() if (dramWrCnt > 0);
	    dramWrCnt <= dramWrCnt - extend(dramWrBurstLen);
	    dramWrOffset <= dramWrOffset + deltaOffset;
	    let tag = truncate(dramWrOffset>>3);
	    dramWrTag <= tag;
	    return DmaRequest { pointer: dramWrPointer, offset: dramWrOffset, burstLen: dramWrBurstLen, tag: tag };
	 endmethod
	 method Bool notEmpty();
	    return dramWrCnt > 0;
	 endmethod
      endinterface: writeReq
      interface GetF writeData;
	 method ActionValue#(DmaData#(64)) get();
	    let v <- br.response.get();
	    $display("writeReq v=%h", v);
	    return DmaData { data: v, tag: dramWrTag };
	 endmethod
	 method Bool notEmpty();
	    return nandRdAddr < nandRdLimit;
	 endmethod
      endinterface: writeData
      interface PutF writeDone;
	 method Action put(Bit#(6) tag);
	    let dwd = dramWrDone - extend(dramWrBurstLen);
	    dramWrDone <= dwd;
	    $display("dramWrDone=%h", dramWrDone);
            if (dwd <= extend(dramWrBurstLen))
	       indication.readDone(0);
	 endmethod
	 method Bool notFull();
	    return True;
	 endmethod
      endinterface: writeDone
   endinterface
endmodule
