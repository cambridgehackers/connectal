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

import FIFO::*;
import GetPut::*;
import Connectable::*;
import RegFile::*;

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Master
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

function Bit#(3) axiBusSize(Integer busWidth);
   if (busWidth == 32)
      return 3'b010; // 3'b010: 32bit, 3'b011: 64bit, 3'b100: 128bit
   else if (busWidth == 64)
      return 3'b011;
   else if (busWidth == 128)
      return 3'b100;
   else
      return 3'b011;
endfunction

typedef struct {
   Bit#(busWidth) data;
   Bit#(2) resp;
   Bit#(1) last;
   Bit#(idWidth) id;
} Axi3ReadResponse#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
   Bit#(addrWidth) address;
   Bit#(4) len;
   Bit#(3) size; // assume matches bus width of Axi3Master
   Bit#(2) burst;  // drive with 2'b01
   Bit#(3) prot; // drive with 3'b000
   Bit#(4) cache; // drive with 4'b0011
   Bit#(idWidth) id;
   Bit#(2) lock;
   Bit#(4) qos;
} Axi3WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(TDiv#(busWidth,8)) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi3WriteData#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi3WriteResponse#(type idWidth) deriving (Bits);

interface Axi3Master#(type addrWidth, type busWidth, type idWidth);
   interface Get#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Get#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface Put#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi3Slave#(type addrWidth, type busWidth, type idWidth);
   interface Put#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface Get#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

function Put#(t) null_put();
   return (interface Put;
	      method Action put(t x) if (False);
		 noAction;
	      endmethod
	   endinterface);
endfunction

function Get#(t) null_get();
   return (interface Get;
	      method ActionValue#(t) get() if (False);
		 return ?;
	      endmethod
	   endinterface);
endfunction
      
function  Axi3Master#(addrWidth, busWidth, idWidth) null_axi_master();
   return (interface Axi3Master;
	      interface Get req_ar = null_get;
	      interface Put resp_read = null_put;
	      interface Get req_aw = null_get;
	      interface Get resp_write = null_get;
	      interface Put resp_b = null_put;
	   endinterface);
endfunction

interface RegFileA#(type index_t, type data_t);
   method Action upd(index_t addr, data_t d);
   method ActionValue#(data_t) sub(index_t addr);
endinterface

module mkAxi3SlaveFromRegFile#(RegFileA#(Bit#(regFileBusWidth), Bit#(busWidth)) rf)
   (Axi3Slave#(addrWidth, busWidth, idWidth))
   provisos(Add#(nz, regFileBusWidth, addrWidth));
   Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
   Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(idWidth)) readIdReg <- mkReg(0);
   Reg#(Bit#(4)) readBurstCountReg <- mkReg(0);
   Reg#(Bit#(4)) writeBurstCountReg <- mkReg(0);
   FIFO#(Bit#(2)) writeRespFifo <- mkFIFO();
   FIFO#(Bit#(idWidth)) writeIdFifo <- mkFIFO();

   Bool verbose = False;
   interface Put req_ar;
      method Action put(Axi3ReadRequest#(addrWidth,idWidth) req) if (readBurstCountReg == 0);
         if (verbose) $display("axiSlave.read.readAddr %h bc %d", req.address, req.len+1);
         readAddrReg <= truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
	 readIdReg <= req.id;
         readBurstCountReg <= req.len+1;
      endmethod
   endinterface: req_ar
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(busWidth,idWidth)) get() if (readBurstCountReg > 0);
         let data <- rf.sub(readAddrReg);
         if (verbose) $display("axiSlave.read.readData %h %h %d", readAddrReg, data, readBurstCountReg);
         readBurstCountReg <= readBurstCountReg - 1;
         readAddrReg <= readAddrReg + 1;
         return Axi3ReadResponse { data: data, last: (readBurstCountReg == 1) ? 1 : 0, id: readIdReg, resp: 0 };
      endmethod
   endinterface: resp_read
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(addrWidth,idWidth) req) if (writeBurstCountReg == 0);
         if (verbose) $display("axiSlave.write.writeAddr %h bc %d", req.address, req.len+1);
         writeAddrReg <= truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
         writeBurstCountReg <= req.len+1;
         writeIdFifo.enq(req.id);
      endmethod
   endinterface: req_aw
   interface Put resp_write;
      method Action put(Axi3WriteData#(busWidth,idWidth) resp) if (writeBurstCountReg > 0);
         if (verbose) $display("writeData %h %h %d", writeAddrReg, resp.data, writeBurstCountReg);
         rf.upd(writeAddrReg, resp.data);
         writeAddrReg <= writeAddrReg + 1;
         writeBurstCountReg <= writeBurstCountReg - 1;
         if (verbose) $display("axiSlave.write.writeData %h %h %d", writeAddrReg, resp.data, writeBurstCountReg);
         if (writeBurstCountReg == 1)
	    begin
               writeRespFifo.enq(0);
            end
      endmethod
   endinterface: resp_write
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(idWidth)) get();
         writeRespFifo.deq;
	 writeIdFifo.deq;
         return Axi3WriteResponse { resp: writeRespFifo.first, id: writeIdFifo.first };
      endmethod
   endinterface: resp_b
endmodule

module mkAxi3SlaveOutOfRange (Axi3Slave#(addrWidth, busWidth, idWidth));
   
   Reg#(Bit#(addrWidth)) readAddrReg <- mkReg(0);
   Reg#(Bit#(addrWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(idWidth)) readIdReg <- mkReg(0);
   Reg#(Bit#(4)) readBurstCountReg <- mkReg(0);
   Reg#(Bit#(4)) writeBurstCountReg <- mkReg(0);
   FIFO#(Bit#(2)) writeRespFifo <- mkFIFO();
   FIFO#(Bit#(idWidth)) writeIdFifo <- mkFIFO();

   interface Put req_ar;
      method Action put(Axi3ReadRequest#(addrWidth,idWidth) req) if (readBurstCountReg == 0);
         readAddrReg <= req.address/fromInteger(valueOf(TDiv#(busWidth,8)));
	 readIdReg <= req.id;
         readBurstCountReg <= req.len+1;
      endmethod
   endinterface: req_ar
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(busWidth,idWidth)) get() if (readBurstCountReg > 0);
         let data = 0;
         readBurstCountReg <= readBurstCountReg - 1;
         readAddrReg <= readAddrReg + 1;
         return Axi3ReadResponse { data: data, last: (readBurstCountReg == 1) ? 1 : 0, id: readIdReg, resp: 2'b11 };
      endmethod
   endinterface: resp_read
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(addrWidth,idWidth) req) if (writeBurstCountReg == 0);
         writeAddrReg <= req.address/fromInteger(valueOf(TDiv#(busWidth,8)));
         writeBurstCountReg <= req.len+1;
         writeIdFifo.enq(req.id);
      endmethod
   endinterface: req_aw
   interface Put resp_write;
      method Action put(Axi3WriteData#(busWidth,idWidth) resp) if (writeBurstCountReg > 0);
         writeAddrReg <= writeAddrReg + 1;
         writeBurstCountReg <= writeBurstCountReg - 1;
         if (writeBurstCountReg == 1)
	    begin
               writeRespFifo.enq(2'b11);
            end
      endmethod
   endinterface: resp_write
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(idWidth)) get();
         writeRespFifo.deq;
	 writeIdFifo.deq;
         return Axi3WriteResponse { resp: writeRespFifo.first, id: writeIdFifo.first };
      endmethod
   endinterface: resp_b
endmodule


typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) len;
    Bit#(3) size; // assume matches bus width of Axi4Master
    Bit#(2) burst;  // drive with 2'b01
    Bit#(3) prot; // drive with 3'b000
    Bit#(4) cache; // drive with 4'b0011
    Bit#(idWidth) id;
    Bit#(2) lock;
    Bit#(4) qos;
} Axi4ReadRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(2) resp;
    Bit#(1) last;
    Bit#(idWidth) id;
} Axi4ReadResponse#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(addrWidth) address;
    Bit#(8) len;
    Bit#(3) size; // assume matches bus width of Axi4Master
    Bit#(2) burst;  // drive with 2'b01
    Bit#(3) prot; // drive with 3'b000
    Bit#(4) cache; // drive with 4'b0011
    Bit#(idWidth) id;
    Bit#(2) lock;
    Bit#(4) qos;
} Axi4WriteRequest#(type addrWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(TDiv#(busWidth,8)) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi4WriteData#(type busWidth, type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi4WriteResponse#(type idWidth) deriving (Bits);

interface Axi4Master#(type addrWidth, type busWidth, type idWidth);
   interface Get#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;

   interface Get#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi4WriteData#(busWidth, idWidth)) resp_write;
   interface Put#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi4Slave#(type addrWidth, type busWidth, type idWidth);
   interface Put#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi4WriteData#(busWidth, idWidth)) resp_write;
   interface Get#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

module mkAxi4SlaveFromRegFile#(RegFile#(Bit#(regFileBusWidth), Bit#(busWidth)) rf)
   (Axi4Slave#(addrWidth, busWidth, idWidth))
   provisos(Add#(nz, regFileBusWidth, addrWidth));
   Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
   Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(idWidth)) readIdReg <- mkReg(0);
   Reg#(Bit#(4)) readBurstCountReg <- mkReg(0);
   Reg#(Bit#(4)) writeBurstCountReg <- mkReg(0);
   FIFO#(Bit#(2)) writeRespFifo <- mkFIFO();
   FIFO#(Bit#(idWidth)) writeIdFifo <- mkFIFO();

   Bool verbose = False;
   interface Put req_ar;
      method Action put(Axi4ReadRequest#(addrWidth,idWidth) req) if (readBurstCountReg == 0);
         if (verbose) $display("axiSlave.read.readAddr %h bc %d", req.address, req.len+1);
         readAddrReg <= truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
	 readIdReg <= req.id;
         readBurstCountReg <= truncate(req.len)+1;
      endmethod
   endinterface: req_ar
   interface Get resp_read;
      method ActionValue#(Axi4ReadResponse#(busWidth,idWidth)) get() if (readBurstCountReg > 0);
         let data = rf.sub(readAddrReg);
         if (verbose) $display("axiSlave.read.readData %h %h %d", readAddrReg, data, readBurstCountReg);
         readBurstCountReg <= readBurstCountReg - 1;
         readAddrReg <= readAddrReg + 1;
         return Axi4ReadResponse { data: data, last: (readBurstCountReg == 1) ? 1 : 0, id: readIdReg, resp: 0 };
      endmethod
   endinterface: resp_read
   interface Put req_aw;
      method Action put(Axi4WriteRequest#(addrWidth,idWidth) req) if (writeBurstCountReg == 0);
         if (verbose) $display("axiSlave.write.writeAddr %h bc %d", req.address, req.len+1);
         writeAddrReg <= truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
         writeBurstCountReg <= truncate(req.len)+1;
         writeIdFifo.enq(req.id);
      endmethod
   endinterface: req_aw
   interface Put resp_write;
      method Action put(Axi4WriteData#(busWidth,idWidth) resp) if (writeBurstCountReg > 0);
         if (verbose) $display("writeData %h %h %d", writeAddrReg, resp.data, writeBurstCountReg);
         rf.upd(writeAddrReg, resp.data);
         writeAddrReg <= writeAddrReg + 1;
         writeBurstCountReg <= writeBurstCountReg - 1;
         if (verbose) $display("axiSlave.write.writeData %h %h %d", writeAddrReg, resp.data, writeBurstCountReg);
         if (writeBurstCountReg == 1)
	    begin
               writeRespFifo.enq(0);
            end
      endmethod
   endinterface: resp_write
   interface Get resp_b;
      method ActionValue#(Axi4WriteResponse#(idWidth)) get();
         writeRespFifo.deq;
	 writeIdFifo.deq;
         return Axi4WriteResponse { resp: writeRespFifo.first, id: writeIdFifo.first };
      endmethod
   endinterface: resp_b
endmodule

instance Connectable#(Axi3Master#(addrWidth, busWidth,idWidth), Axi3Slave#(addrWidth, busWidth,idWidth));
   module mkConnection#(Axi3Master#(addrWidth, busWidth,idWidth) m, Axi3Slave#(addrWidth, busWidth,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance

instance Connectable#(Axi4Master#(addrWidth, busWidth,idWidth), Axi4Slave#(addrWidth, busWidth,idWidth));
   module mkConnection#(Axi4Master#(addrWidth, busWidth,idWidth) m, Axi4Slave#(addrWidth, busWidth,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance
