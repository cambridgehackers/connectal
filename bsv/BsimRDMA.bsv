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

// BSV Libraries
import FIFOF::*;
import Vector::*;
import GetPut::*;
import ClientServer::*;
import BRAMFIFO::*;
import BRAM::*;

// XBSV Libraries
import PortalMemory::*;
import PortalRMemory::*;
import Adapter::*;

import "BDPI" function Action pareff(Bit#(32) handle, Bit#(32) size);
import "BDPI" function Action init_pareff();
import "BDPI" function Action write_pareff32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_pareff64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_pareff32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff64(Bit#(32) handle, Bit#(32) addr);
		       
interface BsimRdmaReadWrite#(numeric type dsz);
   method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(dsz) v);
   method ActionValue#(Bit#(dsz)) read_pareff(Bit#(32) handle, Bit#(32) addr);
endinterface

typeclass SelectBsimRdmaReadWrite#(numeric type dsz);
   module selectBsimRdmaReadWrite(BsimRdmaReadWrite#(dsz) ifc);
endtypeclass

instance SelectBsimRdmaReadWrite#(32);
   module selectBsimRdmaReadWrite(BsimRdmaReadWrite#(32) ifc);
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
	  write_pareff32(handle, addr, v);
       endmethod
       method ActionValue#(Bit#(32)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v <- read_pareff32(handle, addr);
	  return v;
       endmethod
   endmodule
endinstance
instance SelectBsimRdmaReadWrite#(64);
   module selectBsimRdmaReadWrite(BsimRdmaReadWrite#(64) ifc);
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
	  write_pareff64(handle, addr, v);
       endmethod
       method ActionValue#(Bit#(64)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v <- read_pareff64(handle, addr);
	  return v;
       endmethod
   endmodule
endinstance

//
// @brief DMA server for use in Bluesim
//
// @param dsz Number of bits in the data bus
//
interface BsimDMAServer#(numeric type dsz);
   interface DMARequest request;
endinterface

module mkBsimDMAReadInternal#(Vector#(numReadClients, DMAReadClient#(dsz)) readClients)(DMARead)
      provisos (SelectBsimRdmaReadWrite#(dsz));
   
   let dsz = valueOf(dsz);
   let rw <- selectBsimRdmaReadWrite();

   Reg#(DmaMemHandle)     handleReg <- mkReg(0);
   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(8))         burstReg <- mkReg(0);   
   Reg#(Bit#(8))           tagReg <- mkReg(0);
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      let s = selectReg+1;
      if (s == fromInteger(valueOf(numReadClients)))
	 s = 0;
      selectReg <= s;
   endrule

   rule loadClient if (burstReg == 0);
      activeChan <= selectReg;
      let req <- readClients[selectReg].readReq.get();
      //$display("dmaread.loadClient activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.handle, req.address, req.burstLen);
      handleReg <= req.handle;
      addrReg <= truncate(req.address);
      burstReg <= req.burstLen;
      tagReg <= req.tag;
   endrule
   
   rule readData if (burstReg > 0);
      addrReg <= addrReg+fromInteger(valueOf(TDiv#(dsz,8)));
      burstReg <= burstReg-1;
      Bit#(dsz) v <- rw.read_pareff(handleReg, addrReg);
      //$display("dmaread.readData activeChan=%d handle=%h addr=%h burst=%h v=%h", activeChan, handleReg, addrReg, burstReg, v);
      readClients[activeChan].readData.put(DMAData { data: v, tag: tagReg});
   endrule
   
   method ActionValue#(DmaDbgRec) dbg();
      return ?;
   endmethod
   
endmodule


module mkBsimDMAWriteInternal#(Vector#(numWriteClients, DMAWriteClient#(dsz)) writeClients)(DMAWrite)
      provisos (SelectBsimRdmaReadWrite#(dsz));

   let dsz = valueOf(dsz);
   let rw <- selectBsimRdmaReadWrite();

   Reg#(DmaMemHandle)   handleReg <- mkReg(0);
   Reg#(Bit#(32))         addrReg <- mkReg(0);
   Reg#(Bit#(8))         burstReg <- mkReg(0);   
   Reg#(Bit#(8))           tagReg <- mkReg(0);
   Reg#(DmaChannelId)  activeChan <- mkReg(0);
   Reg#(DmaChannelId)   selectReg <- mkReg(0);
   
   rule incSelectReg;
      let s = selectReg+1;
      if (s == fromInteger(valueOf(numWriteClients)))
	 s = 0;
      selectReg <= s;
   endrule

   rule loadClient if (burstReg == 0);
      activeChan <= selectReg;
      let req   <- writeClients[selectReg].writeReq.get();
      //$display("dmawrite.loadClient activeChan=%d handle=%h addr=%h burst=%h", selectReg, req.handle, req.address, req.burstLen);
      handleReg   <= req.handle;
      addrReg   <= truncate(req.address);
      burstReg  <= req.burstLen;
      tagReg    <= req.tag;
   endrule
   
   rule writeData if (burstReg > 0);
      addrReg <= addrReg+fromInteger(valueOf(TDiv#(dsz,8)));
      let v <- writeClients[activeChan].writeData.get();
      if (v.tag != tagReg) begin
	 //$display("BsimWriteData tag mismatch %h expected %h", v.tag, tagReg);
      end
      if (burstReg == 1)
	 writeClients[activeChan].writeDone.put(v.tag);
      burstReg <= burstReg-1;
      //$display("writeData activeChan=%d handle=%h addr=%h", activeChan, handleReg, addrReg);
      rw.write_pareff(handleReg, addrReg, v.data);
   endrule
   
   method ActionValue#(DmaDbgRec) dbg();
      return ?;
   endmethod

endmodule
		 
		 	 
//
// @brief Creates a DMA controller for read and write clients
//
// @param dmaIndication Interface for notifying software
// @param readClients The read clients.
// @param writeClients The writeclients.
//
module mkBsimDMAServer#(DMAIndication dmaIndication,
			Vector#(numReadClients, DMAReadClient#(dsz)) readClients,
			Vector#(numWriteClients, DMAWriteClient#(dsz)) writeClients)
   (BsimDMAServer#(dsz))
   provisos (SelectBsimRdmaReadWrite#(dsz));

	    
   Reg#(Bool) inited <- mkReg(False);

   DMARead reader;
   if (valueOf(numReadClients) > 0)
      reader <- mkBsimDMAReadInternal(readClients);
   else
      reader = (interface DMARead;
		   method ActionValue#(DmaDbgRec) dbg();
		      return ?;
		   endmethod
		endinterface);

   DMAWrite writer;
   if (valueOf(numWriteClients) > 0)
      writer <- mkBsimDMAWriteInternal(writeClients);
   else
      writer = (interface DMAWrite;
		    method ActionValue#(DmaDbgRec) dbg();
		        return ?;
		    endmethod
		endinterface);

   rule initialize(!inited);
      inited <= True;
      init_pareff();
   endrule
   
   interface DMARequest request;
      method Action getStateDbg(ChannelType rc);
	 let rv = ?;
	 if (rc == Read)
	    rv <- reader.dbg;
	 if (rc == Write)
	    rv <- writer.dbg;
	 dmaIndication.reportStateDbg(rv);
      endmethod
      method Action paref(Bit#(32) handle, Bit#(32) size);
	 pareff(handle, size); 
	 dmaIndication.parefResp(handle);
      endmethod
   endinterface
endmodule
