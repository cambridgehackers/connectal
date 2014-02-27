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

import FIFOF::*;
import FIFO::*;
import GetPut::*;
import Connectable::*;
import RegFile::*;
import GetPutF::*;

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

function GetF#(Axi3ReadResponse#(_b,_c)) get_resp_read(Axi3Slave#(_a,_b,_c) x);
   return x.resp_read;
endfunction

function GetF#(Axi3WriteResponse#(_c)) get_resp_b(Axi3Slave#(_a,_b,_c) x);
   return x.resp_b;
endfunction

interface Axi3Master#(type addrWidth, type busWidth, type idWidth);
   interface Get#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Get#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface Put#(Axi3WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi3Slave#(type addrWidth, type busWidth, type idWidth);
   interface Put#(Axi3ReadRequest#(addrWidth, idWidth)) req_ar;
   interface GetF#(Axi3ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi3WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi3WriteData#(busWidth, idWidth)) resp_write;
   interface GetF#(Axi3WriteResponse#(idWidth)) resp_b;
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

module mkRegFileANull#(data_t defv) (RegFileA#(index_t,data_t));
   method Action upd(index_t addr, data_t d);
      noAction;
   endmethod
   method ActionValue#(data_t) sub(index_t addr);
      return defv;
   endmethod
endmodule

module mkAxi3SlaveOutOfRange (Axi3Slave#(addrWidth, busWidth, idWidth));
   RegFileA#(Bit#(addrWidth), Bit#(busWidth)) rf <- mkRegFileANull(0);
   let rv <- mkAxi3SlaveFromRegFile(rf);
   return rv;
endmodule

module mkAxi3SlaveFromRegFile#(RegFileA#(Bit#(regFileBusWidth), Bit#(busWidth)) rf) (Axi3Slave#(addrWidth, busWidth, idWidth))
   provisos(Add#(nz, regFileBusWidth, addrWidth));

   Reg#(Bit#(regFileBusWidth)) readAddrReg <- mkReg(0);
   Reg#(Bit#(regFileBusWidth)) writeAddrReg <- mkReg(0);
   Reg#(Bit#(idWidth)) readIdReg <- mkReg(0);
   Reg#(Bit#(4)) readBurstCountReg <- mkReg(0);
   Reg#(Bit#(4)) writeBurstCountReg <- mkReg(0);
   FIFOF#(Bit#(2)) writeRespFifo <- mkFIFOF();
   FIFOF#(Bit#(idWidth)) writeIdFifo <- mkFIFOF();
   FIFOF#(Axi3ReadRequest#(addrWidth,idWidth)) req_ar_fifo <- mkSizedFIFOF(1);
   FIFO#(Axi3WriteRequest#(addrWidth,idWidth)) req_aw_fifo <- mkSizedFIFO(1);
   
   Bool verbose = False;
   interface Put req_ar;
      method Action put(Axi3ReadRequest#(addrWidth,idWidth) req);
         if (verbose) $display("axiSlave.read.readAddr %h bc %d", req.address, req.len+1);
   	 req_ar_fifo.enq(req);
      endmethod
   endinterface: req_ar
   interface GetF resp_read;
      method ActionValue#(Axi3ReadResponse#(busWidth,idWidth)) get();
   	 let addr = readAddrReg;
   	 let id = readIdReg;
   	 let burstCount = readBurstCountReg;
   	 if (readBurstCountReg == 0) begin
	    let req = req_ar_fifo.first;
            addr = truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
   	    id = req.id;
            burstCount = req.len+1;
   	    req_ar_fifo.deq;
   	 end
         let data <- rf.sub(addr);
         if (verbose) $display("axiSlave.read.readData %h %h %d", addr, data, burstCount);
         readBurstCountReg <= burstCount - 1;
         readAddrReg <= addr + 1;
   	 readIdReg <= id;
         return Axi3ReadResponse { data: data, last: (burstCount == 1) ? 1 : 0, id: id, resp: 0 };
      endmethod
      method Bool notEmpty();
	 return (readBurstCountReg==0) ? req_ar_fifo.notEmpty : True;
      endmethod
   endinterface: resp_read
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(addrWidth,idWidth) req);
         req_aw_fifo.enq(req);
         if (verbose) $display("axiSlave.write.writeAddr %h bc %d", req.address, req.len+1);
      endmethod
   endinterface: req_aw
   interface Put resp_write;
      method Action put(Axi3WriteData#(busWidth,idWidth) resp);
	 let addr = writeAddrReg;
         let burstCount = writeBurstCountReg;
         if (burstCount == 0) begin
	    let req = req_aw_fifo.first;
            addr = truncate(req.address/fromInteger(valueOf(TDiv#(busWidth,8))));
            burstCount = req.len+1;
            writeIdFifo.enq(req.id);
	    req_aw_fifo.deq;
	 end
         if (verbose) $display("writeData %h %h %d", addr, resp.data, burstCount);
         rf.upd(addr, resp.data);
         writeAddrReg <= addr + 1;
         writeBurstCountReg <= burstCount - 1;
         if (verbose) $display("axiSlave.write.writeData %h %h %d", addr, resp.data, burstCount);
         if (burstCount == 1)
               writeRespFifo.enq(0);
      endmethod
   endinterface: resp_write
   interface GetF resp_b;
      method ActionValue#(Axi3WriteResponse#(idWidth)) get();
         writeRespFifo.deq;
	 writeIdFifo.deq;
         return Axi3WriteResponse { resp: writeRespFifo.first, id: writeIdFifo.first };
      endmethod
      method Bool notEmpty();
	 return (writeRespFifo.notEmpty() && writeIdFifo.notEmpty());
      endmethod
   endinterface: resp_b
endmodule
