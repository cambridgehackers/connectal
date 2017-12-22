// Copyright (c) 2013 Quanta Research Cambridge, Inc.
// Copyright (c) 2015 Connectal Project

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
import ConnectalMemTypes::*; // null_get, null_put

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
} Axi4ReadRequest#(numeric type addrWidth, numeric type idWidth) deriving (Bits);

function Bit#(3) axiBusSize(busWidthType busWidth) provisos (Eq#(busWidthType),Literal#(busWidthType));
   if (busWidth == 16)
      return 3'b001;
   else if (busWidth == 32)
      return 3'b010;
   else if (busWidth == 64)
      return 3'b011;
   else if (busWidth == 128)
      return 3'b100;
   else if (busWidth == 256)
      return 3'b101;
   else if (busWidth == 512)
      return 3'b110;
   else if (busWidth == 1024)
      return 3'b111;
   else
      return 3'b000;
endfunction

function Bit#(3) axiBusSizeBytes(busWidthType busWidth) provisos (Eq#(busWidthType),Literal#(busWidthType),Arith#(busWidthType));
   return axiBusSize(8*busWidth);
endfunction

typedef struct {
   Bit#(busWidth) data;
   Bit#(2) resp;
   Bit#(1) last;
   Bit#(idWidth) id;
} Axi4ReadResponse#(numeric type busWidth, numeric type idWidth) deriving (Bits);

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
} Axi4WriteRequest#(numeric type addrWidth, numeric type idWidth) deriving (Bits);

typedef struct {
    Bit#(busWidth) data;
    Bit#(TDiv#(busWidth,8)) byteEnable;
    Bit#(1)        last;
    Bit#(idWidth) id;
} Axi4WriteData#(numeric type busWidth, numeric type idWidth) deriving (Bits);

typedef struct {
    Bit#(2) resp;
    Bit#(idWidth) id;
} Axi4WriteResponse#(numeric type idWidth) deriving (Bits);

interface Axi4Master#(numeric type addrWidth, numeric type busWidth, numeric type idWidth);
   interface Get#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Put#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;
   interface Get#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Get#(Axi4WriteData#(busWidth, idWidth)) resp_write;
   interface Put#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

interface Axi4Slave#(numeric type addrWidth, numeric type busWidth, numeric type idWidth);
   interface Put#(Axi4ReadRequest#(addrWidth, idWidth)) req_ar;
   interface Get#(Axi4ReadResponse#(busWidth, idWidth)) resp_read;
   interface Put#(Axi4WriteRequest#(addrWidth, idWidth)) req_aw;
   interface Put#(Axi4WriteData#(busWidth, idWidth)) resp_write;
   interface Get#(Axi4WriteResponse#(idWidth)) resp_b;
endinterface

function  Axi4Master#(addrWidth, busWidth, idWidth) null_axi_master();
   return (interface Axi4Master;
	      interface Get req_ar = null_get;
	      interface Put resp_read = null_put;
	      interface Get req_aw = null_get;
	      interface Get resp_write = null_get;
	      interface Put resp_b = null_put;
	   endinterface);
endfunction

instance Connectable#(Axi4Master#(addrWidth, busWidth,idWidth), Axi4Slave#(addrWidth, busWidth,idWidth));
   module mkConnection#(Axi4Master#(addrWidth, busWidth,idWidth) m, Axi4Slave#(addrWidth, busWidth,idWidth) s)(Empty);

      mkConnection(m.req_ar, s.req_ar);
      mkConnection(s.resp_read, m.resp_read);

      mkConnection(m.req_aw, s.req_aw);
      mkConnection(m.resp_write, s.resp_write);
      mkConnection(s.resp_b, m.resp_b);

   endmodule
endinstance

function Axi4ReadRequest#(axiAddrWidth,idWidth) toAxi4ReadRequest(PhysMemRequest#(addrWidth,dataBusWidth) req)
   provisos (Add#(axiAddrWidth,a__,addrWidth)
	     ,Add#(b__, idWidth, MemTagSize));
   Axi4ReadRequest#(axiAddrWidth,idWidth) axireq  = unpack(0);
   axireq.address = truncate(req.addr);
   axireq.id   = truncate(req.tag);
   let dataWidthBytes = valueOf(TDiv#(dataBusWidth,8));
   let dataSizeMask = dataWidthBytes-1;
   let size = req.burstLen & fromInteger(dataSizeMask);
   let beats = (req.burstLen + fromInteger(dataWidthBytes-1)) / fromInteger(dataWidthBytes);
   axireq.len = truncate(beats-1);
   //axireq.size = (beats == 1) ? axiBusSizeBytes(size) : axiBusSizeBytes(dataWidthBytes);
   axireq.size = axiBusSizeBytes(dataWidthBytes);
   axireq.burst = 2'b01;
   axireq.cache = 4'b1111;
   return axireq;
endfunction
function Axi4WriteRequest#(axiAddrWidth,idWidth) toAxi4WriteRequest(PhysMemRequest#(addrWidth,dataBusWidth) req)
   provisos (Add#(axiAddrWidth,a__,addrWidth)
	     ,Add#(b__, idWidth, MemTagSize));
   Axi4WriteRequest#(axiAddrWidth,idWidth) axireq  = unpack(0);
   axireq.address = truncate(req.addr);
   axireq.id   = truncate(req.tag);
   let dataWidthBytes = valueOf(TDiv#(dataBusWidth,8));
   let dataSizeMask = dataWidthBytes-1;
   let size = req.burstLen & fromInteger(dataSizeMask);
   let beats = (req.burstLen + fromInteger(dataWidthBytes-1)) / fromInteger(dataWidthBytes);
   axireq.len = truncate(beats-1);
   //axireq.size = (beats == 1) ? axiBusSizeBytes(size) : axiBusSizeBytes(dataWidthBytes);
   axireq.size = axiBusSizeBytes(dataWidthBytes);
   axireq.burst = 2'b01;
   axireq.cache = 4'b1111;
   return axireq;
endfunction

instance MkPhysMemSlave#(Axi4Slave#(axiAddrWidth,dataWidth,idWidth),addrWidth,dataWidth)
      provisos (Add#(axiAddrWidth,a__,addrWidth),Add#(b__, idWidth, MemTagSize));
   module mkPhysMemSlave#(Axi4Slave#(axiAddrWidth,dataWidth,idWidth) axiSlave)(PhysMemSlave#(addrWidth,dataWidth));
      FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) arfifo <- mkFIFOF();
      FIFOF#(MemData#(dataWidth)) rfifo <- mkFIFOF();
      FIFOF#(PhysMemRequest#(addrWidth,dataWidth)) awfifo <- mkFIFOF();
      FIFOF#(MemData#(dataWidth)) wfifo <- mkFIFOF();
      FIFOF#(Bit#(MemTagSize)) bfifo <- mkFIFOF();
      FIFOF#(Bit#(MemTagSize)) rtagfifo <- mkFIFOF();
      FIFOF#(Bit#(MemTagSize)) wtagfifo <- mkFIFOF();

      rule rl_arfifo;
	 let req <- toGet(arfifo).get();
	 Axi4ReadRequest#(axiAddrWidth,idWidth) axireq = toAxi4ReadRequest(req);
	 axiSlave.req_ar.put(axireq);
      endrule
      rule rl_rdata;
	 let rdata <- axiSlave.resp_read.get();
	 rfifo.enq(MemData { data: rdata.data, tag: extend(rdata.id) } );
      endrule

      rule rl_awfifo;
	 let req <- toGet(awfifo).get();
	 Axi4WriteRequest#(axiAddrWidth,idWidth) axireq = toAxi4WriteRequest(req);
	 axiSlave.req_aw.put(axireq);
      endrule
      rule rl_wdata;
	 let md <- toGet(wfifo).get();
	 //FIXME byteEnable
	 axiSlave.resp_write.put(Axi4WriteData {data: md.data, byteEnable:maxBound, last:pack(md.last), id:truncate(md.tag)});
      endrule
      rule rl_done;
	 let b <- axiSlave.resp_b.get();
	 bfifo.enq(extend(b.id));
      endrule

      interface PhysMemReadServer read_server;
	 interface Put readReq = toPut(arfifo);
	 interface Get readData = toGet(rfifo);
      endinterface
      interface PhysMemWriteServer write_server;
	 interface Put writeReq = toPut(awfifo);
	 interface Put writeData = toPut(wfifo);
	 interface Get writeDone = toGet(bfifo);
      endinterface
   endmodule
endinstance
