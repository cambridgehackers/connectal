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
   method Action startRead(Bit#(32) dramhandle, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numWords, Bit#(32) burstLen);
   method Action startWrite(Bit#(32) dramhandle, Bit#(32) dramOffset, Bit#(32) nandAddr, Bit#(32) numWords, Bit#(32) burstLen);
   method Action startErase(Bit#(32) nandAddr, Bit#(32) numWords, Bit#(32) burstLen);
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
   Reg#(DmaMemHandle) dramWrHandle <- mkReg(0);
   Reg#(Bit#(32)) dramRdCnt <- mkReg(0);
   Reg#(Bit#(32)) dramWrCnt <- mkReg(0);
   Reg#(Bit#(DmaAddrSize))      dramRdOffset <- mkReg(0);
   Reg#(Bit#(DmaAddrSize))      dramWrOffset <- mkReg(0);
   Reg#(Bit#(asz)) nandRdAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandWrAddr <- mkReg(0);
   Reg#(Bit#(asz)) nandRdLimit <- mkReg(0);
   Reg#(Bit#(asz)) nandWrLimit <- mkReg(0);

   Reg#(Bit#(8)) dramRdTag <- mkReg(0);
   Reg#(Bit#(8)) dramWrTag <- mkReg(0);

   Reg#(Bit#(8)) burstLen <- mkReg(8);
   Reg#(Bit#(8)) dramWrBurstLen <- mkReg(8);
   Reg#(Bit#(DmaAddrSize)) deltaOffset <- mkReg(8*8);

   rule readBram if (nandRdAddr < nandRdLimit);
      br.request.put(BRAMRequest{write:False,responseOnWrite:?,address:nandRdAddr,datain:?});
      nandRdAddr <= nandRdAddr+1;
   endrule

   interface NandSimRequest request;
   /*!
   * Reads from NAND and writes to DRAM
   */
       method Action startRead(Bit#(32) handle, Bit#(32) dramOffset, Bit#(32) nandAddr,
			       Bit#(32) numWords, Bit#(32) bl) if (dramWrCnt == 0);
          dramWrHandle <= handle;
	  dramWrOffset <= truncate(dramOffset);
          dramWrCnt <= numWords>>1;
	  nandRdAddr <= truncate(nandAddr);
	  nandRdLimit <= truncate(nandAddr + numWords);
          burstLen <= truncate(bl);
          deltaOffset <= 8*truncate(bl);
       endmethod
   /*!
   * Reads from DRAM and writes to NAND
   */
       method Action startWrite(Bit#(32) handle, Bit#(32) dramOffset, Bit#(32) nandAddr,
				Bit#(32) numWords, Bit#(32) bl) if (dramRdCnt == 0);
          dramRdHandle <= handle;
          dramRdOffset <= truncate(dramOffset);
          dramRdCnt <= numWords>>1;
	  nandWrAddr <= truncate(nandAddr);
	  nandWrLimit <= truncate(nandAddr + numWords);
          dramWrBurstLen <= truncate(bl);
          deltaOffset <= 8*truncate(bl);
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
	    return DMAData { data: v, tag: dramWrTag };
	 endmethod
	 method Bool notEmpty();
	    return nandRdAddr < nandRdLimit;
	 endmethod
      endinterface: writeData
      interface PutF writeDone;
	 method Action put(Bit#(8) tag);
            if (dramWrCnt <= extend(dramWrBurstLen))
	       indication.readDone(0);
	 endmethod
	 method Bool notFull();
	    return True;
	 endmethod
      endinterface: writeDone
   endinterface
endmodule
