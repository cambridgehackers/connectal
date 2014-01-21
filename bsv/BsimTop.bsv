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

import Vector            :: *;
import FIFO              :: *;
import SpecialFIFOs      :: *;
import GetPut            :: *;
import Connectable       :: *;
import StmtFSM           :: *;
import Portal            :: *;
import AxiClientServer   :: *;
import Leds              :: *;
import Top               :: *;

import "BDPI" function Action      initPortal(Bit#(32) d);
import "BDPI" function Bool                    writeReq();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr();
import "BDPI" function ActionValue#(Bit#(32)) writeData();
import "BDPI" function Bool                     readReq();
import "BDPI" function ActionValue#(Bit#(32))  readAddr();
import "BDPI" function Action        readData(Bit#(32) d);

		 
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
instance SelectBsimRdmaReadWrite#(128);
   module selectBsimRdmaReadWrite(BsimRdmaReadWrite#(128) ifc);
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(128) v);
	  write_pareff64(handle, addr, v[63:0]);
	  write_pareff64(handle, addr+8, v[127:64]);
       endmethod
       method ActionValue#(Bit#(128)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v0 <- read_pareff64(handle, addr);
	  let v1 <- read_pareff64(handle, addr+8);
	  return {v1,v0};
       endmethod
   endmodule
endinstance
		 
typedef (function Module#(PortalTop#(40, nmasters, dsz, ipins)) mkpt()) MkPortalTop#(numeric type nmasters, numeric type dsz, type ipins);

module [Module] mkBsimTopFromPortal#(MkPortalTop#(nmasters,dsz,ipins) constructor)(Empty)
   provisos (SelectBsimRdmaReadWrite#(dsz));

   Integer nmasters = valueOf(nmasters);
   let top <- constructor();
   Axi3Client#(40,dsz,6) master = ?;
   if (nmasters > 0) begin
      master = top.m_axi[0];

      BsimRdmaReadWrite#(dsz) rw <- selectBsimRdmaReadWrite();

      Reg#(Bool) inited <- mkReg(False);
      rule initialize(!inited);
	 inited <= True;
	 init_pareff();
      endrule

      Reg#(Bit#(40)) readAddr <- mkReg(0);
      Reg#(Bit#(5))  readLen <- mkReg(0);
      Reg#(Bit#(6)) readId <- mkReg(0);
      Reg#(Bit#(40)) writeAddr <- mkReg(0);
      Reg#(Bit#(5))  writeLen <- mkReg(0);
      Reg#(Bit#(6)) writeId <- mkReg(0);

      rule req_ar if (readLen == 0);
	 let req <- master.req_ar.get();
	 Bit#(5) rlen = extend(req.len)+1;
	 $display("req_ar: addr=%h len=%d", req.address, rlen);
	 readAddr <= req.address;
	 readLen <= rlen;
	 readId <= req.id;
      endrule
      rule read_resp if (readLen > 0);
	 let handle = readAddr[39:32];
	 let addr = readAddr[31:0];
	 Bit#(dsz) v <- rw.read_pareff(extend(handle), addr);
	 $display("read_resp: handle=%d addr=%h v=%h", handle, addr, v);
	 readLen <= readLen - 1;
	 readAddr <= readAddr + fromInteger(valueOf(dsz)/8);
	 let resp = Axi3ReadResponse { data: v, resp: 0, last: pack(readLen == 1), id: readId};
	 master.resp_read.put(resp);
      endrule

      rule req_aw if (writeLen == 0);
	 let req <- master.req_aw.get();
	 Bit#(5) wlen = extend(req.len)+1;
	 $display("req_aw: addr=%h len=%d", req.address, wlen);
	 writeAddr <= req.address;
	 writeLen <= wlen;
	 writeId <= req.id;
      endrule

      FIFO#(Axi3WriteResponse#(6)) bFifo <- mkFIFO();

      rule write_resp if (writeLen > 0);
	 let handle = writeAddr[39:32];
	 let addr = writeAddr[31:0];
	 let resp <- master.resp_write.get();
	 rw.write_pareff(extend(handle), addr, resp.data);
	 $display("write_resp: handle=%d addr=%h v=%h", handle, addr, resp.data);
	 writeLen <= writeLen - 1;
	 writeAddr <= writeAddr + fromInteger(valueOf(dsz)/8);
	 if (writeLen == 1)
	    bFifo.enq(Axi3WriteResponse { id: writeId, resp: 0 });
      endrule

      rule resp_b;
	 let resp = bFifo.first();
	 bFifo.deq();
	 master.resp_b.put(resp);
      endrule
   end

   let wf <- mkPipelineFIFO;
   let init_seq = (action 
		      initPortal(0);
		      initPortal(1);
		      initPortal(2);
		      initPortal(3);
		      initPortal(4);
		      initPortal(5);
		      initPortal(6);
		      initPortal(7);
                   endaction);
   let init_fsm <- mkOnce(init_seq);
   
   (* descending_urgency = "rdResp, rdReq" *)
   rule init_rule;
      init_fsm.start;
   endrule
   rule wrReq (writeReq());
      let wa <- writeAddr;
      let wd <- writeData;
      top.ctrl.req_aw.put(Axi3WriteRequest { address: wa, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 });
      wf.enq(wd);
   endrule
   rule wrData;
      wf.deq;
      top.ctrl.resp_write.put(Axi3WriteData { data: wf.first, id: 0, last: 1 });
   endrule
   rule wrB;
      let resp <- top.ctrl.resp_b.get();
   endrule
   rule rdReq (readReq());
      let ra <- readAddr;
	 top.ctrl.req_ar.put(Axi3ReadRequest { address: ra, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 });
   endrule
   rule rdResp;
      let rd <- top.ctrl.resp_read.get();
      readData(rd.data);
   endrule
endmodule

module mkBsimTop(Empty);
   let top <- mkBsimTopFromPortal(mkPortalTop);
   return top;
endmodule
