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
import Top               :: *;
import MemTypes          :: *;
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

// implemented in BsimCtrl.cpp
import "BDPI" function Action                 initPortal();
import "BDPI" function Bool                   checkForRequest(Bit#(32) v);
import "BDPI" function ActionValue#(Bit#(64)) getRequest32(Bit#(32) v);
import "BDPI" function Action                 readResponse32(Bit#(32) d, Bit#(32) tag);
import "BDPI" function Action                 interruptLevel(Bit#(1) d);

// implemented in BsimDma.cpp
import "BDPI" function Action write_pareff32(Bit#(32) handle, Bit#(32) addr, Bit#(32) v);
import "BDPI" function Action write_pareff64(Bit#(32) handle, Bit#(32) addr, Bit#(64) v);
import "BDPI" function ActionValue#(Bit#(32)) read_pareff32(Bit#(32) handle, Bit#(32) addr);
import "BDPI" function ActionValue#(Bit#(64)) read_pareff64(Bit#(32) handle, Bit#(32) addr);

module mkBsimCtrlReadWrite(PhysMemMaster#(clientAddrWidth, clientBusWidth))
   provisos(Add#(a__, 32, clientAddrWidth), Add#(b__, 32, clientBusWidth));
   FIFO#(Bit#(clientBusWidth)) wf <- mkPipelineFIFO;
   Reg#(Bit#(32)) cycles      <- mkReg(0);
   rule count;
      cycles <= cycles + 1;
   endrule
 
   let verbose = False;
   let init_fsm <- mkOnce(initPortal());
 
   rule init_rule;
      init_fsm.start;
   endrule
   interface PhysMemReadClient read_client;
     interface Get readReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth)) get() if (checkForRequest(0));
	 //$write("req_ar: ");
	 let ra <- getRequest32(0);
	 //$display("ra=%h", ra);
	 let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	 if (verbose) $display("\n%d BsimHost.readReq addr=%h burstLen=%d", cycles, ra, burstLen);
	 return PhysMemRequest { addr: extend(ra[31:0]), burstLen: burstLen, tag: truncate(ra[63:32])};
	 endmethod
     endinterface
     interface Put readData;
	 method Action put(MemData#(clientBusWidth) rd);
	 //$display("resp_read: rd=%h", rd);
	 if (verbose) $display("%d BsimHost.readData %h", cycles, rd.data);
	 readResponse32(truncate(rd.data), extend(rd.tag));
	 endmethod
     endinterface
   endinterface
   interface PhysMemWriteClient write_client;
     interface Get writeReq;
	 method ActionValue#(PhysMemRequest#(clientAddrWidth)) get() if (checkForRequest(1));
	 let wd <- getRequest32(1);
	 wf.enq(extend(wd[63:32]));
	 let burstLen = fromInteger(valueOf(clientBusWidth) / 8);
	 if (verbose) $display("\n%d BsimHost.writeReq addr/data=%h burstLen=%d", cycles, wd, burstLen);
	 return PhysMemRequest { addr: extend(wd[31:0]), burstLen: burstLen, tag: 0 };
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
endmodule

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
instance SelectBsimRdmaReadWrite#(256);
   module selectBsimRdmaReadWrite(BsimRdmaReadWrite#(256) ifc);
       method Action write_pareff(Bit#(32) handle, Bit#(32) addr, Bit#(256) v);
	  write_pareff64(handle, addr, v[63:0]);
	  write_pareff64(handle, addr+8, v[127:64]);
	  write_pareff64(handle, addr+16, v[191:128]);
	  write_pareff64(handle, addr+24, v[255:192]);
       endmethod
       method ActionValue#(Bit#(256)) read_pareff(Bit#(32) handle, Bit#(32) addr);
	  let v0 <- read_pareff64(handle, addr);
	  let v1 <- read_pareff64(handle, addr+8);
	  let v2 <- read_pareff64(handle, addr+16);
	  let v3 <- read_pareff64(handle, addr+24);
	  return {v3,v2,v1,v0};
       endmethod
   endmodule
endinstance

module mkBsimDmaMaster(PhysMemSlave#(serverAddrWidth,serverBusWidth))
   provisos(Div#(serverBusWidth,8,dataWidthBytes),
	    Mul#(dataWidthBytes,8,serverBusWidth),
	    Log#(dataWidthBytes,beatShift),
	    SelectBsimRdmaReadWrite#(serverBusWidth));

   let verbose = False;
   BsimRdmaReadWrite#(serverBusWidth) rw <- selectBsimRdmaReadWrite();

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
	 Bit#(serverBusWidth) v <- rw.read_pareff(extend(handle), read_addr[31:0]);
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
	 rw.write_pareff(extend(handle), write_addr[31:0], resp.data);
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


module  mkBsimHost#(Clock derived_clock, Reset derived_reset)(BsimHost#(clientAddrWidth, clientBusWidth, clientIdWidth,
			      serverAddrWidth, serverBusWidth, serverIdWidth,
			      nSlaves))
   provisos (SelectBsimRdmaReadWrite#(serverBusWidth),
             Add#(a__, 32, clientAddrWidth), Add#(b__, 32, clientBusWidth),
             Mul#(TDiv#(serverBusWidth, 8), 8, serverBusWidth));

   Vector#(nSlaves,PhysMemSlave#(serverAddrWidth,  serverBusWidth)) servers <- replicateM(mkBsimDmaMaster);
   PhysMemMaster#(clientAddrWidth, clientBusWidth) crw <- mkBsimCtrlReadWrite();

   interface mem_servers = servers;
   interface PhysMemMaster mem_client = crw;
   interface derivedClock = derived_clock;
   interface derivedReset = derived_reset;
endmodule

module  mkBsimTop(Empty)
   provisos (SelectBsimRdmaReadWrite#(DataBusWidth));
   let divider <- mkClockDivider(2);
   Clock derivedClock = divider.fastClock;
   Clock singleClock = divider.slowClock;
   Reset derivedReset <- exposeCurrentReset;
   let single_reset <- mkReset(2, True, singleClock);
   Reset singleReset = single_reset.new_rst;
   BsimHost#(32,32,12,PhysAddrWidth,DataBusWidth,6,NumberOfMasters) host <- mkBsimHost(clocked_by singleClock, reset_by singleReset, derivedClock, derivedReset);
   ConnectalTop#(PhysAddrWidth,DataBusWidth,PinType,NumberOfMasters) top <- mkConnectalTop(
`ifdef IMPORT_HOSTIF
       host,
`endif
       clocked_by singleClock, reset_by singleReset);
   mapM(uncurry(mkConnection),zip(top.masters, host.mem_servers), clocked_by singleClock, reset_by singleReset);
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
