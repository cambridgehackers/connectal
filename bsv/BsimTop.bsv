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
import FIFOF             :: *;
import FIFO              :: *;
import SpecialFIFOs      :: *;
import GetPut            :: *;
import Connectable       :: *;
import StmtFSM           :: *;
import Portal            :: *;
import AxiMasterSlave    :: *;
import Leds              :: *;
import Top               :: *;
import GetPutF           :: *;
import AxiMasterSlave    :: *;

// implemented in BsimCtrl.cxx
import "BDPI" function Action      initPortal(Bit#(32) d);
import "BDPI" function Bool                    writeReq32();
import "BDPI" function ActionValue#(Bit#(32)) writeAddr32();
import "BDPI" function ActionValue#(Bit#(32)) writeData32();
import "BDPI" function Bool                     readReq32();
import "BDPI" function ActionValue#(Bit#(32))  readAddr32();
import "BDPI" function Action        readData32(Bit#(32) d);
		 
// implemented in BsimDma.cxx		 
import "BDPI" function Action pareff(Bit#(32) handle, Bit#(32) size);
import "BDPI" function Action init_pareff();
import "BDPI" function Action write_pareff32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_pareff64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_pareff32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff64(Bit#(32) handle, Bit#(32) addr);
		 
		 
interface BsimCtrlReadWrite#(numeric type asz, numeric type dsz);
   method ActionValue#(Bit#(asz)) readAddr();
   method Action readData(Bit#(dsz) d);		    
   method Bool readReq();
   method ActionValue#(Bit#(asz)) writeAddr();
   method ActionValue#(Bit#(dsz)) writeData();
   method Bool writeReq();
endinterface
		 
typeclass SelectBsimCtrlReadWrite#(numeric type asz, numeric type dsz);	
   module selectBsimCtrlReadWrite(BsimCtrlReadWrite#(asz,dsz) ifc);	
endtypeclass 

instance SelectBsimCtrlReadWrite#(32,32);
   module selectBsimCtrlReadWrite(BsimCtrlReadWrite#(32,32) ifc);
      method ActionValue#(Bit#(32)) readAddr();
	 let rv <- readAddr32();
	 return extend(rv);
      endmethod
      method Action readData(Bit#(32) d);		    
	 readData32(d);
      endmethod
      method Bool readReq();
	 return readReq32();
      endmethod
      method ActionValue#(Bit#(32)) writeAddr();
	 let rv <- writeAddr32();
	 return extend(rv);
      endmethod
      method ActionValue#(Bit#(32)) writeData();
	 let rv <- writeData32();
	 return rv;
      endmethod
      method Bool writeReq();
	 return writeReq32();
      endmethod
   endmodule
endinstance
      
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

// this interface should allow for different master and slave bus paraters;		 
interface BsimHost#(numeric type clientAddrWidth, numeric type clientBusWidth, numeric type clientIdWidth, 
		    numeric type serverAddrWidth, numeric type serverBusWidth, numeric type serverIdWidth);
   interface Axi3Master#(clientAddrWidth, clientBusWidth, clientIdWidth)  axi_client;
   interface Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth)  axi_server;
endinterface
      
module [Module] mkBsimHost (BsimHost#(clientAddrWidth, clientBusWidth, clientIdWidth, 
				      serverAddrWidth, serverBusWidth, serverIdWidth))
   provisos (SelectBsimRdmaReadWrite#(serverBusWidth),
	     SelectBsimCtrlReadWrite#(clientAddrWidth, clientBusWidth));
   
   BsimRdmaReadWrite#(serverBusWidth) rw <- selectBsimRdmaReadWrite();
   BsimCtrlReadWrite#(clientAddrWidth,clientBusWidth) crw <- selectBsimCtrlReadWrite();
   
   Reg#(Bit#(serverAddrWidth)) readAddrr <- mkReg(0);
   Reg#(Bit#(5))  readLen <- mkReg(0);
   Reg#(Bit#(serverIdWidth)) readId <- mkReg(0);
   Reg#(Bit#(serverAddrWidth)) writeAddrr <- mkReg(0);
   Reg#(Bit#(5))  writeLen <- mkReg(0);
   Reg#(Bit#(serverIdWidth)) writeId <- mkReg(0);
   
   Bit#(64) readLatency = 32;
   Bit#(64) writeLatency = 32;
   
   Reg#(Bit#(64)) cycle <- mkReg(0);
   FIFO#(Tuple2#(Bit#(64), Axi3ReadRequest#(serverAddrWidth,serverIdWidth))) readDelayFifo <- mkSizedFIFO(32);
   FIFO#(Tuple2#(Bit#(64),Axi3WriteRequest#(serverAddrWidth,serverIdWidth))) writeDelayFifo <- mkSizedFIFO(32);
   FIFOF#(Axi3WriteResponse#(serverIdWidth)) bFifo <- mkFIFOF();
				    
   rule increment_cycle;
      cycle <= cycle+1;
   endrule
   
   rule req_ar_b if (readLen == 0 && (cycle-tpl_1(readDelayFifo.first)) > readLatency);
      let req = tpl_2(readDelayFifo.first);
      readDelayFifo.deq;
      Bit#(5) rlen = extend(req.len)+1;
      readAddrr <= req.address;
      readLen <= rlen;
      readId <= req.id;
      //$display("mkBsimHost::req_ar_b: id=%d len=%d", req.id, rlen);
   endrule

   rule req_aw_b if (writeLen == 0 && (cycle-tpl_1(writeDelayFifo.first)) > writeLatency);
      let req = tpl_2(writeDelayFifo.first);
      writeDelayFifo.deq;
      Bit#(5) wlen = extend(req.len)+1;
      writeAddrr <= req.address;
      writeLen <= wlen;
      writeId <= req.id;
   endrule

   FIFO#(Bit#(clientBusWidth)) wf <- mkPipelineFIFO;
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
   
   rule init_rule;
      init_pareff();
      init_fsm.start;
   endrule

   interface Axi3Slave axi_server;
      interface Put req_ar;
	 method Action put(Axi3ReadRequest#(serverAddrWidth,serverIdWidth) req);
	    readDelayFifo.enq(tuple2(cycle,req));
	 endmethod
      endinterface
      interface GetF resp_read;
	 method ActionValue#(Axi3ReadResponse#(serverBusWidth,serverIdWidth)) get if (readLen > 0);
	    let handle = readAddrr[39:32];
	    let addr = readAddrr[31:0];
	    Bit#(serverBusWidth) v <- rw.read_pareff(extend(handle), addr);
	    readLen <= readLen - 1;
	    readAddrr <= readAddrr + fromInteger(valueOf(serverBusWidth)/8);
	    //$display("mkBsimHost::resp_read id=%d %d", readId, readLen); 
	    return Axi3ReadResponse { data: v, resp: 0, last: pack(readLen == 1), id: readId};
	 endmethod
	 method Bool notEmpty();
	    return (readLen > 0);
	 endmethod
      endinterface
      interface Put req_aw;
	 method Action put(Axi3WriteRequest#(serverAddrWidth,serverIdWidth) req); 
	    writeDelayFifo.enq(tuple2(cycle,req));
	 endmethod
      endinterface
      interface Put resp_write;
	 method Action put(Axi3WriteData#(serverBusWidth,serverIdWidth) resp) if (writeLen > 0);
	    let handle = writeAddrr[39:32];
	    let addr = writeAddrr[31:0];
	    //$display("write_resp: handle=%d addr=%h v=%h", handle, addr, resp.data);
	    rw.write_pareff(extend(handle), addr, resp.data);
	    writeLen <= writeLen - 1;
	    writeAddrr <= writeAddrr + fromInteger(valueOf(serverBusWidth)/8);
	    if (writeLen == 1)
	       bFifo.enq(Axi3WriteResponse { id: writeId, resp: 0 });
	 endmethod
      endinterface
      interface GetF resp_b;
	 method ActionValue#(Axi3WriteResponse#(serverIdWidth)) get;
	    bFifo.deq();
	    return bFifo.first();
	 endmethod
	 method Bool notEmpty();
	    return bFifo.notEmpty();
	 endmethod
      endinterface
   endinterface

   interface Axi3Master axi_client;
      interface Get req_ar;
	 method ActionValue#(Axi3ReadRequest#(clientAddrWidth,clientIdWidth)) get() if (crw.readReq);
	    //$write("req_ar: ");
	    let ra <- crw.readAddr;
	    //$display("ra=%h", ra);
	    return Axi3ReadRequest { address: ra, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 };
	 endmethod
      endinterface
      interface Put resp_read;
	 method Action put(Axi3ReadResponse#(clientBusWidth,clientIdWidth) rd);
	    //$display("resp_read: rd=%h", rd);
	    crw.readData(rd.data);
	 endmethod
      endinterface
      interface Get req_aw;
	 method ActionValue#(Axi3WriteRequest#(clientAddrWidth,clientIdWidth)) get() if (crw.writeReq());
	    //$write("req_aw: ");
	    let wa <- crw.writeAddr;
	    let wd <- crw.writeData;
	    //$display("wa=%h, wd=%h", wa,wd);
	    wf.enq(wd);
	    return Axi3WriteRequest { address: wa, len: 0, size: axiBusSize(32), id: 0, prot: 0, burst: 1, cache: 'b11, qos: 0, lock: 0 };
	 endmethod
      endinterface
      interface Get resp_write;
	 method ActionValue#(Axi3WriteData#(clientBusWidth,clientIdWidth)) get;
	    wf.deq;
	    //$display("resp_write %h", wf.first);
	    return Axi3WriteData { data: wf.first, id: 0, last: 1 };
	 endmethod
      endinterface
      interface Put resp_b;
	 method Action put(Axi3WriteResponse#(clientIdWidth) resp);
	    noAction;
	 endmethod
      endinterface
   endinterface

endmodule
   
//typedef (function Module#(PortalTop#(40, dsz, ipins)) mkpt()) MkPortalTop#(numeric type dsz, type ipins);

module mkBsimTop(Empty);

   BsimHost#(32,32,12,40,64,6) host <- mkBsimHost;
   StdPortalTop#(40) top <- mkPortalTop;
   
   mkConnection(host.axi_client, top.ctrl);
   mkConnection(top.m_axi, host.axi_server);
   
endmodule
