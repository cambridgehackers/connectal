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

`ifdef SIM_DMA_READ_LATENCY
typedef `SIM_DMA_READ_LATENCY SimDmaReadLatency;
`else
typedef 150 SimDmaReadLatency;
`endif
`ifdef SIM_DMA_WRITE_LATENCY
typedef `SIM_DMA_WRITE_LATENCY SimDmaWriteLatency;
`else
typedef 150 SimDmaWriteLatency;
`endif

interface SimDma#(numeric type dataWidth);
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   method Action idreturn(Bit#(32) id);
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
   method Action readrequest(Bit#(32) handle, Bit#(32) addr);
   method ActionValue#(Bit#(dataWidth)) readresponse();
endinterface

`ifdef BSIM
import "BDPI" function ActionValue#(Bit#(32)) simDma_init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
import "BDPI" function ActionValue#(Bit#(32)) simDma_initfd(Bit#(32) id, Bit#(32) fd);
import "BDPI" function ActionValue#(Bit#(32)) simDma_idreturn(Bit#(32) id);

// implemented in BsimDma.cpp
import "BDPI" function Action write_simDma32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_simDma64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_simDma32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_simDma64(Bit#(32) handle, Bit#(32) addr);

module mkSimDma(SimDma#(dataWidth) ifc)
   provisos (Mul#(TDiv#(dataWidth, 32), 32, dataWidth));
   FIFO#(Bit#(dataWidth)) dataFifo <- mkFIFO();
      method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
	 let v <- simDma_init(id, handle, size);
	 //return v;
      endmethod
      method Action initfd(Bit#(32) id, Bit#(32) fd);
	 let v <- simDma_initfd(id, fd);
	 //return v;
      endmethod
      method Action idreturn(Bit#(32) id);
	 let v <- simDma_idreturn(id);
	 //return v;
      endmethod
      method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
	  Vector#(TDiv#(dataWidth, 32), Bit#(32)) vs = unpack(v);
	  function Action write32(Integer i, Bit#(32) vv);
	     action
		write_simDma32(handle, addr+4*fromInteger(i), vv);
	     endaction
	  endfunction
	  mapM_(uncurry(write32), zip(genVector(), vs));
      endmethod
      method Action  readrequest(Bit#(32) handle, Bit#(32) addr);
	  function ActionValue#(Bit#(32)) read32(Integer i);
	     actionvalue
		let v <- read_simDma32(handle, addr+4*fromInteger(i));
		return v;
	     endactionvalue
	  endfunction
   	  Vector#(TDiv#(dataWidth,32),Bit#(32)) vs <- mapM(read32, genVector());
	  dataFifo.enq(pack(vs));
      endmethod
      method ActionValue#(Bit#(dataWidth)) readresponse();
          let v <- toGet(dataFifo).get();
	  return v;
      endmethod
endmodule
`endif
		 
`ifdef XSIM
interface XsimDmaReadWrite;
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   method Action idreturn(Bit#(32) id);
   method Action write32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
   method Action readrequest(Bit#(32) handle, Bit#(32) addr);
   method ActionValue#(Bit#(32)) readresponse();
endinterface

import "BVI" XsimDmaReadWrite =
module mkXsimReadWrite(XsimDmaReadWrite);
   method init(init_id, init_handle, init_size) enable (en_init);
   method initfd(initfd_id, initfd_fd) enable (en_initfd);
   method idreturn(idreturn_id) enable (en_idreturn);
   method write32(write32_handle, write32_addr, write32_data) enable (en_write32);
   method readrequest(readrequest_handle, readrequest_addr) enable (en_readrequest) ready (rdy_readrequest);
   method readresponse_data readresponse() enable (en_readresponse) ready (rdy_readresponse);
   schedule (init, initfd, write32, readrequest, readresponse) CF (init, initfd, write32, readrequest, readresponse);
endmodule

module mkSimDma(SimDma#(dataWidth) ifc)
   provisos (Mul#(TDiv#(dataWidth, 32), 32, dataWidth));
   Vector#(TDiv#(dataWidth,32),XsimDmaReadWrite) rws <- replicateM(mkXsimReadWrite());
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
      rws[0].init(id, handle, size);
   endmethod
   method Action initfd(Bit#(32) id, Bit#(32) fd);
      rws[0].initfd(id, fd);
   endmethod
   method Action idreturn(Bit#(32) id);
      rws[0].idreturn(id);
   endmethod
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
      Vector#(TDiv#(dataWidth, 32), Bit#(32)) vs = unpack(v);
      function Action write32(Integer i, Bit#(32) vv);
	 action
	    rws[i].write32(handle, addr+4*fromInteger(i), vv);
	 endaction
      endfunction
      mapM_(uncurry(write32), zip(genVector(), vs));
   endmethod
   method Action readrequest(Bit#(32) handle, Bit#(32) addr);
      function Action doreadrequest(Integer i);
	 action
	    rws[i].readrequest(handle, addr+4*fromInteger(i));
	 endaction
      endfunction
      Vector#(TDiv#(dataWidth,32),Integer) indexes = genVector();
      mapM_(doreadrequest, indexes);
   endmethod
   method ActionValue#(Bit#(dataWidth)) readresponse();
      function ActionValue#(Bit#(32)) readresponse32(Integer i);
	 actionvalue
	    let v <- rws[i].readresponse();
	    return v;
	 endactionvalue
      endfunction
      Vector#(TDiv#(dataWidth,32),Bit#(32)) vs <- mapM(readresponse32, genVector());
      return pack(vs);
   endmethod
endmodule
`endif

`ifndef BSIM
`ifndef XSIM
module mkSimDma(SimDma#(dataWidth) ifc);
   method Action init(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
   endmethod
   method Action initfd(Bit#(32) id, Bit#(32) fd);
   endmethod
   method Action idreturn(Bit#(32) id);
   endmethod
   method Action write(Bit#(32) handle, Bit#(32) addr, Bit#(dataWidth) v);
   endmethod
   method Action readrequest(Bit#(32) handle, Bit#(32) addr);
   endmethod
   method ActionValue#(Bit#(dataWidth)) readresponse();
      return 0;
   endmethod
endmodule
`endif
`endif

module mkSimDmaDmaMaster(PhysMemSlave#(serverAddrWidth,serverBusWidth))
   provisos(Div#(serverBusWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,serverBusWidth),
	    Log#(dataWidthBytes,beatShift),
	    Mul#(TDiv#(serverBusWidth, 32), 32, serverBusWidth),
	    Bits#(Tuple2#(Bit#(64), PhysMemRequest#(serverAddrWidth)), a__)
	    );

   let verbose = False;
   SimDma#(serverBusWidth) rw <- mkSimDma();

   Reg#(Bit#(BurstLenSize))  readLenReg <- mkReg(0);
   Reg#(Bit#(32))         readOffsetReg <- mkReg(0);

   Reg#(Bit#(BurstLenSize))  writeLenReg <- mkReg(0);
   Reg#(Bit#(32))         writeOffsetReg <- mkReg(0);

   let readLatency_I = valueOf(SimDmaReadLatency);
   let writeLatency_I = valueOf(SimDmaWriteLatency);

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
   FIFOF#(Tuple2#(Bit#(MemTagSize),Bool)) taglastfifo <- mkFIFOF();
   rule increment_cycle;
      cycles <= cycles+1;
   endrule

   let read_jitter = True; //cycles[4:0] == 0;
   let write_jitter = True; //cycles[4:0] == 5;

   Reg#(Bit#(8))  burstReg <- mkReg(0);
   FIFO#(Bit#(8)) reqs <- mkSizedFIFO(32);
   
   let beat_shift = fromInteger(valueOf(beatShift));

   rule read_rule if (readDelayFifo.notEmpty() && (cycles-tpl_1(readDelayFifo.first) > readLatency));
	 match { .reqTime, .req } = readDelayFifo.first;
	 Bit#(BurstLenSize) readLen = readLenReg;
	 Bit#(32) readOffset = readOffsetReg;
	 Bit#(MemTagSize) tag = req.tag;
	 Bit#(8) handle = req.addr[39:32];

	 if (readLen == 0) begin
	    req_ar_b_ts <= cycles;
	    readLen     = req.burstLen>>beat_shift;
	    readOffset  = 0;
	 end
	 rw.readrequest(extend(handle), req.addr[31:0]+readOffset);
	 let last = (readLen == 1);
	 if (last)
	    readDelayFifo.deq();
	 taglastfifo.enq(tuple2(tag, last));
	 readLenReg <= readLen - 1;
	 readOffsetReg <= readOffset + fromInteger(valueOf(serverBusWidth)/8);
   endrule

   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(serverAddrWidth) req);
            if (verbose) $display("%d axiSlave.read.readAddr %h bc %d", cycles, req.addr, req.burstLen);
	    //readAddrGenerator.request.put(req);
	    readDelayFifo.enq(tuple2(cycles,req));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(serverBusWidth)) get();
	     match { .tag, .last } <- toGet(taglastfifo).get();
 	     let v <- rw.readresponse();
	     return MemData { data: v, tag: tag, last: last };
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
	 method Action put(MemData#(serverBusWidth) resp) if (writeDelayFifo.notEmpty && (cycles-tpl_1(writeDelayFifo.first)) > writeLatency);
	    match { .reqTime, .req } = writeDelayFifo.first;
	    Bit#(BurstLenSize) writeLen = writeLenReg;
	    Bit#(32) writeOffset = writeOffsetReg;
	    Bit#(MemTagSize) tag = req.tag;
	    Bit#(8) handle = req.addr[39:32];
	    if (writeLenReg == 0) begin
	       req_aw_b_ts <= cycles;
	       writeLen = req.burstLen>>beat_shift;
	       writeOffset = 0;
	    end
	    rw.write(extend(handle), req.addr[31:0] + writeOffset, resp.data);
	    writeLenReg <= writeLen - 1;
	    writeOffsetReg <= writeOffset + fromInteger(valueOf(serverBusWidth)/8);
	    if (writeLen == 1) begin
	       bFifo.enq(tuple2(cycles,tag));
	       writeDelayFifo.deq;
	    end
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
