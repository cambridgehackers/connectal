
import Vector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
import Connectable::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import MemTypes::*;
import MemServer::*;
import IfcNames::*;
import `PinTypeInclude::*;
import DmaIndication::*;
import DmaLoopback::*;
import DmaIndication::*;
import DmaLoopback::*;
import DmaRequest::*;
import DmaRequest::*;

`ifndef IMPORT_HOSTIF
(* synthesize *)
`endif
module mkConnectalTop
`ifdef IMPORT_HOSTIF // no synthesis boundary
      #(HostInterface host)
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       #(Clock derivedClockIn, Reset derivedResetIn)
`else
// otherwise no params
`endif
`endif
       (ConnectalTop);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
   HostInterface host = (interface HostInterface;
                           interface Clock derivedClock = derivedClockIn;
                           interface Reset derivedReset = derivedResetIn;
                         endinterface);
`endif
   DmaIndicationOutput lDmaIndicationOutput0 <- mkDmaIndicationOutput;
   DmaIndicationOutput lDmaIndicationOutput1 <- mkDmaIndicationOutput;
   DmaRequestInput lDmaRequestInput0 <- mkDmaRequestInput;
   DmaRequestInput lDmaRequestInput1 <- mkDmaRequestInput;

   DmaLoopback lDmaLoopback <- mkDmaLoopback(lDmaIndicationOutput0.ifc,lDmaIndicationOutput1.ifc);


   mkConnection(lDmaRequestInput0.pipes, lDmaLoopback.request0);
   mkConnection(lDmaRequestInput1.pipes, lDmaLoopback.request1);

   Vector#(4,StdPortal) portals;
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_0 <- mkPortalCtrlMemSlave(extend(pack(IfcNames_DmaIndicationH2S0)), lDmaIndicationOutput0.portalIfc.intr);
   let memslave_0 <- mkMemMethodMuxOut(ctrlPort_0.memSlave,lDmaIndicationOutput0.portalIfc.indications);
   portals[0] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_0;
       interface ReadOnly interrupt = ctrlPort_0.interrupt;
       interface WriteOnly num_portals = ctrlPort_0.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_1 <- mkPortalCtrlMemSlave(extend(pack(IfcNames_DmaIndicationH2S1)), lDmaIndicationOutput1.portalIfc.intr);
   let memslave_1 <- mkMemMethodMuxOut(ctrlPort_1.memSlave,lDmaIndicationOutput1.portalIfc.indications);
   portals[1] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_1;
       interface ReadOnly interrupt = ctrlPort_1.interrupt;
       interface WriteOnly num_portals = ctrlPort_1.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_2 <- mkPortalCtrlMemSlave(extend(pack(IfcNames_DmaRequestS2H0)), lDmaRequestInput0.portalIfc.intr);
   let memslave_2 <- mkMemMethodMuxIn(ctrlPort_2.memSlave,lDmaRequestInput0.portalIfc.requests);
   portals[2] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_2;
       interface ReadOnly interrupt = ctrlPort_2.interrupt;
       interface WriteOnly num_portals = ctrlPort_2.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_3 <- mkPortalCtrlMemSlave(extend(pack(IfcNames_DmaRequestS2H1)), lDmaRequestInput1.portalIfc.intr);
   let memslave_3 <- mkMemMethodMuxIn(ctrlPort_3.memSlave,lDmaRequestInput1.portalIfc.requests);
   portals[3] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_3;
       interface ReadOnly interrupt = ctrlPort_3.interrupt;
       interface WriteOnly num_portals = ctrlPort_3.num_portals;
       endinterface);
   let ctrl_mux <- mkSlaveMux(portals);
   Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) nullWriters = replicate(null_mem_write_client());
   Vector#(NumReadClients,MemReadClient#(DataBusWidth)) nullReaders = replicate(null_mem_read_client());
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface readers = take(append(lDmaLoopback.readClient, nullReaders));
   interface writers = take(append(lDmaLoopback.writeClient, nullWriters));

endmodule : mkConnectalTop
export mkConnectalTop;
export `PinTypeInclude::*;
