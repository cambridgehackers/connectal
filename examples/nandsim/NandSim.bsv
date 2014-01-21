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

import PortalMemory::*;
import PortalRMemory::*;

interface NandSimRequest;
   method Action startRead(Bit#(32) dramhandle, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) dramhandle, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numBytes, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
endinterface

interface NandSimIndication;
   method Action readDone(Bit#(32) tag);
   method Action writeDone(Bit#(32) tag);
   method Action eraseDone(Bit#(32) tag);
endinterface

interface NandSim;
   interface NandSimRequest request;
   interface DMAReadClient#(64) readClient;
   interface DMAWriteClient#(64) writeClient;
endinterface

module mkNandSim#(NandSimIndication indication, BRAMServer#(Bit#(asz), Bit#(64)) br) (NandSim)
   provisos (Add#(a__, asz, 32));

   Reg#(DmaMemHandle) dramRdHandle <- mkReg(0);
   Reg#(Bit#(32)) dramRdCnt <- mkReg(0);
   Reg#(Bit#(DmaAddrSize))      dramRdOffset <- mkReg(0);
   Reg#(Bit#(6)) dramRdTag <- mkReg(0);
   Reg#(Bit#(asz)) nandRdAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandRdLimit <- mkReg(0);

   Reg#(DmaMemHandle) dramWrHandle <- mkReg(0);
   Reg#(Bit#(32)) dramWrCnt <- mkReg(0);
   Reg#(Bit#(32)) dramWrDone <- mkReg(0);
   Reg#(Bit#(DmaAddrSize))      dramWrOffset <- mkReg(0);
   Reg#(Bit#(6)) dramWrTag <- mkReg(0);
   Reg#(Bit#(asz)) nandWrAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandWrLimit <- mkReg(0);

   Reg#(Bit#(asz)) nandEraseAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandEraseLimit <- mkReg(0);
   Reg#(Bit#(asz)) nandEraseCnt <- mkReg(0);

   Reg#(Bit#(8)) burstLen <- mkReg(8);
   Reg#(Bit#(8)) dramWrBurstLen <- mkReg(8);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(8*8);

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
      method Action startRead(Bit#(32) handle, Bit#(32) dramOffset, Bit#(32) nandAddr,
			      Bit#(32) numBytes, Bit#(32) bl);
         dramWrHandle <= handle;
	 dramWrOffset <= truncate(dramOffset);
         dramWrCnt <= numBytes>>3;
         dramWrDone <= numBytes>>3;
	 nandRdAddr <= truncate(nandAddr >> 3);
	 nandRdLimit <= truncate((nandAddr + numBytes) >> 3);
         burstLen <= truncate(bl);
         deltaOffset <= 8*truncate(bl);
      endmethod
   /*!
   * Reads from DRAM and writes to NAND
   */
      method Action startWrite(Bit#(32) handle, Bit#(32) dramOffset, Bit#(32) nandAddr,
			       Bit#(32) numBytes, Bit#(32) bl);
         dramRdHandle <= handle;
         dramRdOffset <= truncate(dramOffset);
         dramRdCnt <= numBytes>>3;
	 nandWrAddr <= truncate(nandAddr >> 3);
	 nandWrLimit <= truncate((nandAddr + numBytes) >> 3);
         dramWrBurstLen <= truncate(bl);
         deltaOffset <= 8*truncate(bl);
      endmethod

      method Action startErase(Bit#(32) nandAddr, Bit#(32) numBytes);
	 nandEraseAddr <= truncate(nandAddr >> 3);
	 nandEraseLimit <= truncate((nandAddr + numBytes) >> 3);
	 nandEraseCnt <= truncate(numBytes >> 3);
      endmethod

   endinterface

   interface DMAReadClient readClient;
      interface GetF readReq;
         method ActionValue#(DMAAddressRequest) get() if (dramRdCnt > 0);
            dramRdCnt <= dramRdCnt-extend(burstLen);
            dramRdOffset <= dramRdOffset + deltaOffset;
            if (dramRdCnt <= extend(burstLen))
               indication.writeDone(0); // read from DRAM is write to NAND
            //else if (dramRdCnt[5:0] == 6'b0)
            //   indication.readReq(dramRdCnt);
            return DMAAddressRequest { handle: dramRdHandle, address: dramRdOffset, burstLen: burstLen, tag: truncate(dramRdOffset) };
         endmethod
         method Bool notEmpty();
            return dramRdCnt > 0;
         endmethod
      endinterface : readReq
      interface PutF readData;
         method Action put(DMAData#(64) d);
	    $display("readData/nandWrite nandWrAddr=%h d=%h tag=%h", nandWrAddr, d.data, d.tag);
	    br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:nandWrAddr, datain:d.data});
	    nandWrAddr <= nandWrAddr+1;
         endmethod
         method Bool notFull();
            return True;
         endmethod
      endinterface : readData
   endinterface
   interface DMAWriteClient writeClient;
      interface GetF writeReq;
	 method ActionValue#(DMAAddressRequest) get() if (dramWrCnt > 0);
	    dramWrCnt <= dramWrCnt - extend(dramWrBurstLen);
	    dramWrOffset <= dramWrOffset + deltaOffset;
	    let tag = truncate(dramWrOffset>>3);
	    dramWrTag <= tag;
	    return DMAAddressRequest { handle: dramWrHandle, address: dramWrOffset, burstLen: dramWrBurstLen, tag: tag };
	 endmethod
	 method Bool notEmpty();
	    return dramWrCnt > 0;
	 endmethod
      endinterface: writeReq
      interface GetF writeData;
	 method ActionValue#(DMAData#(64)) get();
	    let v <- br.response.get();
	    $display("writeReq v=%h", v);
	    return DMAData { data: v, tag: dramWrTag };
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
