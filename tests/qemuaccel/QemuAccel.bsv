
import MemServerPortal::*;
import Portal::*;
import Simple::*;
import AccelTop::*;
import QemuAccelIfc::*;


interface QemuAccel;
   interface QemuAccelRequest request;
   interface MemServerPortalRequest memServerPortalRequest;
endinterface

module mkQemuAccel#(QemuAccelIndication ind, MemServerPortalIndication memServerPortalIndication)(QemuAccel);

   let accel <- AccelTop::mkConnectalTop();
   let physMemSlavePortal <- mkPhysMemSlavePortal(accel.slave, memServerPortalIndication);

   interface MemServerPortalRequest memServerPortalRequest = physMemSlavePortal.request;

   interface QemuAccelRequest request;
      method Action start();
	 ind.started();
      endmethod
   endinterface
endmodule

