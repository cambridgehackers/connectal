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

import Vector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;

import MemTypes::*;

interface Pareff#(numeric type dataWidth);
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
   method ActionValue#(Bit#(dataWidth)) read(Bit#(32) handle, Bit#(32) addr);
endinterface

`ifdef BSIM
import "BDPI" function ActionValue#(Bit#(32)) pareff_init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
import "BDPI" function ActionValue#(Bit#(32)) pareff_initfd(Bit#(32) id, Bit#(32) fd);

// implemented in BsimDma.cpp
import "BDPI" function Action write_pareff32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_pareff64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_pareff32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff64(Bit#(32) handle, Bit#(32) addr);

module mkPareff(Pareff#(dataWidth) ifc)
   provisos (Mul#(TDiv#(dataWidth, 32), 32, dataWidth));
      method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
	 let v <- pareff_init(id, handle, size);
	 //return v;
      endmethod
      method Action initfd(Bit#(32) id, Bit#(32) fd);
	 let v <- pareff_initfd(id, fd);
	 //return v;
      endmethod
      method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
	  Vector#(TDiv#(dataWidth, 32), Bit#(32)) vs = unpack(v);
	  function Action write32(Integer i, Bit#(32) vv);
	     action
		write_pareff32(handle, addr+4*fromInteger(i), vv);
	     endaction
	  endfunction
	  mapM_(uncurry(write32), zip(genVector(), vs));
      endmethod
      method ActionValue#(Bit#(dataWidth)) read(Bit#(32) handle, Bit#(32) addr);
	  function ActionValue#(Bit#(32)) read32(Integer i);
	     actionvalue
		let v <- read_pareff32(handle, addr+4*fromInteger(i));
		return v;
	     endactionvalue
	  endfunction
   	  Vector#(TDiv#(dataWidth,32),Bit#(32)) vs <- mapM(read32, genVector());
	  return pack(vs);
      endmethod
endmodule
`endif
		 
`ifdef XSIM
interface XsimMemReadWrite;
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   method Action write32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
   method Action write64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
   method ActionValue#(Bit#(32)) read32(Bit#(32) handle, Bit#(32) addr);
   method ActionValue#(Bit#(64)) read64(Bit#(32) handle, Bit#(32) addr);
endinterface

import "BVI" XsimMemReadWrite =
module mkXsimReadWrite(XsimMemReadWrite);
   method init(init_id, init_handle, init_size) enable (en_init);
   method initfd(initfd_id, initfd_fd) enable (en_initfd);
   method write32(write32_handle, write32_addr, write32_data) enable (en_write32);
   method write64(write64_handle, write64_addr, write64_data) enable (en_write64);
   method read32_data read32(read32_handle, read32_addr) enable (en_read32);
   method read64_data read64(read64_handle, read64_addr) enable (en_read64);
   schedule (init, initfd, write32, write64, read32, read64) CF (init, initfd, write32, write64, read32, read64);
endmodule

module mkPareff(Pareff#(dataWidth) ifc)
   provisos (Mul#(TDiv#(dataWidth, 32), 32, dataWidth));
   Vector#(TDiv#(dataWidth,32),XsimMemReadWrite) rws <- replicateM(mkXsimReadWrite());
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
      rws[0].init(id, handle, size);
   endmethod
   method Action initfd(Bit#(32) id, Bit#(32) fd);
      rws[0].initfd(id, fd);
   endmethod
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
      Vector#(TDiv#(dataWidth, 32), Bit#(32)) vs = unpack(v);
      function Action write32(Integer i, Bit#(32) vv);
	 action
$display("read32: [%2d:%2d:%2d] = %x", handle, addr, fromInteger(i), vv);
	    rws[i].write32(handle, addr+4*fromInteger(i), vv);
	 endaction
      endfunction
      mapM_(uncurry(write32), zip(genVector(), vs));
   endmethod
   method ActionValue#(Bit#(dataWidth)) read(Bit#(32) handle, Bit#(32) addr);
      function ActionValue#(Bit#(32)) read32(Integer i);
	 actionvalue
	    let v <- rws[i].read32(handle, addr+4*fromInteger(i));
	    return v;
	 endactionvalue
      endfunction
      Vector#(TDiv#(dataWidth,32),Bit#(32)) vs <- mapM(read32, genVector());
$display("read32: [%2d:%2d] = %x", handle, addr, vs[0]);
      return pack(vs);
   endmethod
endmodule
`endif

`ifndef BSIM
`ifndef XSIM
module mkPareff(Pareff#(dataWidth) ifc);
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   endmethod
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   endmethod
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
   endmethod
   method ActionValue#(Bit#(dataWidth)) read(Bit#(32) handle, Bit#(32) addr);
      return 0;
   endmethod
endmodule
`endif
`endif

module mkPareffDmaMaster(PhysMemSlave#(serverAddrWidth,serverBusWidth))
   provisos(Div#(serverBusWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,serverBusWidth),
	    Log#(dataWidthBytes,beatShift),
	    Mul#(TDiv#(serverBusWidth, 32), 32, serverBusWidth)
	    );

   let verbose = False;
   Pareff#(serverBusWidth) rw <- mkPareff();

   Reg#(Bit#(serverAddrWidth)) readAddrr <- mkReg(0);
   Reg#(Bit#(BurstLenSize))  readLen <- mkReg(0);
   Reg#(Bit#(MemTagSize)) readId <- mkReg(0);
   Reg#(Bit#(serverAddrWidth)) writeAddrr <- mkReg(0);
   Reg#(Bit#(BurstLenSize))  writeLen <- mkReg(0);
   Reg#(Bit#(MemTagSize)) writeId <- mkReg(0);

   let readLatency_I = 150;
   let writeLatency_I = 150;

   Bit#(64) readLatency = fromInteger(readLatency_I);
   Bit#(64) writeLatency = fromInteger(writeLatency_I);

   Reg#(Bit#(64)) req_ar_b_ts <- mkReg(0);
   Reg#(Bit#(64)) req_aw_b_ts <- mkReg(0);
   Reg#(Bit#(64)) cycles <- mkReg(0);
   Reg#(Bit#(64)) last_reqAr <- mkReg(0);
   Reg#(Bit#(64)) last_read_eob <- mkReg(0);
   Reg#(Bit#(64)) last_write_eob <- mkReg(0);

   FIFOF#(Tuple2#(Bit#(64), PhysMemRequest#(serverAddrWidth)))  readDelayFifo <- mkSizedFIFOF(readLatency_I);
   FIFOF#(Tuple2#(Bit#(64),PhysMemRequest#(serverAddrWidth))) writeDelayFifo <- mkSizedFIFOF(writeLatency_I);

   FIFOF#(Tuple2#(Bit#(64), Bit#(MemTagSize))) bFifo <- mkSizedFIFOF(writeLatency_I);

   rule increment_cycle;
      cycles <= cycles+1;
   endrule

   let read_jitter = True; //cycles[4:0] == 0;
   let write_jitter = True; //cycles[4:0] == 5;

   Reg#(Bit#(8))  burstReg <- mkReg(0);
   FIFO#(Bit#(8)) reqs <- mkSizedFIFO(32);
   
   let beat_shift = fromInteger(valueOf(beatShift));

   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(serverAddrWidth) req);
            if (verbose) $display("%d axiSlave.read.readAddr %h bc %d", cycles, req.addr, req.burstLen);
	    //readAddrGenerator.request.put(req);
	    readDelayFifo.enq(tuple2(cycles,req));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(serverBusWidth)) get() if (((readLen > 0) || (readLen == 0 && (cycles-tpl_1(readDelayFifo.first)) > readLatency)) && read_jitter);
	 Bit#(BurstLenSize) read_len = ?;
	 Bit#(serverAddrWidth) read_addr = ?;
	 Bit#(MemTagSize) read_id = ?;
	 Bit#(8) handle = ?;
	 if (readLen == 0 && (cycles-tpl_1(readDelayFifo.first)) > readLatency) begin
	    req_ar_b_ts <= cycles;
	    let req = tpl_2(readDelayFifo.first);
	    readDelayFifo.deq;
	    read_len = req.burstLen>>beat_shift;
	    read_addr = req.addr;
	    read_id = req.tag;
	    handle = req.addr[39:32];
	    //if(id==1) $display("mkBsimHost::resp_read_a: %d %d %d", req.tag,  cycles-last_read_eob, (req.burstLen>>beat_shift)-1);
	    //last_read_eob <= cycles;
	 end 
	 else begin
	    //$display("mkBsimHost::resp_read_b: %d %d", readId,  cycles-last_read_eob);
	    //last_read_eob <= cycles;
	    handle = readAddrr[39:32];
	    read_addr = readAddrr;
	    read_id = readId;
	    read_len = readLen;
	 end
	 Bit#(serverBusWidth) v <- rw.read(extend(handle), read_addr[31:0]);
	 readLen <= read_len - 1;
	 readId <= read_id;
	 readAddrr <= read_addr + fromInteger(valueOf(serverBusWidth)/8);
	 //$display("mkBsimHost::resp_read id=%d %d", read_id, read_len);
	 //return Axi3ReadResponse { data: v, resp: 0, last: pack(readLen == 1), id: read_id};
            //if (verbose) $display("%d read_server.readData (b) %h", cycles, data);
            return MemData { data: v, tag: read_id, last: readLen == 1};
	 endmethod
      endinterface
   endinterface
   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(serverAddrWidth) req);
	 //$display("mkBsimHost::req_aw id=%d", req.tag);
	 writeDelayFifo.enq(tuple2(cycles,req));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(serverBusWidth) resp) if (((writeLen > 0) || (writeLen == 0 && (cycles-tpl_1(writeDelayFifo.first)) > writeLatency)) && write_jitter);
	    //let addrBeat <- writeAddrGenerator.addrBeat.get();
	    //let addr = addrBeat.addr;
	    //Bit#(bramAddrWidth) regFileAddr = truncate(addr/fromInteger(valueOf(TDiv#(serverBusWidth,8))));
            //br.request.put(BRAMRequest{write:True, responseOnWrite:False, address:regFileAddr, datain:resp.data});
	 Bit#(BurstLenSize) write_len = ?;
	 Bit#(serverAddrWidth) write_addr = ?;
	 Bit#(MemTagSize) write_id = ?;
	 Bit#(8) handle = ?;
	 if (writeLen == 0 && (cycles-tpl_1(writeDelayFifo.first)) > writeLatency) begin
	    req_aw_b_ts <= cycles;
	    let req = tpl_2(writeDelayFifo.first);
	    writeDelayFifo.deq;
	    write_addr = req.addr;
	    write_len = req.burstLen>>beat_shift;
	    write_id = req.tag;
	    handle = req.addr[39:32];
	    //$display("mkBsimHost::resp_write_a: %d %d", req.tag,  cycles-last_write_eob);
	    //last_write_eob <= cycles;
	 end
	 else begin
	    //$display("mkBsimHost::resp_write_b: %d %d", writeId,  cycles-last_write_eob);
	    //last_write_eob <= cycles;
	    handle = writeAddrr[39:32];
	    write_len = writeLen;
	    write_addr = writeAddrr;
	    write_id = writeId;
	 end
	 rw.write(extend(handle), write_addr[31:0], resp.data);
	 //$display("write_resp(%d): handle=%d addr=%h v=%h", cycles, handle, write_addr, resp.data);
	 writeId <= write_id;
	 writeLen <= write_len - 1;
	 writeAddrr <= write_addr + fromInteger(valueOf(serverBusWidth)/8);
	 if (write_len == 1) begin
	    bFifo.enq(tuple2(cycles,write_id));
	 end
            //if (verbose) $display("%d write_server.writeAddr %h bc %d", cycles, req.addr, req.burstLen);
            //if (verbose) $display("%d write_server.writeData %h %h %d", cycles, addr, resp.data, addrBeat.bc);
            //if (addrBeat.last)
               //writeTagFifo.enq(addrBeat.tag);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(MemTagSize)) get() if ((cycles-tpl_1(bFifo.first)) > writeLatency);
	 bFifo.deq();
	 return tpl_2(bFifo.first());
	 endmethod
      endinterface
   endinterface
endmodule
