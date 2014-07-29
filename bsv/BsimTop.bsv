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

import Clocks            :: *;
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
import AxiMasterSlave    :: *;
import MemTypes          :: *;
import AxiDma            :: *;
import HostInterface    :: *;

`ifndef DataBusWidth
`define DataBusWidth 64
`endif
`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;
typedef `DataBusWidth DataBusWidth;

// implemented in BsimCtrl.cxx
import "BDPI" function Action      initPortal(Bit#(32) d);
import "BDPI" function Bool                    processReq32(Bit#(32) v);
import "BDPI" function ActionValue#(Bit#(32)) processAddr32(Bit#(32) v);
import "BDPI" function ActionValue#(Bit#(32)) writeData32();
import "BDPI" function Action        readData32(Bit#(32) d);

// implemented in BsimDma.cxx
import "BDPI" function Action pareff(Bit#(32) handle, Bit#(32) size);
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
	 let rv <- processAddr32(0);
	 return extend(rv);
      endmethod
      method Action readData(Bit#(32) d);
	 readData32(d);
      endmethod
      method Bool readReq();
	 return processReq32(0);
      endmethod
      method ActionValue#(Bit#(32)) writeAddr();
	 let rv <- processAddr32(1);
	 return extend(rv);
      endmethod
      method ActionValue#(Bit#(32)) writeData();
	 let rv <- writeData32();
	 return rv;
      endmethod
      method Bool writeReq();
	 return processReq32(1);
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

module mkAxi3Slave#(Integer id)(Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth))
   provisos (SelectBsimRdmaReadWrite#(serverBusWidth));

   BsimRdmaReadWrite#(serverBusWidth) rw <- selectBsimRdmaReadWrite();

   Reg#(Bit#(serverAddrWidth)) readAddrr <- mkReg(0);
   Reg#(Bit#(5))  readLen <- mkReg(0);
   Reg#(Bit#(serverIdWidth)) readId <- mkReg(0);
   Reg#(Bit#(serverAddrWidth)) writeAddrr <- mkReg(0);
   Reg#(Bit#(5))  writeLen <- mkReg(0);
   Reg#(Bit#(serverIdWidth)) writeId <- mkReg(0);

   let readLatency_I = 150;
   let writeLatency_I = 150;

   Bit#(64) readLatency = fromInteger(readLatency_I);
   Bit#(64) writeLatency = fromInteger(writeLatency_I);

   Reg#(Bit#(64)) req_ar_b_ts <- mkReg(0);
   Reg#(Bit#(64)) req_aw_b_ts <- mkReg(0);
   Reg#(Bit#(64)) cycle <- mkReg(0);
   Reg#(Bit#(64)) last_reqAr <- mkReg(0);
   Reg#(Bit#(64)) last_read_eob <- mkReg(0);
   Reg#(Bit#(64)) last_write_eob <- mkReg(0);

   FIFOF#(Tuple2#(Bit#(64), Axi3ReadRequest#(serverAddrWidth,serverIdWidth)))  readDelayFifo <- mkSizedFIFOF(readLatency_I/4);
   FIFOF#(Tuple2#(Bit#(64),Axi3WriteRequest#(serverAddrWidth,serverIdWidth))) writeDelayFifo <- mkSizedFIFOF(writeLatency_I/4);

   FIFOF#(Tuple2#(Bit#(64), Axi3WriteResponse#(serverIdWidth))) bFifo <- mkSizedFIFOF(16);

   rule increment_cycle;
      cycle <= cycle+1;
   endrule

   let read_jitter = True; //cycle[4:0] == 0;
   let write_jitter = True; //cycle[4:0] == 5;

   interface Put req_ar;
      method Action put(Axi3ReadRequest#(serverAddrWidth,serverIdWidth) req);
	 //if(id==1) $display("mkBsimHost::req_ar_a: %d %d", req.id, cycle-last_reqAr);
	 //last_reqAr <= cycle;
	 readDelayFifo.enq(tuple2(cycle,req));
      endmethod
   endinterface
   interface Get resp_read;
      method ActionValue#(Axi3ReadResponse#(serverBusWidth,serverIdWidth)) get if (((readLen > 0) || (readLen == 0 && (cycle-tpl_1(readDelayFifo.first)) > readLatency)) && read_jitter);
	 Bit#(5) read_len = ?;
	 Bit#(serverAddrWidth) read_addr = ?;
	 Bit#(serverIdWidth) read_id = ?;
	 Bit#(8) handle = ?;
	 if (readLen == 0 && (cycle-tpl_1(readDelayFifo.first)) > readLatency) begin
	    req_ar_b_ts <= cycle;
	    let req = tpl_2(readDelayFifo.first);
	    readDelayFifo.deq;
	    read_len = extend(req.len)+1;
	    read_addr = req.address;
	    read_id = req.id;
	    handle = req.address[39:32];
	    //if(id==1) $display("mkBsimHost::resp_read_a: %d %d %d", req.id,  cycle-last_read_eob, req.len);
	    //last_read_eob <= cycle;
	 end 
	 else begin
	    //$display("mkBsimHost::resp_read_b: %d %d", readId,  cycle-last_read_eob);
	    //last_read_eob <= cycle;
	    handle = readAddrr[39:32];
	    read_addr = readAddrr;
	    read_id = readId;
	    read_len = readLen;
	 end
	 Bit#(serverBusWidth) v <- rw.read_pareff(extend(handle), read_addr[31:0]);
	 readLen <= read_len - 1;
	 readId <= read_id;
	 readAddrr <= read_addr + fromInteger(valueOf(serverBusWidth)/8);
	 //$display("mkBsimHost::resp_read id=%d %d", read_id, read_len);
	 return Axi3ReadResponse { data: v, resp: 0, last: pack(readLen == 1), id: read_id};
      endmethod
   endinterface
   interface Put req_aw;
      method Action put(Axi3WriteRequest#(serverAddrWidth,serverIdWidth) req);
	 //$display("mkBsimHost::req_aw id=%d", req.id);
	 writeDelayFifo.enq(tuple2(cycle,req));
      endmethod
   endinterface
   interface Put resp_write;
      method Action put(Axi3WriteData#(serverBusWidth,serverIdWidth) resp) if (((writeLen > 0) || (writeLen == 0 && (cycle-tpl_1(writeDelayFifo.first)) > writeLatency)) && write_jitter);
	 Bit#(5) write_len = ?;
	 Bit#(serverAddrWidth) write_addr = ?;
	 Bit#(serverIdWidth) write_id = ?;
	 Bit#(8) handle = ?;
	 if (writeLen == 0 && (cycle-tpl_1(writeDelayFifo.first)) > writeLatency) begin
	    req_aw_b_ts <= cycle;
	    let req = tpl_2(writeDelayFifo.first);
	    writeDelayFifo.deq;
	    write_addr = req.address;
	    write_len = extend(req.len)+1;
	    write_id = req.id;
	    handle = req.address[39:32];
	    //$display("mkBsimHost::resp_write_a: %d %d", req.id,  cycle-last_write_eob);
	    //last_write_eob <= cycle;
	 end
	 else begin
	    //$display("mkBsimHost::resp_write_b: %d %d", writeId,  cycle-last_write_eob);
	    //last_write_eob <= cycle;
	    handle = writeAddrr[39:32];
	    write_len = writeLen;
	    write_addr = writeAddrr;
	    write_id = writeId;
	 end
	 rw.write_pareff(extend(handle), write_addr[31:0], resp.data);
	 //$display("write_resp(%d): handle=%d addr=%h v=%h", cycle, handle, write_addr, resp.data);
	 writeId <= write_id;
	 writeLen <= write_len - 1;
	 writeAddrr <= write_addr + fromInteger(valueOf(serverBusWidth)/8);
	 if (write_len == 1) begin
	    bFifo.enq(tuple2(cycle,Axi3WriteResponse { id: write_id, resp: 0 }));
	 end
      endmethod
   endinterface
   interface Get resp_b;
      method ActionValue#(Axi3WriteResponse#(serverIdWidth)) get if ((cycle-tpl_1(bFifo.first)) > writeLatency);
	 bFifo.deq();
	 return tpl_2(bFifo.first());
      endmethod
   endinterface

endmodule


module  mkBsimHost#(Clock double_clock, Reset double_reset)(BsimHost#(clientAddrWidth, clientBusWidth, clientIdWidth,
			      serverAddrWidth, serverBusWidth, serverIdWidth,
			      nSlaves))
   provisos (SelectBsimRdmaReadWrite#(serverBusWidth),
	     SelectBsimCtrlReadWrite#(clientAddrWidth, clientBusWidth));

   Vector#(nSlaves,Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth)) servers <- mapM(mkAxi3Slave,genVector);
   BsimCtrlReadWrite#(clientAddrWidth,clientBusWidth) crw <- selectBsimCtrlReadWrite();
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
		      initPortal(8);
		      initPortal(9);
		      initPortal(10);
		      initPortal(11);
		      initPortal(12);
		      initPortal(13);
		      initPortal(14);
		      initPortal(15);
                   endaction);
   let init_fsm <- mkOnce(init_seq);

   rule init_rule;
      init_fsm.start;
   endrule

   interface axi_servers = servers;
   interface MemMaster mem_client;
      interface MemReadClient read_client;
        interface Get readReq;
	 method ActionValue#(MemRequest#(clientAddrWidth)) get() if (crw.readReq);
	    //$write("req_ar: ");
	    let ra <- crw.readAddr;
	    //$display("ra=%h", ra);
	    return MemRequest { addr: ra, burstLen: 1, tag: 0};
	 endmethod
        endinterface
        interface Put readData;
	 method Action put(MemData#(clientBusWidth) rd);
	    //$display("resp_read: rd=%h", rd);
	    crw.readData(rd.data);
	 endmethod
        endinterface
      endinterface
      interface MemWriteClient write_client;
        interface Get writeReq;
	 method ActionValue#(MemRequest#(clientAddrWidth)) get() if (crw.writeReq());
	    //$write("req_aw: ");
	    let wa <- crw.writeAddr;
	    let wd <- crw.writeData;
	    //$display("wa=%h, wd=%h", wa,wd);
	    wf.enq(wd);
	    return MemRequest { addr: wa, burstLen: 1, tag: 0 };
	 endmethod
        endinterface
        interface Get writeData;
	 method ActionValue#(MemData#(clientBusWidth)) get;
	    wf.deq;
	    //$display("resp_write %h", wf.first);
	    return MemData { data: wf.first, tag: 0, last: True };
	 endmethod
        endinterface
        interface Put writeDone;
	 method Action put(Bit#(ObjectTagSize) resp);
	    noAction;
	 endmethod
        endinterface
      endinterface
   endinterface
   interface doubleClock = double_clock;
   interface doubleReset = double_reset;
endmodule

module  mkBsimTop(Empty)
   provisos (SelectBsimRdmaReadWrite#(DataBusWidth));
   let divider <- mkClockDivider(2);
   Clock doubleClock = divider.fastClock;
   Clock singleClock = divider.slowClock;
   Reset doubleReset <- exposeCurrentReset;
   let single_reset <- mkReset(2, True, singleClock);
   Reset singleReset = single_reset.new_rst;
   BsimHost#(32,32,12,40,DataBusWidth,6,NumberOfMasters) host <- mkBsimHost(clocked_by singleClock, reset_by singleReset, doubleClock, doubleReset);
`ifdef IMPORT_HOSTIF
   PortalTop#(40,DataBusWidth,PinType,NumberOfMasters) top <- mkPortalTop(clocked_by singleClock, reset_by singleReset, host);
`else
   PortalTop#(40,DataBusWidth,PinType,NumberOfMasters) top <- mkPortalTop(clocked_by singleClock, reset_by singleReset);
`endif
   Vector#(NumberOfMasters,Axi3Master#(40,DataBusWidth,6)) m_axis <- mapM(mkAxiDmaMaster,top.masters, clocked_by singleClock, reset_by singleReset);
   mkConnection(host.mem_client, top.slave, clocked_by singleClock, reset_by singleReset);
   mapM(uncurry(mkConnection),zip(m_axis, host.axi_servers), clocked_by singleClock, reset_by singleReset);

`ifdef BSIMRESPONDER
   `BSIMRESPONDER (top.pins);
`endif
endmodule
