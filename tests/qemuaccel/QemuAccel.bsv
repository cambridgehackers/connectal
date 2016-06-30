
import GetPut::*;
import ClientServer::*;

import MemServerPortal::*;
import Pipe::*;
import Portal::*;
import Simple::*;
import AccelTop::*;
import QemuAccelIfc::*;
import BlockDev::*;
import Serial::*;


interface QemuAccel;
   interface QemuAccelRequest request;
   interface MemServerPortalRequest memServerPortalRequest;
   interface SerialRequest uartRequest;
   interface BlockDevResponse blockDevResponse;
endinterface

module mkQemuAccel#(QemuAccelIndication ind, MemServerPortalResponse memServerPortalIndication, SerialIndication uartIndication, BlockDevRequest blockDevRequest)(QemuAccel);

   let accel <- AccelTop::mkAccelTop();
   let physMemSlavePortal <- mkPhysMemSlavePortal(accel.slave, memServerPortalIndication);

   rule rl_rx;
      let ch <- toGet(accel.pins.pins0.out).get();
      uartIndication.rx(ch);
   endrule
   rule rl_blockdev;
      let req <- accel.pins.pins1.request.get();
      blockDevRequest.transfer(req.op, req.dramaddr, req.offset, req.size, req.tag);
   endrule

   interface MemServerPortalRequest memServerPortalRequest = physMemSlavePortal.request;

   interface QemuAccelRequest request;
      method Action start();
	 ind.started();
      endmethod
   endinterface
   interface SerialRequest uartRequest;
      method Action tx(Bit#(8) ch);
	 accel.pins.pins0.in.enq(ch);
      endmethod
   endinterface
   interface BlockDevResponse blockDevResponse;
      method Action transferDone(Bit#(32) tag);
	 accel.pins.pins1.response.put(tag);
      endmethod
   endinterface
endmodule

