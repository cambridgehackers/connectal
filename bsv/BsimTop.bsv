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
import HostInterface     :: *;
import CtrlMux           :: *;
import ClientServer      :: *;
import MemSlaveEngine    :: *;
import MemMasterEngine   :: *;
import PCIE              :: *;

`ifndef PinType
`define PinType Empty
`endif

typedef `PinType PinType;
typedef `NumberOfMasters NumberOfMasters;

// implemented in BsimCtrl.cxx
import "BDPI" function Action                 initPortal();
import "BDPI" function Bool                   checkForRequest(Bit#(32) v);
import "BDPI" function ActionValue#(Bit#(64)) readRequest32();
import "BDPI" function ActionValue#(Bit#(64)) writeRequest32();
import "BDPI" function Action                 readResponse32(Bit#(32) d, Bit#(32) tag);
import "BDPI" function Action                 interruptLevel(Bit#(1) d);

// implemented in BsimDma.cxx
import "BDPI" function Action pareff(Bit#(32) id, Bit#(32) handle, Bit#(32) size);
import "BDPI" function Action write_pareff32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_pareff64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_pareff32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff64(Bit#(32) handle, Bit#(32) addr);

typedef struct {
   Bit#(MemTagSize) tag;
   Bit#(asz) addr;
} BsimReadRequest#(numeric type asz, numeric type dsz) deriving(Eq, Bits);

typedef struct {
   Bit#(dsz) data;
   Bit#(asz) addr;
} BsimWriteRequest#(numeric type asz, numeric type dsz) deriving(Eq, Bits);

interface BsimCtrlReadWrite#(numeric type asz, numeric type dsz);
   method ActionValue#(BsimReadRequest#(asz, dsz)) readRequest();
   method Action readResponse(Bit#(dsz) d, Bit#(MemTagSize) tag);
   method ActionValue#(BsimWriteRequest#(asz, dsz)) writeRequest();
endinterface

typeclass SelectBsimCtrlReadWrite#(numeric type asz, numeric type dsz);
   module selectBsimCtrlReadWrite(BsimCtrlReadWrite#(asz,dsz) ifc);
endtypeclass

instance SelectBsimCtrlReadWrite#(32,32);
   module selectBsimCtrlReadWrite(BsimCtrlReadWrite#(32,32) ifc);
      method ActionValue#(BsimReadRequest#(32,32)) readRequest() if (checkForRequest(0));
	 let rv <- readRequest32();
	 return BsimReadRequest{tag: truncate(rv[63:32]), addr:rv[31:0]};
      endmethod
      method Action readResponse(Bit#(32) d, Bit#(MemTagSize) tag);
	 readResponse32(d, extend(tag));
      endmethod
      method ActionValue#(BsimWriteRequest#(32, 32)) writeRequest() if (checkForRequest(1));
	 let rv <- writeRequest32();
	 return BsimWriteRequest{data: rv[63:32], addr: rv[31:0]};
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

module mkAxi3Slave(Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth))
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

   FIFOF#(Tuple2#(Bit#(64), Axi3ReadRequest#(serverAddrWidth,serverIdWidth)))  readDelayFifo <- mkSizedFIFOF(readLatency_I);
   FIFOF#(Tuple2#(Bit#(64),Axi3WriteRequest#(serverAddrWidth,serverIdWidth))) writeDelayFifo <- mkSizedFIFOF(writeLatency_I);

   FIFOF#(Tuple2#(Bit#(64), Axi3WriteResponse#(serverIdWidth))) bFifo <- mkSizedFIFOF(writeLatency_I);

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

   Vector#(nSlaves,Axi3Slave#(serverAddrWidth,  serverBusWidth, serverIdWidth)) servers <- replicateM(mkAxi3Slave);
   BsimCtrlReadWrite#(clientAddrWidth,clientBusWidth) crw <- selectBsimCtrlReadWrite();
   FIFO#(Bit#(clientBusWidth)) wf <- mkPipelineFIFO;
   let init_fsm <- mkOnce(initPortal());

   rule init_rule;
      init_fsm.start;
   endrule

   let verbose = False;
    Reg#(Bit#(32)) cycles      <- mkReg(0);
    rule count;
       cycles <= cycles + 1;
    endrule

   interface axi_servers = servers;
   interface PhysMemMaster mem_client;
      interface PhysMemReadClient read_client;
        interface Get readReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth)) get();
	    //$write("req_ar: ");
	    let ra <- crw.readRequest();
	    //$display("ra=%h", ra);
	    let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	    if (verbose) $display("\n%d BsimHost.readReq addr=%h burstLen=%d", cycles, ra, burstLen);
	    return PhysMemRequest { addr: ra.addr, burstLen: burstLen, tag: ra.tag};
	 endmethod
        endinterface
        interface Put readData;
	 method Action put(MemData#(clientBusWidth) rd);
	    //$display("resp_read: rd=%h", rd);
	    if (verbose) $display("%d BsimHost.readData %h", cycles, rd.data);
	    crw.readResponse(rd.data, rd.tag);
	 endmethod
        endinterface
      endinterface
      interface PhysMemWriteClient write_client;
        interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth)) get();
	    let wd <- crw.writeRequest;
	    wf.enq(wd.data);
	    let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	    if (verbose) $display("\n%d BsimHost.writeReq addr/data=%h burstLen=%d", cycles, wd, burstLen);
	    return PhysMemRequest { addr: wd.addr, burstLen: burstLen, tag: 0 };
	 endmethod
        endinterface
        interface Get writeData;
	 method ActionValue#(MemData#(clientBusWidth)) get;
	    wf.deq;
	    if (verbose) $display("%d BsimHost.writeData %h", cycles, wf.first);
	    return MemData { data: wf.first, tag: 0, last: True };
	 endmethod
        endinterface
        interface Put writeDone;
	 method Action put(Bit#(MemTagSize) resp);
	    if (verbose) $display("%d BsimHost.writeDone %d", cycles, resp);
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
   BsimHost#(32,32,12,PhysAddrWidth,DataBusWidth,6,NumberOfMasters) host <- mkBsimHost(clocked_by singleClock, reset_by singleReset, doubleClock, doubleReset);
`ifdef IMPORT_HOSTIF
   ConnectalTop#(PhysAddrWidth,DataBusWidth,PinType,NumberOfMasters) top <- mkConnectalTop(clocked_by singleClock, reset_by singleReset, host);
`else
   ConnectalTop#(PhysAddrWidth,DataBusWidth,PinType,NumberOfMasters) top <- mkConnectalTop(clocked_by singleClock, reset_by singleReset);
`endif
   Vector#(NumberOfMasters,Axi3Master#(PhysAddrWidth,DataBusWidth,6)) m_axis <- mapM(mkAxiDmaMaster,top.masters, clocked_by singleClock, reset_by singleReset);
   mapM(uncurry(mkConnection),zip(m_axis, host.axi_servers), clocked_by singleClock, reset_by singleReset);
`ifndef BSIM_EXERCISE_MEM_MASTER_SLAVE
   mkConnection(host.mem_client, top.slave, clocked_by singleClock, reset_by singleReset);
`else
   PciId masterPciId = unpack(22);
   PciId slavePciId = unpack(23);
   MemMasterEngine masterEngine <- mkMemMasterEngine(masterPciId, clocked_by singleClock, reset_by singleReset);
   MemSlaveEngine#(32) slaveEngine <- mkMemSlaveEngine(slavePciId, clocked_by singleClock, reset_by singleReset);
   mkConnection(host.mem_client, slaveEngine.slave, clocked_by singleClock, reset_by singleReset);
   mkConnection(slaveEngine.tlp.request, masterEngine.tlp.response, clocked_by singleClock, reset_by singleReset);
   mkConnection(slaveEngine.tlp.response, masterEngine.tlp.request, clocked_by singleClock, reset_by singleReset);
   mkConnection(masterEngine.master, top.slave, clocked_by singleClock, reset_by singleReset);
`endif

   let intr_mux <- mkInterruptMux(top.interrupt);
   rule int_rule;
      interruptLevel(truncate(pack(intr_mux)));
   endrule

`ifdef BSIMRESPONDER
   `BSIMRESPONDER (top.pins);
`endif
endmodule
