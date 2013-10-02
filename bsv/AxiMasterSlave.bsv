
// Copyright (c) 2012 Nokia, Inc.
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

import Connectable::*;
import RegFile::*;
import BRAMFIFO::*;
import FIFO::*;
import FIFOF::*;
import FIFOLevel::*;
import SpecialFIFOs::*;
import AxiClientServer::*;
import Vector::*;

interface AxiMasterRead#(type addrWidth, type busWidth);
   method ActionValue#(Bit#(addrWidth)) readAddr();
   method Bit#(8) readBurstLen();
   method Bit#(3) readBurstWidth();
   method Bit#(2) readBurstType();  // drive with 2'b01
   method Bit#(3) readBurstProt(); // drive with 3'b000
   method Bit#(4) readBurstCache(); // drive with 4'b0011
   method Bit#(1) readId();

   method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(1) id);
endinterface

interface AxiMasterWrite#(type addrWidth, type busWidth, type busWidthBytes);
   method ActionValue#(Bit#(addrWidth)) writeAddr();
   method Bit#(8) writeBurstLen();
   method Bit#(3) writeBurstWidth();
   method Bit#(2) writeBurstType();  // drive with 2'b01
   method Bit#(3) writeBurstProt(); // drive with 3'b000
   method Bit#(4) writeBurstCache(); // drive with 4'b0011
   method Bit#(1) writeId();

   method ActionValue#(Bit#(busWidth)) writeData();
   method Bit#(1) writeWid();
   method Bit#(busWidthBytes) writeDataByteEnable();
   method Bit#(1) writeLastDataBeat(); // last data beat
   method Action writeResponse(Bit#(2) responseCode, Bit#(1) id);
endinterface

interface AxiMaster#(type addrWidth, type busWidth, type busWidthBytes);
   interface AxiMasterRead#(addrWidth, busWidth) read;
   interface AxiMasterWrite#(addrWidth, busWidth, busWidthBytes) write;
endinterface

typedef enum {
    ReadBurstWidth32 = 3'b010,
    ReadBurstWidth64 = 3'b011,
    ReadBurstWidth128 = 3'b100
} Axi3ReadBurstWidth deriving (Bits, Eq);

interface Axi3MasterRead#(type addrWidth, type busWidth, type idWidth);
   method ActionValue#(Bit#(addrWidth)) readAddr();
   method Bit#(4) readBurstLen();
   method Bit#(3) readBurstWidth();
   method Bit#(2) readBurstType();  // drive with 2'b01
   method Bit#(3) readBurstProt(); // drive with 3'b000
   method Bit#(4) readBurstCache(); // drive with 4'b0011
   method Bit#(idWidth) readId();

   method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(idWidth) id);
endinterface

interface Axi3MasterWrite#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   method ActionValue#(Bit#(addrWidth)) writeAddr();
   method Bit#(4) writeBurstLen();
   method Bit#(3) writeBurstWidth();
   method Bit#(2) writeBurstType();  // drive with 2'b01
   method Bit#(3) writeBurstProt(); // drive with 3'b000
   method Bit#(4) writeBurstCache(); // drive with 4'b0011
   method Bit#(idWidth) writeId();

   method ActionValue#(Bit#(busWidth)) writeData();
   method Bit#(idWidth) writeWid();
   method Bit#(busWidthBytes) writeDataByteEnable();
   method Bit#(1) writeLastDataBeat(); // last data beat
   method Action writeResponse(Bit#(2) responseCode, Bit#(idWidth) id);
endinterface

interface Axi3Master#(type addrWidth, type busWidth, type busWidthBytes, type idWidth);
   interface Axi3MasterRead#(addrWidth, busWidth, idWidth) read;
   interface Axi3MasterWrite#(addrWidth, busWidth, busWidthBytes, idWidth) write;
endinterface

interface AxiSlaveRead#(type addrWidth, type busWidth, type busWidthBytes);
   method Action readAddr(Bit#(addrWidth) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                          Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache);

   method ActionValue#(Bit#(busWidth)) readData();
   method Bit#(1) last();
   // method Action readResponse(Bit#(2) responseCode);
endinterface

//FIXME: should have transaction ID's
interface AxiSlaveWrite#(type addrWidth, type busWidth, type busWidthBytes);
   method Action writeAddr(Bit#(addrWidth) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                           Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache);
   method Action writeData(Bit#(busWidth) data, Bit#(busWidthBytes) byteEnable, Bit#(1) last);
   method ActionValue#(Bit#(2)) writeResponse();
endinterface

interface AxiSlave#(type addrWidth, type busWidth, type busWidthBytes);
   interface AxiSlaveRead#(addrWidth, busWidth, busWidthBytes) read;
   interface AxiSlaveWrite#(addrWidth, busWidth, busWidthBytes) write;
endinterface

interface Axi3SlaveRead#(type addrWidth, type busWidth, type busWidthBytes);
   method Action readAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                          Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) arid);
   method ActionValue#(Bit#(busWidth)) readData();
   method Bit#(1) last();
   method Bit#(12) rid();
   // method Action readResponse(Bit#(2) responseCode);
endinterface

interface Axi3SlaveWrite#(type addrWidth, type busWidth, type busWidthBytes);
   method Action writeAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                           Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) awid);
   method Action writeData(Bit#(busWidth) data, Bit#(busWidthBytes) byteEnable, Bit#(1) last);
   method ActionValue#(Bit#(2)) writeResponse();
   method ActionValue#(Bit#(12)) bid();
endinterface

interface Axi3Slave#(type addrWidth, type busWidth, type busWidthBytes);
   interface Axi3SlaveRead#(addrWidth, busWidth, busWidthBytes) read;
   interface Axi3SlaveWrite#(addrWidth, busWidth, busWidthBytes) write;
endinterface

interface AxiMasterServer#(type addrWidth, type busWidth, type busWidthBytes, type tagSize);
   method Action readAddr(Bit#(addrWidth) addr, Bit#(8) numWords);
   method Action readAddrTagged(Bit#(addrWidth) addr, Bit#(8) numWords, Bit#(tagSize) tag);
   method ActionValue#(Bit#(busWidth)) readData();
   method Bit#(tagSize) readTag();

   method Action writeAddr(Bit#(addrWidth) addr, Bit#(8) numWords);
   method Action writeData(Bit#(busWidth) data);
   method ActionValue#(Bit#(2)) writeResponse();

   interface AxiMaster#(addrWidth,busWidth,busWidthBytes) axi;
endinterface

typedef struct {
    Bit#(addrWidth) addr;
    Bit#(8) numWords;
} AddrBurst#(type addrWidth) deriving (Bits);


module mkAxiSlaveMux#(Vector#(numInputs,Axi3Slave#(addrWidth, busWidth,busWidthBytes)) inputs) (Axi3Slave#(addrWidth, busWidth, busWidthBytes))
   provisos(Add#(nz, TLog#(numInputs), 4));

   Reg#(Bit#(TLog#(numInputs))) ws <- mkReg(0);
   Reg#(Bit#(TLog#(numInputs))) rs <- mkReg(0);
   
   interface Axi3SlaveWrite write;
      method Action writeAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
			      Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache,
			      Bit#(12) awid);
	 Bit#(TLog#(numInputs)) wsv = truncate(addr[19:16]); 
	 inputs[wsv].write.writeAddr(addr,burstLen,burstWidth,burstType,burstProt,burstCache,awid);
	 ws <= wsv;
      endmethod
      method Action writeData(Bit#(busWidth) v, Bit#(busWidthBytes) byteEnable, Bit#(1) last);
	 inputs[ws].write.writeData(v,byteEnable,last);
      endmethod
      method ActionValue#(Bit#(2)) writeResponse();
	 let rv <- inputs[ws].write.writeResponse;
	 return rv;
      endmethod
      method ActionValue#(Bit#(12)) bid();
	 let rv <- inputs[ws].write.bid;
	 return rv;
      endmethod
   endinterface
   interface Axi3SlaveRead read;
      method Action readAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
			     Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) arid);
	 Bit#(TLog#(numInputs)) rsv = truncate(addr[19:16]); 
	 inputs[rsv].read.readAddr(addr,burstLen,burstWidth,burstType,burstProt,burstCache,arid);
	 rs <= rsv;
      endmethod
      method Bit#(1) last();
	 return inputs[rs].read.last;
      endmethod
      method Bit#(12) rid();
         return inputs[rs].read.rid;
      endmethod
      method ActionValue#(Bit#(busWidth)) readData();
	 let rv <- inputs[rs].read.readData;
	 return rv;
      endmethod
   endinterface
endmodule

module mkAxiMasterServer(AxiMasterServer#(addrWidth,busWidth,busWidthBytes,tagSize)) provisos(Div#(busWidth,8,busWidthBytes),Add#(1,a,busWidth));
   Reg#(Bit#(addrWidth)) wAddrReg <- mkReg(0);
   Reg#(Bit#(1)) writeIdReg <- mkReg(0);
   Reg#(Bit#(1)) readIdReg <- mkReg(0);
   FIFOF#(Bit#(busWidth)) wfifo <- mkSizedBRAMFIFOF(32);
   FIFOF#(Bit#(2)) bfifo <- mkSizedBRAMFIFOF(32);
   Reg#(Bit#(8)) wBurstCountReg <- mkReg(0);
   Reg#(Bool) wAddressPresented <- mkReg(False);

   FIFOF#(AddrBurst#(addrWidth)) raddrFifo <- mkSizedBypassFIFOF(4);
   FIFOF#(Bit#(tagSize)) tagFifo <- mkSizedFIFOF(4);
   //FIFOF#(AddrBurst) raddrFifo <- mkSizedBRAMFIFOF(8);
   let rfifoDepth = 1024;
   FIFOF#(Bit#(busWidth)) rfifo <- mkSizedBRAMFIFOF(rfifoDepth);
   Reg#(Bit#(11)) rfifoWordsAvail <- mkReg(rfifoDepth);
   PulseWire enqPulse <- mkPulseWire();
   PulseWire deqPulse <- mkPulseWire();
   Wire#(Bit#(8)) readCount <- mkDWire(0);

   rule updateWordsAvailCount;
      let avail = rfifoWordsAvail;
      if (enqPulse)
          avail = avail - extend(readCount);
      if (deqPulse)
          avail = avail + 1;
      rfifoWordsAvail <= avail;
   endrule

   method Action readAddr(Bit#(addrWidth) addr, Bit#(8) numWords);
       //$display("readAddr addr %h burstCountReg %d", addr, numWords);
       raddrFifo.enq(AddrBurst { addr: addr, numWords: numWords});
       tagFifo.enq(0);
   endmethod

   method Action readAddrTagged(Bit#(addrWidth) addr, Bit#(8) numWords, Bit#(tagSize) tag);
       //$display("readAddr addr %h burstCountReg %d", addr, numWords);
       raddrFifo.enq(AddrBurst { addr: addr, numWords: numWords});
       tagFifo.enq(tag);
   endmethod

   method ActionValue#(Bit#(busWidth)) readData() if (rfifo.notEmpty);
       //$display("axiMaster.readData %h", rfifo.first);
       deqPulse.send;
       rfifo.deq;
       tagFifo.deq;
       return rfifo.first;
   endmethod

   method Bit#(tagSize) readTag();
       return tagFifo.first;
   endmethod

   method Action writeAddr(Bit#(addrWidth) addr, Bit#(8) numWords) if (wBurstCountReg == 0);
       wAddrReg <= addr;
       wBurstCountReg <= numWords;
       wAddressPresented <= False;
   endmethod

   method Action writeData(Bit#(busWidth) data) if (wfifo.notFull);
       wfifo.enq(data);
   endmethod
   method ActionValue#(Bit#(2)) writeResponse() if (bfifo.notEmpty);
       bfifo.deq;
       return bfifo.first;
   endmethod

   interface AxiMaster axi;
       interface AxiMasterWrite write;
           method ActionValue#(Bit#(addrWidth)) writeAddr() if (wBurstCountReg != 0 && !wAddressPresented);
               wAddressPresented <= True;
               writeIdReg <= writeIdReg + 1;
               return wAddrReg;
           endmethod
           method Bit#(8) writeBurstLen();
               return wBurstCountReg-1;
           endmethod
           method Bit#(3) writeBurstWidth();
               if (valueOf(busWidth) == 32)
                   return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
               else if (valueOf(busWidth) == 64)
                   return 3'b011;
               else
                   return 3'b100;
           endmethod
           method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
               return 2'b01; // increment address
           endmethod
           method Bit#(3) writeBurstProt(); // drive with 3'b000
               return 3'b000;
           endmethod
           method Bit#(4) writeBurstCache(); // drive with 4'b0011
               return 4'b0011;
           endmethod
           method Bit#(1) writeId();
               return writeIdReg;
           endmethod

           method ActionValue#(Bit#(busWidth)) writeData() if (wBurstCountReg != 0 && wfifo.notEmpty);
               wBurstCountReg <= wBurstCountReg - 1;

               let d = wfifo.first;
               wfifo.deq;
               return d;
           endmethod
           method Bit#(1) writeWid();
               return writeIdReg;
           endmethod
           method Bit#(busWidthBytes) writeDataByteEnable();
               return maxBound;
           endmethod
           method Bit#(1) writeLastDataBeat(); // last data beat
               return (wBurstCountReg == 8'd1) ? 1'b1 : 1'b0;
           endmethod

           method Action writeResponse(Bit#(2) responseCode, Bit#(1) id) if (bfifo.notFull);
               if (responseCode != 0)
                   bfifo.enq(responseCode);
           endmethod
       endinterface

       interface AxiMasterRead read;
           method ActionValue#(Bit#(addrWidth)) readAddr() if (extend(unpack(raddrFifo.first.numWords)) <= rfifoWordsAvail);
               enqPulse.send;
               readCount <= raddrFifo.first.numWords;
               raddrFifo.deq();
               readIdReg <= readIdReg + 1;
               return raddrFifo.first().addr;
           endmethod
           method Bit#(8) readBurstLen();
               return raddrFifo.first().numWords-1;
           endmethod
           method Bit#(3) readBurstWidth();
               if (valueOf(busWidth) == 32)
                   return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
               else if (valueOf(busWidth) == 64)
                   return 3'b011;
               else
                   return 3'b100;
           endmethod
           method Bit#(2) readBurstType();  // drive with 2'b01
               return 2'b01;
           endmethod
           method Bit#(3) readBurstProt(); // drive with 3'b000
               return 3'b000;
           endmethod
           method Bit#(4) readBurstCache(); // drive with 4'b0011
               return 4'b0011;
           endmethod
           method Bit#(1) readId();
               return readIdReg;
           endmethod
           method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(1) id) if (rfifo.notFull);
	       //$display("axi.read.readData %h bc %d", data, rBurstCountReg);
               rfifo.enq(data);
           endmethod
       endinterface
   endinterface
endmodule

module mkNullAxiMaster(AxiMaster#(addrWidth,busWidth,busWidthBytes)) provisos(Div#(busWidth,8,busWidthBytes),Add#(1,a,busWidth));
   interface AxiMasterWrite write;
       method ActionValue#(Bit#(addrWidth)) writeAddr() if (False);
           return 0;
       endmethod
       method Bit#(8) writeBurstLen();
           return 0;
       endmethod
       method Bit#(3) writeBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (valueOf(busWidth) == 64)
               return 3'b011;
           else
               return 3'b100;
       endmethod
       method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
           return 2'b01; // increment address
       endmethod
       method Bit#(3) writeBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) writeBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod
       method Bit#(1) writeId();
           return 0;
       endmethod

       method ActionValue#(Bit#(busWidth)) writeData();
           return 0;
       endmethod
       method Bit#(1) writeWid();
           return 0;
       endmethod
       method Bit#(busWidthBytes) writeDataByteEnable();
           return maxBound;
       endmethod
       method Bit#(1) writeLastDataBeat(); // last data beat
           return 0;
       endmethod

       method Action writeResponse(Bit#(2) responseCode, Bit#(1) id);
       endmethod
   endinterface

   interface AxiMasterRead read;
       method ActionValue#(Bit#(addrWidth)) readAddr() if (False);
           return 0;
       endmethod
       method Bit#(8) readBurstLen();
           return 0;
       endmethod
       method Bit#(3) readBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (valueOf(busWidth) == 64)
               return 3'b011;
           else
               return 3'b100;
       endmethod
       method Bit#(2) readBurstType();  // drive with 2'b01
           return 2'b01;
       endmethod
       method Bit#(3) readBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) readBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod
       method Bit#(1) readId();
           return 0;
       endmethod
       method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(1) id);
       endmethod
   endinterface
endmodule

module mkNullAxi3Master(Axi3Master#(addrWidth,busWidth,busWidthBytes,idWidth)) provisos(Div#(busWidth,8,busWidthBytes),Add#(1,a,busWidth));
   interface Axi3MasterWrite write;
       method ActionValue#(Bit#(addrWidth)) writeAddr() if (False);
           return 0;
       endmethod
       method Bit#(4) writeBurstLen();
           return 0;
       endmethod
       method Bit#(3) writeBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (valueOf(busWidth) == 64)
               return 3'b011;
           else
               return 3'b100;
       endmethod
       method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
           return 2'b01; // increment address
       endmethod
       method Bit#(3) writeBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) writeBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod
       method Bit#(idWidth) writeId();
           return 0;
       endmethod

       method ActionValue#(Bit#(busWidth)) writeData();
           return 0;
       endmethod
       method Bit#(idWidth) writeWid();
           return 0;
       endmethod
       method Bit#(busWidthBytes) writeDataByteEnable();
           return maxBound;
       endmethod
       method Bit#(1) writeLastDataBeat(); // last data beat
           return 0;
       endmethod

       method Action writeResponse(Bit#(2) responseCode, Bit#(idWidth) id);
       endmethod
   endinterface

   interface Axi3MasterRead read;
       method ActionValue#(Bit#(addrWidth)) readAddr() if (False);
           return 0;
       endmethod
       method Bit#(4) readBurstLen();
           return 0;
       endmethod
       method Bit#(3) readBurstWidth();
           if (valueOf(busWidth) == 32)
               return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
           else if (valueOf(busWidth) == 64)
               return 3'b011;
           else
               return 3'b100;
       endmethod
       method Bit#(2) readBurstType();  // drive with 2'b01
           return 2'b01;
       endmethod
       method Bit#(3) readBurstProt(); // drive with 3'b000
           return 3'b000;
       endmethod
       method Bit#(4) readBurstCache(); // drive with 4'b0011
           return 4'b0011;
       endmethod
       method Bit#(idWidth) readId();
           return 0;
       endmethod
       method Action readData(Bit#(busWidth) data, Bit#(2) resp, Bit#(1) last, Bit#(idWidth) id);
       endmethod
   endinterface
endmodule

module mkAxiSlaveFromRegFile#(RegFile#(Bit#(regFileBusWidth), Bit#(busWidth)) rf)
                             (AxiSlave#(addrWidth, busWidth, busWidthBytes)) 
                             provisos(Div#(busWidth,8,busWidthBytes),
                                       Add#(nz, regFileBusWidth, addrWidth));
    Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
    Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
    Reg#(Bit#(8)) readBurstCountReg <- mkReg(0);
    Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
    FIFO#(Bit#(2)) writeRespFifo <- mkFIFO();

    Bool verbose = False;
    interface AxiSlaveRead read;
        method Action readAddr(Bit#(addrWidth) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                               Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache) if (readBurstCountReg == 0);
            if (verbose) $display("axiSlave.read.readAddr %h bc %d", addr, burstLen+1);
            readAddrReg <= truncate(addr/fromInteger(valueOf(busWidthBytes)));
            readBurstCountReg <= burstLen+1;
        endmethod

        method ActionValue#(Bit#(busWidth)) readData() if (readBurstCountReg > 0);
            let data = rf.sub(readAddrReg);
            if (verbose) $display("axiSlave.read.readData %h %h %d", readAddrReg, data, readBurstCountReg);
            readBurstCountReg <= readBurstCountReg - 1;
            readAddrReg <= readAddrReg + 1;
            return data;
        endmethod
        method Bit#(1) last();
            return (readBurstCountReg == 1) ? 1 : 0;
        endmethod
    endinterface

    interface AxiSlaveWrite write;
       method Action writeAddr(Bit#(addrWidth) addr, Bit#(8) burstLen, Bit#(3) burstWidth,
                               Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache) if (writeBurstCountReg == 0);
           if (verbose) $display("axiSlave.write.writeAddr %h bc %d", addr, burstLen+1);
           writeAddrReg <= truncate(addr/fromInteger(valueOf(busWidthBytes)));
           writeBurstCountReg <= burstLen+1;
       endmethod

       method Action writeData(Bit#(busWidth) data, Bit#(busWidthBytes) byteEnable, Bit#(1) last) if (writeBurstCountReg > 0);
           if (verbose) $display("writeData %h %h %d", writeAddrReg, data, writeBurstCountReg);
           rf.upd(writeAddrReg, data);
           writeAddrReg <= writeAddrReg + 1;
           writeBurstCountReg <= writeBurstCountReg - 1;
            if (verbose) $display("axiSlave.write.writeData %h %h %d", writeAddrReg, data, writeBurstCountReg);
           if (writeBurstCountReg == 1)
               writeRespFifo.enq(0);
       endmethod
       method ActionValue#(Bit#(2)) writeResponse();
           writeRespFifo.deq;
           return writeRespFifo.first;
       endmethod
    endinterface
endmodule

module mkAxiSlaveRegFile(AxiSlave#(addrWidth, busWidth, busWidthBytes)) provisos(Div#(busWidth,8,busWidthBytes),Add#(nz, 21, addrWidth));
       RegFile#(Bit#(21), Bit#(busWidth)) rf <- mkRegFileFull();
       AxiSlave#(addrWidth, busWidth, busWidthBytes) axiSlave <- mkAxiSlaveFromRegFile(rf);
       return axiSlave;
endmodule

module mkAxiSlaveRegFileLoad#(String fileName)(AxiSlave#(addrWidth, busWidth, busWidthBytes)) provisos(Div#(busWidth,8,busWidthBytes),Add#(nz, 21, addrWidth));
       RegFile#(Bit#(21), Bit#(busWidth)) rf <- mkRegFileFullLoad(fileName);
       AxiSlave#(addrWidth, busWidth, busWidthBytes) axiSlave <- mkAxiSlaveFromRegFile(rf);
       return axiSlave;
endmodule

module mkAxi3SlaveFromRegFile#(RegFile#(Bit#(regFileBusWidth), Bit#(busWidth)) rf)
                              (Axi3Slave#(addrWidth, busWidth, busWidthBytes))
                              provisos(Div#(busWidth,8,busWidthBytes),
                                       Add#(nz, regFileBusWidth, addrWidth));
    Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
    Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
    Reg#(Bit#(12)) readIdReg <- mkReg(0);
    Reg#(Bit#(12)) writeIdReg <- mkReg(0);
    Reg#(Bit#(4)) readBurstCountReg <- mkReg(0);
    Reg#(Bit#(4)) writeBurstCountReg <- mkReg(0);
    FIFO#(Bit#(2)) writeRespFifo <- mkFIFO();
    FIFO#(Bit#(12)) writeIdFifo <- mkFIFO();

    Bool verbose = False;
    interface Axi3SlaveRead read;
        method Action readAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                               Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) id) if (readBurstCountReg == 0);
            if (verbose) $display("axiSlave.read.readAddr %h bc %d", addr, burstLen+1);
            readAddrReg <= truncate(addr/fromInteger(valueOf(busWidthBytes)));
	    readIdReg <= id;
            readBurstCountReg <= burstLen+1;
        endmethod

        method ActionValue#(Bit#(busWidth)) readData() if (readBurstCountReg > 0);
            let data = rf.sub(readAddrReg);
            if (verbose) $display("axiSlave.read.readData %h %h %d", readAddrReg, data, readBurstCountReg);
            readBurstCountReg <= readBurstCountReg - 1;
            readAddrReg <= readAddrReg + 1;
            return data;
        endmethod
        method Bit#(1) last();
            return (readBurstCountReg == 1) ? 1 : 0;
        endmethod
	method Bit#(12) rid();
	    return readIdReg;
	endmethod
    endinterface

    interface Axi3SlaveWrite write;
       method Action writeAddr(Bit#(addrWidth) addr, Bit#(4) burstLen, Bit#(3) burstWidth,
                               Bit#(2) burstType, Bit#(3) burstProt, Bit#(4) burstCache, Bit#(12) id) if (writeBurstCountReg == 0);
           if (verbose) $display("axiSlave.write.writeAddr %h bc %d", addr, burstLen+1);
           writeAddrReg <= truncate(addr/fromInteger(valueOf(busWidthBytes)));
	   writeIdReg <= id;
           writeBurstCountReg <= burstLen+1;
           writeIdFifo.enq(id);
       endmethod

       method Action writeData(Bit#(busWidth) data, Bit#(busWidthBytes) byteEnable, Bit#(1) last) if (writeBurstCountReg > 0);
           if (verbose) $display("writeData %h %h %d", writeAddrReg, data, writeBurstCountReg);
           rf.upd(writeAddrReg, data);
           writeAddrReg <= writeAddrReg + 1;
           writeBurstCountReg <= writeBurstCountReg - 1;
            if (verbose) $display("axiSlave.write.writeData %h %h %d", writeAddrReg, data, writeBurstCountReg);
           if (writeBurstCountReg == 1)
	   begin
               writeRespFifo.enq(0);
           end
       endmethod
       method ActionValue#(Bit#(2)) writeResponse();
           writeRespFifo.deq;
           return writeRespFifo.first;
       endmethod
	method ActionValue#(Bit#(12)) bid();
	    writeIdFifo.deq;
	    return writeIdFifo.first;
	endmethod
    endinterface
endmodule

module mkAxi3SlaveRegFile(Axi3Slave#(addrWidth, busWidth, busWidthBytes)) provisos(Div#(busWidth,8,busWidthBytes),Add#(a__, 21, addrWidth));
       RegFile#(Bit#(21), Bit#(busWidth)) rf <- mkRegFileFull();
       Axi3Slave#(addrWidth, busWidth, busWidthBytes) axiSlave <- mkAxi3SlaveFromRegFile(rf);
       return axiSlave;
endmodule

module mkMasterSlaveConnection#(AxiMasterWrite#(addrWidth, busWidth, busWidthBytes) axiw,
                                AxiMasterRead#(addrWidth, busWidth) axir,
                                AxiSlave#(addrWidth, busWidth, busWidthBytes) axiSlave)
                                ();
       
    Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
    Bool verbose = False;

    rule readAddr;
        Bit#(addrWidth) addr <-axir.readAddr;
        let burstLen = axir.readBurstLen;
        let burstWidth = axir.readBurstWidth;
        let burstType = axir.readBurstType;
        let burstProt = axir.readBurstProt;
        let burstCache = axir.readBurstCache;
        axiSlave.read.readAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache);
	if (verbose) $display("        MasterSlaveConnection.readAddr %h %d", addr, burstLen+1);
    endrule
    rule readData;
        let data <- axiSlave.read.readData();
        axir.readData(data, 2'b00, 0, 0);
        if (verbose) $display("        MasterSlaveConnection.readData %h", data);
    endrule
    rule writeAddr;
        Bit#(addrWidth) addr <- axiw.writeAddr;
        let burstLen = axiw.writeBurstLen;
        let burstWidth = axiw.writeBurstWidth;
        let burstType = axiw.writeBurstType;
        let burstProt = axiw.writeBurstProt;
        let burstCache = axiw.writeBurstCache;
        axiSlave.write.writeAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache);
        if (verbose) $display("        MasterSlaveConnection.writeAddr %h %d", addr, burstLen+1);
    endrule
    rule writeData;
        let data <- axiw.writeData;
	let id = axiw.writeWid;
        let byteEnable = axiw.writeDataByteEnable;
        let last = axiw.writeLastDataBeat;
        axiSlave.write.writeData(data, byteEnable, last);
        if (verbose) $display("        MasterSlaveConnection.writeData %h", data);
    endrule
    rule writeResponse;
        let response <- axiSlave.write.writeResponse();
        axiw.writeResponse(response, 0);
    endrule
endmodule

module mkClientSlaveConnection#(Axi3WriteClient#(addrWidth, busWidth, busWidthBytes,idWidth) axicw,
                                Axi3ReadClient#(addrWidth, busWidth,idWidth) axicr,
                                Axi3Slave#(addrWidth, busWidth, busWidthBytes) axiSlave)
                                () provisos (Div#(busWidth, 8, busWidthBytes),
				             Add#(1, a__, busWidth),
					     Add#(busWidth, b__, 65),
					     Add#(idWidth, 1, 13));
       
    Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
    Bool verbose = False;

    Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth) axic <- mkAxi3Client(axicw, axicr);
    Axi3Master#(addrWidth, busWidth,busWidthBytes,idWidth) m_axiMaster <- mkAxi3Master(axic);
    let axir = m_axiMaster.read;
    let axiw = m_axiMaster.write;

    rule readAddr;
        Bit#(addrWidth) addr <-axir.readAddr;
        let burstLen = axir.readBurstLen;
        let burstWidth = axir.readBurstWidth;
        let burstType = axir.readBurstType;
        let burstProt = axir.readBurstProt;
        let burstCache = axir.readBurstCache;
	let id = axir.readId;
        axiSlave.read.readAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache, id);
	if (verbose) $display("        MasterSlaveConnection.readAddr %h %d", addr, burstLen+1);
    endrule
    rule readData;
        let data <- axiSlave.read.readData();
	let id = axiSlave.read.rid();
        axir.readData(data, 2'b00, 0, id);
        if (verbose) $display("        MasterSlaveConnection.readData %h", data);
    endrule
    rule writeAddr;
        Bit#(addrWidth) addr <- axiw.writeAddr;
        let burstLen = axiw.writeBurstLen;
        let burstWidth = axiw.writeBurstWidth;
        let burstType = axiw.writeBurstType;
        let burstProt = axiw.writeBurstProt;
        let burstCache = axiw.writeBurstCache;
	let id = axiw.writeId;
        axiSlave.write.writeAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache, id);
        if (verbose) $display("        MasterSlaveConnection.writeAddr %h %d", addr, burstLen+1);
    endrule
    rule writeData;
        let data <- axiw.writeData;
        let id = axiw.writeWid;
        let byteEnable = axiw.writeDataByteEnable;
        let last = axiw.writeLastDataBeat;
        axiSlave.write.writeData(data, byteEnable, last);
        if (verbose) $display("        MasterSlaveConnection.writeData %h", data);
    endrule
    rule writeResponse;
        let response <- axiSlave.write.writeResponse();
        let id <- axiSlave.write.bid();
        axiw.writeResponse(response, id);
    endrule
endmodule

module mkAxi3MasterWires#(Axi3Client#(addrWidth,busWidth,busWidthBytes,idWidth) client)(Axi3Master#(addrWidth, busWidth,busWidthBytes,idWidth))
	 provisos(Div#(busWidth,8,busWidthBytes),Add#(1,a,busWidth));

    Wire#(Axi3ReadRequest#(addrWidth, idWidth))                      wReadRequest <- mkDWire(unpack(0));
    Wire#(Axi3WriteRequest#(addrWidth, idWidth))                     wWriteRequest <- mkDWire(unpack(0));
    Wire#(Axi3WriteData#(busWidth,busWidthBytes,idWidth)) wWriteData <- mkDWire(unpack(0));

    interface Axi3MasterWrite write;
	method ActionValue#(Bit#(addrWidth)) writeAddr();
	    let r <- client.write.address();
	    wWriteRequest <= r;
	    return r.address;
	endmethod
	method Bit#(4) writeBurstLen();
	    return wWriteRequest.burstLen;
	endmethod
	method Bit#(3) writeBurstWidth();
	    if (valueOf(busWidth) == 32)
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    else if (valueOf(busWidth) == 64)
		return 3'b011;
	    else
		return 3'b100;
	endmethod
	method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
	    return 2'b01; // increment address
	endmethod
	method Bit#(3) writeBurstProt(); // drive with 3'b000
	    return 3'b000;
	endmethod
	method Bit#(4) writeBurstCache(); // drive with 4'b0011
	    return 4'b0011;
	endmethod
	method Bit#(idWidth) writeId();
	    return wWriteRequest.id;
	endmethod

	method ActionValue#(Bit#(busWidth)) writeData();
	    let d <- client.write.data();
	    wWriteData <= d;
	    return d.data;
	endmethod
	method Bit#(idWidth) writeWid();
	    return wWriteData.id;
	endmethod
	method Bit#(busWidthBytes) writeDataByteEnable();
	    return wWriteData.byteEnable;
	endmethod
	method Bit#(1) writeLastDataBeat(); // last data beat
	    return wWriteData.last;
	endmethod

	method Action writeResponse(Bit#(2) responseCode, Bit#(idWidth) id);
	    client.write.response(Axi3WriteResponse { code: responseCode, id: id});
	endmethod
    endinterface

    interface Axi3MasterRead read;
	method ActionValue#(Bit#(addrWidth)) readAddr();
	    let r <- client.read.address();
	    wReadRequest <= r;
	    return r.address;
	endmethod
	method Bit#(4) readBurstLen();
	    return wReadRequest.burstLen;
	endmethod
	method Bit#(3) readBurstWidth();
	    if (valueOf(busWidth) == 32)
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    else if (valueOf(busWidth) == 64)
		return 3'b011;
	    else
		return 3'b100;
	endmethod
	method Bit#(2) readBurstType();  // drive with 2'b01
	    return 2'b01;
	endmethod
	method Bit#(3) readBurstProt(); // drive with 3'b000
	    return 3'b000;
	endmethod
	method Bit#(4) readBurstCache(); // drive with 4'b0011
	    return 4'b0011;
	endmethod
	method Bit#(idWidth) readId();
	    return wReadRequest.id;
	endmethod
	method Action readData(Bit#(busWidth) data, Bit#(2) code, Bit#(1) last, Bit#(idWidth) id);
	    client.read.data(Axi3ReadResponse { data: data, code: code, last: last, id: id});
	endmethod
   endinterface
endmodule

module mkAxi3Master#(Axi3Client#(addrWidth, busWidth,busWidthBytes,idWidth) client)(Axi3Master#(addrWidth, busWidth,busWidthBytes,idWidth))
	 provisos(Div#(busWidth,8,busWidthBytes),Add#(1,a,busWidth),Add#(busWidth,b,65));

    FIFOF#(Axi3ReadRequest#(addrWidth, idWidth))                      fReadRequest <- mkSizedBRAMFIFOF(8);
    FIFOF#(Axi3WriteRequest#(addrWidth, idWidth))                     fWriteRequest <- mkSizedBRAMFIFOF(8);
    FIFOF#(Axi3WriteData#(busWidth,busWidthBytes,idWidth)) fWriteData <- mkSizedBRAMFIFOF(8);

    rule writAddrRule;
        let r <- client.write.address();
	fWriteRequest.enq(r);
    endrule

    rule writeDataRule;
        let d <- client.write.data();
	fWriteData.enq(d);
    endrule

    rule readAddrRule;
        let r <- client.read.address();
	fReadRequest.enq(r);
    endrule

    interface Axi3MasterWrite write;
	method ActionValue#(Bit#(addrWidth)) writeAddr();
	    fWriteRequest.deq;
	    return fWriteRequest.first.address;
	endmethod
	method Bit#(4) writeBurstLen();
	    return fWriteRequest.first.burstLen;
	endmethod
	method Bit#(3) writeBurstWidth();
	    if (valueOf(busWidth) == 32)
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    else if (valueOf(busWidth) == 64)
		return 3'b011;
	    else
		return 3'b100;
	endmethod
	method Bit#(2) writeBurstType();  // drive with 2'b01 increment address
	    return 2'b01; // increment address
	endmethod
	method Bit#(3) writeBurstProt(); // drive with 3'b000
	    return 3'b000;
	endmethod
	method Bit#(4) writeBurstCache(); // drive with 4'b0011
	    return 4'b0011;
	endmethod
	method Bit#(idWidth) writeId();
	    return fWriteRequest.first.id;
	endmethod

	method ActionValue#(Bit#(busWidth)) writeData();
	    fWriteData.deq;
	    return fWriteData.first.data;
	endmethod
        method Bit#(idWidth) writeWid();
            return fWriteData.first.id;
        endmethod
	method Bit#(busWidthBytes) writeDataByteEnable();
	    return fWriteData.first.byteEnable;
	endmethod
	method Bit#(1) writeLastDataBeat(); // last data beat
	    return fWriteData.first.last;
	endmethod

	method Action writeResponse(Bit#(2) responseCode, Bit#(idWidth) id);
	    client.write.response(Axi3WriteResponse { code: responseCode, id: id});
	endmethod
    endinterface

    interface Axi3MasterRead read;
	method ActionValue#(Bit#(addrWidth)) readAddr();
	    fReadRequest.deq;
	    return fReadRequest.first.address;
	endmethod
	method Bit#(4) readBurstLen();
	    return fReadRequest.first.burstLen;
	endmethod
	method Bit#(3) readBurstWidth();
	    if (valueOf(busWidth) == 32)
		return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
	    else if (valueOf(busWidth) == 64)
		return 3'b011;
	    else
		return 3'b100;
	endmethod
	method Bit#(2) readBurstType();  // drive with 2'b01
	    return 2'b01;
	endmethod
	method Bit#(3) readBurstProt(); // drive with 3'b000
	    return 3'b000;
	endmethod
	method Bit#(4) readBurstCache(); // drive with 4'b0011
	    return 4'b0011;
	endmethod
	method Bit#(idWidth) readId();
	    return fReadRequest.first.id;
	endmethod
	method Action readData(Bit#(busWidth) data, Bit#(2) code, Bit#(1) last, Bit#(idWidth) id);
	    client.read.data(Axi3ReadResponse { data: data, code: code, last: last, id: id});
	endmethod
   endinterface
endmodule

instance Connectable#(Axi3Master#(addrWidth, busWidth,busWidthBytes,12), Axi3Slave#(addrWidth, busWidth,busWidthBytes));
    module mkConnection#(Axi3Master#(addrWidth, busWidth,busWidthBytes,12) m, Axi3Slave#(addrWidth, busWidth,busWidthBytes) s)(Empty);
	Reg#(Bit#(8)) writeBurstCountReg <- mkReg(0);
	Bool verbose = True;

	rule connectionReadAddr;
	    Bit#(addrWidth) addr <-m.read.readAddr;
	    let burstLen = m.read.readBurstLen;
	    let burstWidth = m.read.readBurstWidth;
	    let burstType = m.read.readBurstType;
	    let burstProt = m.read.readBurstProt;
	    let burstCache = m.read.readBurstCache;
	    let arid = m.read.readId;
	    s.read.readAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache, arid);
	    if (verbose) $display("        MasterSlaveConnection.readAddr %h %d", addr, burstLen+1);
	endrule
	rule connectionReadData;
	    let data <- s.read.readData();
	    let last = s.read.last();
	    let rid = s.read.rid();
	    m.read.readData(data, 2'b00, last, rid);
	endrule
	rule connectionWriteAddr;
	    Bit#(addrWidth) addr <- m.write.writeAddr;
	    let burstLen = m.write.writeBurstLen;
	    let burstWidth = m.write.writeBurstWidth;
	    let burstType = m.write.writeBurstType;
	    let burstProt = m.write.writeBurstProt;
	    let burstCache = m.write.writeBurstCache;
	    let awid = m.write.writeId;
	    s.write.writeAddr(addr, burstLen, burstWidth, burstType, burstProt, burstCache, awid);
	endrule
	rule connectionWriteData;
	    let data <- m.write.writeData;
	    let id = m.write.writeWid;
	    let byteEnable = m.write.writeDataByteEnable;
	    let last = m.write.writeLastDataBeat;
	    s.write.writeData(data, byteEnable, last);
	endrule
	rule connectionWriteResponse;
	    let response <- s.write.writeResponse();
	    m.write.writeResponse(response, 0);
	endrule
    endmodule: mkConnection
endinstance
