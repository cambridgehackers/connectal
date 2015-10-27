
// Copyright (c) 2012 Nokia, Inc.
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

import Vector::*;
import GetPut::*;
import FIFOF::*;
import SpecialFIFOs::*;
import FIFO::*;

`include "ConnectalProjectConfig.bsv"
import ConnectalConfig::*;
import HostInterface::*;
import Connectable::*;
import AddressGenerator::*;

import Portal::*;
import MemTypes::*;
import Arith::*;
import Pipe::*;

interface PortalCtrl#(numeric type addrWidth, numeric type dataWidth);
   method ActionValue#(Bit#(dataWidth)) read(Bit#(addrWidth) addr);
   method Action write(Bit#(addrWidth) addr, Bit#(dataWidth) v);
endinterface

interface PortalCtrlMemSlave#(numeric type addrWidth, numeric type dataWidth);
   interface PortalCtrl#(addrWidth, dataWidth)  memSlave;
   interface ReadOnly#(Bool)                    interrupt;
   interface WriteOnly#(Bit#(dataWidth))        num_portals;
endinterface

module mkInterruptMux#(Vector#(numPortals,ReadOnly#(Bool)) inputs) (ReadOnly#(Bool))
   provisos(Add#(nz, TLog#(numPortals), 4),
	    Add#(1, a__, numPortals));
   function Bool my_read(ReadOnly#(Bool) x);
      return x._read;
   endfunction
   method Bool _read;
      return fold(boolor,map(my_read,inputs));
   endmethod
endmodule

module mkPortalInterrupt#(Vector#(numIndications, PipeOut#(Bit#(dataWidth))) indicationPipes)
   (PortalInterrupt#(dataWidth));
   Bool      interruptStatus = False;
   function Bool pipeOutNotEmpty(PipeOut#(a) po); return po.notEmpty(); endfunction
   Vector#(numIndications, Bool) readyBits = map(pipeOutNotEmpty, indicationPipes);
   
   Bit#(dataWidth)  readyChannel = -1;
   for (Integer i = valueOf(numIndications) - 1; i >= 0; i = i - 1) begin
      if (readyBits[i]) begin
         interruptStatus = True;
         readyChannel = fromInteger(i);
      end
   end
   method Bool status();
      return interruptStatus;
   endmethod
   method Bit#(dataWidth) channel();
      return readyChannel;
   endmethod
endmodule

module mkPortalCtrlMemSlave#(Bit#(dataWidth) ifcId, PortalInterrupt#(dataWidth) intr)
   (PortalCtrlMemSlave#(addrWidth, dataWidth))
   provisos(Add#(d__, dataWidth, TMul#(dataWidth, 2)));
   Reg#(Bit#(dataWidth)) num_portals_reg <- mkReg(0);
   Reg#(Bool) interruptEnableReg <- mkReg(False);
   Reg#(Bit#(TMul#(dataWidth,2))) cycle_count <- mkReg(0);
   Reg#(Bit#(dataWidth))    snapshot <- mkReg(0);
   let verbose = False;
   
   rule count;
      cycle_count <= cycle_count+1;
   endrule
   
   interface PortalCtrl memSlave;
   method Action write(Bit#(addrWidth) addr, Bit#(dataWidth) v);
      if (addr == 4)
	 interruptEnableReg <= v[0] == 1'd1;
   endmethod

   method ActionValue#(Bit#(dataWidth)) read(Bit#(addrWidth) addr);
	       let v = 'h05a05a0;
	       if (addr == 0)
		  v = intr.status() ? 1 : 0;
	       if (addr == 4)
		  v = interruptEnableReg ? 1 : 0;
	       if (addr == 8)
		  v = fromInteger(valueOf(NumberOfTiles));
               if (addr == 'h00C) begin
		  if (intr.status())
		     v = intr.channel()+1;
		  else 
		     v = 0;
               end
	       if (addr == 'h010)
		  v = ifcId;
	       if (addr == 'h014)
		  v = num_portals_reg;
	       if (addr == 'h018) begin
		  snapshot <= truncate(cycle_count);
		  v = truncate(cycle_count>>valueOf(dataWidth));
	       end
	       if (addr == 'h01C)
		  v = snapshot;
	       return v;
   endmethod
   endinterface
   interface ReadOnly interrupt;
      method Bool _read();
	 return intr.status() && interruptEnableReg;
      endmethod
   endinterface
   interface WriteOnly num_portals;
      method Action _write(Bit#(dataWidth) v);
	 num_portals_reg <= v;
      endmethod
   endinterface
endmodule   

module mkMemMethodMuxIn#(PortalCtrl#(aw,dataWidth) ctrl, Vector#(numRequests, PipeIn#(Bit#(dataWidth))) requests
        )(PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    , Add#(a__, TLog#(numRequests), selWidth)
            , Add#(1, b__, dataWidth)
      );
   AddressGenerator#(aw,dataWidth) fifoReadAddrGenerator  <- mkAddressGenerator();
   AddressGenerator#(aw,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(MemTagSize))                fifoWriteDoneFifo <- mkFIFO();
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TSub#(addrWidth,1));
   function Bit#(selWidth) psel(Bit#(addrWidth) a);
      Bit#(selWidth) v = a[port_sel_high:port_sel_low];
      return v - 1;
   endfunction
   function Bool pselCtrl(Bit#(addrWidth) a);
      Bit#(selWidth) v = a[port_sel_high:port_sel_low];
      return v == 0;
   endfunction
   function Bit#(aw) asel(Bit#(addrWidth) a);
      return a[(port_sel_low-1):0];
   endfunction

   FIFO#(Bit#(MemTagSize)) doneFifo          <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_ars <- mkFIFO1();
   FIFO#(Bit#(TLog#(numRequests))) rs <- mkFIFO1();
   FIFO#(Bool)                   rsCtrl <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numRequests))) ws <- mkFIFO1();
   FIFO#(Bool)                   wsCtrl <- mkFIFO1();

   rule write_done;
      let rv <- toGet(fifoWriteDoneFifo).get();
      ws.deq();
      wsCtrl.deq();
      doneFifo.enq(rv);
   endrule

   rule req_aw;
      let req <- toGet(req_aws).get;
      fifoWriteAddrGenerator.request.put(req);
   endrule

   rule req_ar;
      let req <- toGet(req_ars).get;
      fifoReadAddrGenerator.request.put(req);
   endrule

   FIFO#(MemData#(dataWidth)) writeDataFifo <- mkFIFO();
   rule writeDataRule;
      let wdata <- toGet(writeDataFifo).get();
      //$display("mkMemMethodMux.writeData aw=%d ws=%d data=%h", valueOf(aw), ws.first, wdata.data);
      let b <- fifoWriteAddrGenerator.addrBeat.get();
      //$display("mkPipeInMemSlave.writeData.put addr=%h data=%h", b.addr, wdata.data);
      if (b.last)
	 fifoWriteDoneFifo.enq(b.tag);
      if (wsCtrl.first)
	 ctrl.write(b.addr, wdata.data);
      else begin
	 requests[ws.first].enq(wdata.data);
	 // this used to be where we triggered putFailed
      end
   endrule

   FIFO#(MemData#(dataWidth)) rvFifo <- mkFIFO;
   rule rvrule;
	 let v = 0;
      let b <- fifoReadAddrGenerator.addrBeat.get();
      if (rsCtrl.first) begin
	 let vr <- ctrl.read(b.addr);
         v = vr;
      end
      else begin
	 if (b.addr == 4)
	    v = extend(pack(requests[rs.first].notFull()));
      end
      rvFifo.enq(MemData { data: v, tag: b.tag, last: b.last });
      //$display("mkMemMethodMux.readData aw=%d rs=%d data=%h", valueOf(aw), rs.first, rv.data);
      if (b.last) begin
	 rs.deq();
	 rsCtrl.deq();
      end
   endrule

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
				       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
				       });
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.writeReq len=%d \n\n ****", req.burstLen);
	    //$display("mkMemMethodMux.writeReq addr=%h selWidth=%d aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(selWidth), valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    ws.enq(truncate(psel(req.addr)));
            wsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    writeDataFifo.enq(wdata);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(MemTagSize)) get();
	    let rv <- toGet(doneFifo).get();
	    return rv;
	 endmethod
      endinterface
   endinterface
   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
				       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	       });
	    //$display("mkMemMethodMux.readReq addr=%h aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.readReq len=%d \n\n ****", req.burstLen);
	    rs.enq(truncate(psel(req.addr)));
            rsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv <- toGet(rvFifo).get();
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule

module mkMemMethodMuxOut#(PortalCtrl#(aw,dataWidth) ctrl, Vector#(numIndications, PipeOut#(Bit#(dataWidth))) indications)(PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    , Add#(a__, TLog#(numIndications), selWidth)
            , Add#(1, b__, dataWidth)
      );
   AddressGenerator#(aw,dataWidth) fifoReadAddrGenerator <- mkAddressGenerator();
   AddressGenerator#(aw,dataWidth) fifoWriteAddrGenerator <- mkAddressGenerator();
   FIFO#(Bit#(MemTagSize))                fifoWriteDoneFifo <- mkFIFO();
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TSub#(addrWidth,1));
   function Bit#(selWidth) psel(Bit#(addrWidth) a);
      Bit#(selWidth) v = a[port_sel_high:port_sel_low];
      return v - 1;
   endfunction
   function Bool pselCtrl(Bit#(addrWidth) a);
      Bit#(selWidth) v = a[port_sel_high:port_sel_low];
      return v == 0;
   endfunction
   function Bit#(aw) asel(Bit#(addrWidth) a);
      return a[(port_sel_low-1):0];
   endfunction

   FIFO#(Bit#(MemTagSize)) doneFifo          <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_ars <- mkFIFO1();
   FIFO#(Bit#(TLog#(numIndications))) rs <- mkFIFO1();
   FIFO#(Bool)                   rsCtrl <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numIndications))) ws <- mkFIFO1();
   FIFO#(Bool)                   wsCtrl <- mkFIFO1();

   rule write_done;
      let rv <- toGet(fifoWriteDoneFifo).get();
      ws.deq();
      wsCtrl.deq();
      doneFifo.enq(rv);
   endrule

   rule req_aw;
      let req <- toGet(req_aws).get;
      fifoWriteAddrGenerator.request.put(req);
   endrule

   rule req_ar;
      let req <- toGet(req_ars).get;
      fifoReadAddrGenerator.request.put(req);
   endrule

   FIFO#(MemData#(dataWidth)) rvFifo <- mkFIFO;
   rule rvrule;
      let b <- fifoReadAddrGenerator.addrBeat.get();
      let rv = MemData { data: 0, tag: b.tag, last: b.last };
      if (rsCtrl.first) begin
	 let vr <- ctrl.read(b.addr);
         rv.data = vr;
      end
      else begin
	 if (b.addr == 0)
	    rv.data <- toGet(indications[rs.first]).get();
	 else if (b.addr == 4)
	    rv.data = extend(pack(indications[rs.first].notEmpty()));
      end
      rvFifo.enq(rv);
      //$display("mkMemMethodMux.readData aw=%d rs=%d data=%h", valueOf(aw), rs.first, rv.data);
      rs.deq();
      rsCtrl.deq();
   endrule

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
	       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	       });
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.writeReq len=%d \n\n ****", req.burstLen);
	    //$display("mkMemMethodMux.writeReq addr=%h selWidth=%d aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(selWidth), valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    ws.enq(truncate(psel(req.addr)));
            wsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    //$display("mkMemMethodMux.writeData aw=%d ws=%d data=%h", valueOf(aw), ws.first, wdata.data);
	    let b <- fifoWriteAddrGenerator.addrBeat.get();
            if (wsCtrl.first)
	       ctrl.write(b.addr, wdata.data);
	       //$display("mkPipeOutMemSlave.writeData.put addr=%h data=%h", b.addr, d.data);
	       if (b.last)
	          fifoWriteDoneFifo.enq(b.tag);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(MemTagSize)) get();
	    let rv <- toGet(doneFifo).get();
	    return rv;
	 endmethod
      endinterface
   endinterface
   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
	       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	       });
	    //$display("mkMemMethodMux.readReq addr=%h aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.readReq len=%d \n\n ****", req.burstLen);
	    rs.enq(truncate(psel(req.addr)));
            rsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv <- toGet(rvFifo).get();
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule

module mkMemPortalMux#(Vector#(numSlaves,PhysMemSlave#(aw,dataWidth)) slaves) (PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    ,Add#(a__, TLog#(numSlaves), selWidth)
	    ,Min#(4,TLog#(numSlaves),bpc)
	    ,Pipe::FunnelPipesPipelined#(1, numSlaves, MemTypes::MemData#(dataWidth),bpc)
	    );
   let port_sel_low = valueOf(aw);
   let port_sel_high = valueOf(TSub#(addrWidth,1));
   function Bit#(selWidth) psel(Bit#(addrWidth) a);
      return a[port_sel_high:port_sel_low];
   endfunction
   function Bit#(aw) asel(Bit#(addrWidth) a);
      return a[(port_sel_low-1):0];
   endfunction
   function Get#(MemData#(dataWidth)) getMemPortalReadData(PhysMemSlave#(aw,dataWidth) x) = x.read_server.readData;
   function Put#(MemData#(dataWidth)) getMemPortalWriteData(PhysMemSlave#(aw,dataWidth) x) = x.write_server.writeData;
   
   FIFO#(Bit#(MemTagSize))        doneFifo <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_ars <- mkSizedFIFO(1);
   FIFO#(Bit#(TLog#(numSlaves))) rs <- mkFIFO1();
   Vector#(numSlaves, PipeOut#(MemData#(dataWidth))) readDataPipes <- mapM(mkPipeOut, map(getMemPortalReadData,slaves));
   FunnelPipe#(1, numSlaves, MemData#(dataWidth), bpc) read_data_funnel <- mkFunnelPipesPipelined(readDataPipes);
      
   FIFO#(PhysMemRequest#(aw,dataWidth)) req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) ws <- mkFIFO1();
   FIFOF#(Tuple2#(Bit#(TLog#(numSlaves)), MemData#(dataWidth))) write_data <- mkFIFOF;
   UnFunnelPipe#(1, numSlaves, MemData#(dataWidth), bpc) write_data_unfunnel <- mkUnFunnelPipesPipelined(cons(toPipeOut(write_data),nil));
   Vector#(numSlaves, PipeIn#(MemData#(dataWidth))) writeDataPipes <- mapM(mkPipeIn, map(getMemPortalWriteData,slaves));
   zipWithM(mkConnection, write_data_unfunnel, writeDataPipes);
   let verbose = False;
 
   rule req_aw;
      let req <- toGet(req_aws).get;
      slaves[ws.first].write_server.writeReq.put(req);
   endrule
         
   rule req_ar;
      let req <- toGet(req_ars).get;
      slaves[rs.first].read_server.readReq.put(req);
   endrule
   
   rule write_done_rule;
      let rv <- slaves[ws.first].write_server.writeDone.get();
      ws.deq();
      doneFifo.enq(rv);
   endrule

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
	       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	       });
	    if (req.burstLen > 4) $display("**** \n\n mkMemPortalMux.writeReq len=%d \n\n ****", req.burstLen);
	    ws.enq(truncate(psel(req.addr)));
	    if(verbose) $display("mkMemPortalMux.writeReq addr=%h aw=%d psel=%h", req.addr, valueOf(aw), psel(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    write_data.enq(tuple2(ws.first,wdata));
	    if(verbose) $display("mkMemPortalMux.writeData dst=%h wdata=%h", ws.first,wdata);
	 endmethod
      endinterface
      interface Get writeDone;
	 method ActionValue#(Bit#(MemTagSize)) get();
	    let rv <- toGet(doneFifo).get();
	    return rv;
	 endmethod
      endinterface
   endinterface
   interface PhysMemReadServer read_server;
      interface Put readReq;
	 method Action put(PhysMemRequest#(addrWidth,dataWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag
`ifdef BYTE_ENABLES
				       , firstbe: req.firstbe, lastbe: req.lastbe
`endif
	       });
	    rs.enq(truncate(psel(req.addr)));
	    if (req.burstLen > 4) $display("**** \n\n mkMemPortalMux.readReq len=%d \n\n ****", req.burstLen);
	    if(verbose) $display("mkMemPortalMux.readReq addr=%h aw=%d psel=%h", req.addr, valueOf(aw), psel(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv <- toGet(read_data_funnel[0]).get;
	    rs.deq();
	    if(verbose) $display("mkMemPortalMux.readData rs=%d data=%h", rs.first, rv.data);
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule

module mkSlaveMux#(Vector#(numPortals,MemPortal#(aw,dataWidth)) portals) (PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    ,Add#(a__, TLog#(numPortals), selWidth)
	    ,FunnelPipesPipelined#(1, numPortals, MemData#(dataWidth),TMin#(4, TLog#(numPortals)))
	    );
   function PhysMemSlave#(_a,_d) getSlave(MemPortal#(_a,_d) p);
      return p.slave;
   endfunction
   Vector#(numPortals, PhysMemSlave#(aw,dataWidth)) slaves = map(getSlave, portals);
   for(Integer i = 0; i < valueOf(numPortals); i=i+1)
      rule writeTop;
	 portals[i].num_portals <= fromInteger(valueOf(numPortals));
      endrule
   let rv <- mkMemPortalMux(slaves);
   return rv;
endmodule
