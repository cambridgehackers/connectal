
import GetPut::*;

import MemServerPortal::*;
import Pipe::*;
import Portal::*;
import Simple::*;
import AccelTop::*;
import QemuAccelIfc::*;
import Serial::*;


interface QemuAccel;
   interface QemuAccelRequest request;
   interface MemServerPortalRequest memServerPortalRequest;
   interface SerialRequest uartRequest;
endinterface

module mkQemuAccel#(QemuAccelIndication ind, MemServerPortalResponse memServerPortalIndication, SerialIndication uartIndication)(QemuAccel);

   let accel <- AccelTop::mkConnectalTop();
   let physMemSlavePortal <- mkPhysMemSlavePortal(accel.slave, memServerPortalIndication);

   rule rl_rx;
      let ch <- toGet(accel.pins.out).get();
      uartIndication.rx(ch);
   endrule

   interface MemServerPortalRequest memServerPortalRequest = physMemSlavePortal.request;

   interface QemuAccelRequest request;
      method Action start();
	 ind.started();
      endmethod
   endinterface
   interface SerialRequest uartRequest;
      method Action tx(Bit#(8) ch);
	 accel.pins.in.enq(ch);
      endmethod
   endinterface
endmodule

