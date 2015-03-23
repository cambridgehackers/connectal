
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
import Connectable::*;

import Portal::*;
import MemTypes::*;
import Arith::*;
import Pipe::*;

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

module mkSlaveMux#(Vector#(numPortals,MemPortal#(aw,dataWidth)) portals) (PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    ,Add#(a__, TLog#(numPortals), selWidth)
	    ,FunnelPipesPipelined#(1, numPortals, MemData#(dataWidth),TMin#(2, TLog#(numPortals)))
	    );
   Vector#(numPortals, PhysMemSlave#(aw,dataWidth)) slaves = map(getSlave, portals);
   for(Integer i = 0; i < valueOf(numPortals); i=i+1)
      rule writeTop;
	 portals[i].num_portals <= fromInteger(valueOf(numPortals));
      endrule
   let rv <- mkMemPortalMux(slaves);
   return rv;
endmodule


module mkMemMethodMuxIn#(PhysMemSlave#(aw,dataWidth) ctrl, Vector#(numSlaves,PhysMemSlave#(aw,dataWidth)) portalIfcs)(PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth),
	    Add#(a__, TLog#(numSlaves), selWidth)
      );
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
   FIFO#(PhysMemRequest#(aw))   req_ars <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) rs <- mkFIFO1();
   FIFO#(Bool)                   rsCtrl <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw))   req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) ws <- mkFIFO1();
   FIFO#(Bool)                   wsCtrl <- mkFIFO1();

   rule write_done;
      let rv;
      if (wsCtrl.first)
         rv <- ctrl.write_server.writeDone.get();
      else
         rv <- portalIfcs[ws.first].write_server.writeDone.get();
      ws.deq();
      wsCtrl.deq();
      doneFifo.enq(rv);
   endrule

   rule req_aw;
      let req <- toGet(req_aws).get;
      if (wsCtrl.first)
         ctrl.write_server.writeReq.put(req);
      else
         portalIfcs[ws.first].write_server.writeReq.put(req);
   endrule

   rule req_ar;
      let req <- toGet(req_ars).get;
      if (rsCtrl.first)
         ctrl.read_server.readReq.put(req);
      else
         portalIfcs[rs.first].read_server.readReq.put(req);
   endrule

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.writeReq len=%d \n\n ****", req.burstLen);
	    //$display("mkMemMethodMux.writeReq addr=%h selWidth=%d aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(selWidth), valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    ws.enq(truncate(psel(req.addr)));
            wsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    //$display("mkMemMethodMux.writeData aw=%d ws=%d data=%h", valueOf(aw), ws.first, wdata.data);
            if (wsCtrl.first)
	       ctrl.write_server.writeData.put(wdata);
            else
	       portalIfcs[ws.first].write_server.writeData.put(wdata);
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
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    //$display("mkMemMethodMux.readReq addr=%h aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.readReq len=%d \n\n ****", req.burstLen);
	    rs.enq(truncate(psel(req.addr)));
            rsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv;
            if (rsCtrl.first)
	       rv <- ctrl.read_server.readData.get();
            else
	       rv <- portalIfcs[rs.first].read_server.readData.get();
	    //$display("mkMemMethodMux.readData aw=%d rs=%d data=%h", valueOf(aw), rs.first, rv.data);
	    rs.deq();
	    rsCtrl.deq();
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule

module mkMemMethodMuxOut#(PhysMemSlave#(aw,dataWidth) ctrl, Vector#(numSlaves,PhysMemSlave#(aw,dataWidth)) portalIfcs)(PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth),
	    Add#(a__, TLog#(numSlaves), selWidth)
      );
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
   FIFO#(PhysMemRequest#(aw))   req_ars <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) rs <- mkFIFO1();
   FIFO#(Bool)                   rsCtrl <- mkFIFO1();
   FIFO#(PhysMemRequest#(aw))   req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) ws <- mkFIFO1();
   FIFO#(Bool)                   wsCtrl <- mkFIFO1();

   rule write_done;
      let rv;
      if (wsCtrl.first)
         rv <- ctrl.write_server.writeDone.get();
      else
         rv <- portalIfcs[ws.first].write_server.writeDone.get();
      ws.deq();
      wsCtrl.deq();
      doneFifo.enq(rv);
   endrule

   rule req_aw;
      let req <- toGet(req_aws).get;
      if (wsCtrl.first)
         ctrl.write_server.writeReq.put(req);
      else
         portalIfcs[ws.first].write_server.writeReq.put(req);
   endrule

   rule req_ar;
      let req <- toGet(req_ars).get;
      if (rsCtrl.first)
         ctrl.read_server.readReq.put(req);
      else
         portalIfcs[rs.first].read_server.readReq.put(req);
   endrule

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.writeReq len=%d \n\n ****", req.burstLen);
	    //$display("mkMemMethodMux.writeReq addr=%h selWidth=%d aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(selWidth), valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    ws.enq(truncate(psel(req.addr)));
            wsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    //$display("mkMemMethodMux.writeData aw=%d ws=%d data=%h", valueOf(aw), ws.first, wdata.data);
            if (wsCtrl.first)
	       ctrl.write_server.writeData.put(wdata);
            else
	       portalIfcs[ws.first].write_server.writeData.put(wdata);
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
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    //$display("mkMemMethodMux.readReq addr=%h aw=%d psel=%h pselCtrl=%x", req.addr, valueOf(aw), psel(req.addr), pselCtrl(req.addr));
	    if (req.burstLen > 4) $display("**** \n\n mkMemMethodMux.readReq len=%d \n\n ****", req.burstLen);
	    rs.enq(truncate(psel(req.addr)));
            rsCtrl.enq(pselCtrl(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv;
            if (rsCtrl.first)
	       rv <- ctrl.read_server.readData.get();
            else
	       rv <- portalIfcs[rs.first].read_server.readData.get();
	    //$display("mkMemMethodMux.readData aw=%d rs=%d data=%h", valueOf(aw), rs.first, rv.data);
	    rs.deq();
	    rsCtrl.deq();
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule

module mkMemPortalMux#(Vector#(numSlaves,PhysMemSlave#(aw,dataWidth)) slaves) (PhysMemSlave#(addrWidth,dataWidth))
   provisos(Add#(selWidth,aw,addrWidth)
	    ,Add#(a__, TLog#(numSlaves), selWidth)
	    ,Min#(2,TLog#(numSlaves),bpc)
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
   FIFO#(PhysMemRequest#(aw)) req_ars <- mkSizedFIFO(1);
   FIFO#(Bit#(TLog#(numSlaves))) rs <- mkFIFO1();
   Vector#(numSlaves, PipeOut#(MemData#(dataWidth))) readDataPipes <- mapM(mkPipeOut, map(getMemPortalReadData,slaves));
   FunnelPipe#(1, numSlaves, MemData#(dataWidth), bpc) read_data_funnel <- mkFunnelPipesPipelined(readDataPipes);
      
   FIFO#(PhysMemRequest#(aw)) req_aws <- mkFIFO1();
   FIFO#(Bit#(TLog#(numSlaves))) ws <- mkFIFO1();
   FIFOF#(Tuple2#(Bit#(TLog#(numSlaves)), MemData#(dataWidth))) write_data <- mkFIFOF;
   UnFunnelPipe#(1, numSlaves, MemData#(dataWidth), bpc) write_data_unfunnel <- mkUnFunnelPipesPipelined(cons(toPipeOut(write_data),nil));
   Vector#(numSlaves, PipeIn#(MemData#(dataWidth))) writeDataPipes <- mapM(mkPipeIn, map(getMemPortalWriteData,slaves));
   zipWithM(mkConnection, write_data_unfunnel, writeDataPipes);
 
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
      
   let verbose = False;

   interface PhysMemWriteServer write_server;
      interface Put writeReq;
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_aws.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    if (req.burstLen > 4) $display("**** \n\n mkSlaveMux.writeReq len=%d \n\n ****", req.burstLen);
	    ws.enq(truncate(psel(req.addr)));
	    if(verbose) $display("mkSlaveMux.writeReq addr=%h aw=%d psel=%h", req.addr, valueOf(aw), psel(req.addr));
	 endmethod
      endinterface
      interface Put writeData;
	 method Action put(MemData#(dataWidth) wdata);
	    write_data.enq(tuple2(ws.first,wdata));
	    if(verbose) $display("mkSlaveMux.writeData dst=%h wdata=%h", ws.first,wdata);
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
	 method Action put(PhysMemRequest#(addrWidth) req);
	    req_ars.enq(PhysMemRequest{addr:asel(req.addr), burstLen:req.burstLen, tag:req.tag});
	    rs.enq(truncate(psel(req.addr)));
	    if (req.burstLen > 4) $display("**** \n\n mkSlaveMux.readReq len=%d \n\n ****", req.burstLen);
	    if(verbose) $display("mkSlaveMux.readReq addr=%h aw=%d psel=%h", req.addr, valueOf(aw), psel(req.addr));
	 endmethod
      endinterface
      interface Get readData;
	 method ActionValue#(MemData#(dataWidth)) get();
	    let rv <- toGet(read_data_funnel[0]).get;
	    rs.deq();
	    if(verbose) $display("mkSlaveMux.readData rs=%d data=%h", rs.first, rv.data);
	    return rv;
	 endmethod
      endinterface
   endinterface
endmodule
