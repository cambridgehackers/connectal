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
import FIFOF::*;
import FIFO::*;
import GetPut::*;
import ConnectalMemTypes::*;
import AddressGenerator::*;
import BRAM::*;
import Memory::*;


module mkPhysMemSlaveFromBram#(BRAMServer#(Bit#(bramAddrWidth), Bit#(busDataWidth)) br) (PhysMemSlave#(busAddrWidth, busDataWidth))
   provisos(Add#(a__, bramAddrWidth, busAddrWidth));

   FIFOF#(Bit#(6))  readTagFifo <- mkFIFOF();
   FIFOF#(Bit#(6)) writeTagFifo <- mkFIFOF();
   FIFO#(Bool)     readLastFifo <- mkFIFO();
   AddressGenerator#(busAddrWidth,busDataWidth) readAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(busAddrWidth,busDataWidth) writeAddrGenerator <- mkAddressGenerator();
   let verbose = False;

    Reg#(Bit#(32)) cycles      <- mkReg(0);
    rule count;
       cycles <= cycles + 1;
    endrule

   rule read_req;
      let addrBeat <- readAddrGenerator.addrBeat.get();
      let addr = addrBeat.addr;
      let tag = addrBeat.tag;
      let burstCount = addrBeat.bc;
      readTagFifo.enq(tag);
      readLastFifo.enq(addrBeat.last);
      Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
      br.request.put(BRAMRequest{write:False, responseOnWrite:False, address:regFileAddr, datain:?});
      if (verbose) $display("%d read_server.readData (a) %h %d last=%d", cycles, addr, burstCount, addrBeat.last);
   endrule

   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(busAddrWidth, busDataWidth) req);
            if (verbose) $display("%d axiSlave.read.readAddr %h bc %d", cycles, req.addr, req.burstLen);
	    readAddrGenerator.request.put(req);
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(busDataWidth)) get();
   	    let tag = readTagFifo.first;
	    readTagFifo.deq;
	    readLastFifo.deq;
            let data <- br.response.get;
            if (verbose) $display("%d read_server.readData (b) %h", cycles, data);
            return MemData { data: data, tag: tag, last: readLastFifo.first };
	 endmethod
      endinterface
   endinterface
   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(busAddrWidth, busDataWidth) req);
	    writeAddrGenerator.request.put(req);
            if (verbose) $display("%d write_server.writeAddr %h bc %d", cycles, req.addr, req.burstLen);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(busDataWidth) resp);
	    let addrBeat <- writeAddrGenerator.addrBeat.get();
	    let addr = addrBeat.addr;
	    Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
            br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:regFileAddr, datain:resp.data});
            if (verbose) $display("%d write_server.writeData %h %h %d", cycles, addr, resp.data, addrBeat.bc);
            if (addrBeat.last)
               writeTagFifo.enq(addrBeat.tag);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(6)) get();
	    writeTagFifo.deq;
            return writeTagFifo.first;
	 endmethod
      endinterface
   endinterface
endmodule

module mkPhysMemSlaveFromBramBE#(BRAMServerBE#(Bit#(bramAddrWidth), Bit#(busDataWidth), dataWidthBytes) br) (PhysMemSlave#(busAddrWidth, busDataWidth))
   provisos(Add#(a__, bramAddrWidth, busAddrWidth)
           ,Mul#(dataWidthBytes, 8, busDataWidth)
           ,Div#(busDataWidth, 8, dataWidthBytes)
           );
   let verbose = False;

   FIFOF#(Bit#(6))  readTagFifo <- mkFIFOF();
   FIFOF#(Bit#(6)) writeTagFifo <- mkFIFOF();
   FIFO#(Bool)     readLastFifo <- mkFIFO();
   FIFOF#(Bit#(TDiv#(busDataWidth, 8))) readByteEnableFifo <- mkFIFOF;
   FIFOF#(Bit#(TDiv#(busDataWidth, 8))) writeByteEnableFifo <- mkFIFOF;

   AddressGenerator#(busAddrWidth,busDataWidth) readAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(busAddrWidth,busDataWidth) writeAddrGenerator <- mkAddressGenerator();

   FIFO#(PhysMemRequest#(busAddrWidth, busDataWidth)) req_ars <- mkFIFO1;
   FIFO#(Bit#(bramAddrWidth)) req_addr <- mkFIFO1;
   FIFO#(BRAMRequestBE#(Bit#(bramAddrWidth), Bit#(busDataWidth), dataWidthBytes)) req_aws <- mkFIFO1;

   Reg#(Bit#(32)) cycles      <- mkReg(0);
   rule count if (verbose);
      cycles <= cycles + 1;
   endrule

   rule req_ar;
     let req <- toGet(req_ars).get;
     readAddrGenerator.request.put(req);
   endrule

   rule read_req;
      let addrBeat <- readAddrGenerator.addrBeat.get();
      let addr = addrBeat.addr;
      let tag = addrBeat.tag;
      let burstCount = addrBeat.bc;
      readTagFifo.enq(tag);
      readLastFifo.enq(addrBeat.last);
      Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
      req_addr.enq(regFileAddr);
      if (verbose) $display("%d read_server.readData (a) %h %d last=%d", cycles, addr, burstCount, addrBeat.last);
   endrule

   rule read_bram_req;
      let addr <- toGet(req_addr).get;
      br.request.put(BRAMRequestBE{writeen:0, responseOnWrite:False, address:addr, datain:?});
   endrule

   rule req_aw;
      let req <- toGet(req_aws).get;
      br.request.put(req);
   endrule

   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(busAddrWidth, busDataWidth) req);
            if (verbose) $display("%d read_server.readAddr %h bc %d fbe %x lbe %x", cycles, req.addr, req.burstLen
`ifdef BYTE_ENABLES
               , req.firstbe, req.lastbe
`endif
               );
            req_ars.enq(req);
            readByteEnableFifo.enq(reqLastByteEnable(req));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(busDataWidth)) get();
   	    let tag = readTagFifo.first;
	    readTagFifo.deq;
	    readLastFifo.deq;
            let data <- br.response.get;
            let readBE = readByteEnableFifo.first;
            Bit#(dataWidthBytes) byteEnable = readLastFifo.first ? readBE : maxBound;
            let newdata = updateDataWithMask(0, data, byteEnable);
            if (verbose) $display("%d read_server.readData (b) %h, %h", cycles, data, newdata);
            if (readLastFifo.first) begin
               readByteEnableFifo.deq;
            end
            return MemData { data: newdata, tag: tag, last: readLastFifo.first };
	 endmethod
      endinterface
   endinterface
   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(busAddrWidth, busDataWidth) req);
	    writeAddrGenerator.request.put(req);
            writeByteEnableFifo.enq(reqLastByteEnable(req));
            if (verbose) $display("%d write_server.writeAddr %h bc %d fbe %x lbe %x", cycles, req.addr, req.burstLen
`ifdef BYTE_ENABLES
               , req.firstbe, req.lastbe
`endif
               );
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(busDataWidth) resp);
	    let addrBeat <- writeAddrGenerator.addrBeat.get();
	    let addr = addrBeat.addr;
	    Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
            let writeBE = writeByteEnableFifo.first;
            Bit#(dataWidthBytes) byteEnable = addrBeat.last ? writeBE : maxBound;
            req_aws.enq(BRAMRequestBE{writeen:byteEnable, responseOnWrite:False, address:regFileAddr, datain:resp.data});
            if (verbose) $display("%d write_server.writeData %h %h %d", cycles, addr, resp.data, addrBeat.bc);
            if (addrBeat.last)
               writeByteEnableFifo.deq;
               writeTagFifo.enq(addrBeat.tag);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(6)) get();
	    writeTagFifo.deq;
            return writeTagFifo.first;
	 endmethod
      endinterface
   endinterface
endmodule


module mkMemServerFromBram#(BRAMServer#(Bit#(bramAddrWidth), Bit#(busDataWidth)) br) (MemServer#(busDataWidth))
   provisos(Add#(a__, bramAddrWidth, MemOffsetSize));

   FIFOF#(Tuple2#(Bit#(6),Bool))  readTagFifo <- mkFIFOF();
   FIFOF#(Bit#(6)) writeTagFifo <- mkFIFOF();
   AddressGenerator#(bramAddrWidth,busDataWidth) readAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(bramAddrWidth,busDataWidth) writeAddrGenerator <- mkAddressGenerator();
   let verbose = False;

    Reg#(Bit#(32)) cycles      <- mkReg(0);
    rule count;
       cycles <= cycles + 1;
    endrule

   rule read_req;
      let addrBeat <- readAddrGenerator.addrBeat.get();
      let addr = addrBeat.addr;
      let tag = addrBeat.tag;
      let burstCount = addrBeat.bc;
      readTagFifo.enq(tuple2(tag, addrBeat.last));
      Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
      br.request.put(BRAMRequest{write:False, responseOnWrite:False, address:regFileAddr, datain:?});
      if (verbose) $display("%d read_server.readData (a) %h %d last=%d", cycles, addr, burstCount, addrBeat.last);
   endrule

   interface MemReadServer readServer;
      interface Put readReq;
	 method Action put(MemRequest req);
            if (verbose) $display("%d axiSlave.read.readAddr %h bc %d", cycles, req.offset, req.burstLen);
	    readAddrGenerator.request.put(PhysMemRequest { addr: truncate(req.offset), burstLen: req.burstLen, tag: req.tag });
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(busDataWidth)) get();
	    match { .tag, .last } = readTagFifo.first;
	    readTagFifo.deq;
            let data <- br.response.get;
            if (verbose) $display("%d read_server.readData (b) %h", cycles, data);
            return MemData { data: data, tag: tag, last: last };
	 endmethod
      endinterface
   endinterface
   interface MemWriteServer writeServer;
      interface Put writeReq;
	 method Action put(MemRequest req);
	    writeAddrGenerator.request.put(PhysMemRequest { addr: truncate(req.offset), burstLen: req.burstLen, tag: req.tag});
            if (verbose) $display("%d write_server.writeAddr %h bc %d", cycles, req.offset, req.burstLen);
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(busDataWidth) resp);
	    let addrBeat <- writeAddrGenerator.addrBeat.get();
	    let addr = addrBeat.addr;
	    Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(busDataWidth,8))));
            br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:regFileAddr, datain:resp.data});
            if (verbose) $display("%d write_server.writeData %h %h %d", cycles, addr, resp.data, addrBeat.bc);
            if (addrBeat.last)
               writeTagFifo.enq(addrBeat.tag);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(6)) get();
	    writeTagFifo.deq;
            return writeTagFifo.first;
	 endmethod
      endinterface
   endinterface
endmodule
