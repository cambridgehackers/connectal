`include "ConnectalProjectConfig.bsv"

import ConnectalConfig::*;
import Vector::*;
import BuildVector::*;
import Portal::*;
import CtrlMux::*;
import HostInterface::*;
import Connectable::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import ConnectalMemTypes::*;
import MemServer::*;
import AccelIfcNames::*;
`ifdef PinTypeInclude
import `PinTypeInclude::*;
`endif
import SerialIndication::*;
import Serial::*;
import SimpleRequest::*;
import Simple::*;
import BlockDevResponse::*;
import BlockDev::*;
import SerialRequest::*;
import SimpleRequest::*;
import BlockDevRequest::*;

interface Pins;
     interface SerialPort pins0;

    interface BlockDevClient pins1;
 endinterface


`ifndef IMPORT_HOSTIF
(* synthesize *)
`endif
module mkAccelTop
`ifdef IMPORT_HOSTIF // no synthesis boundary
      #(HostInterface host)
`else
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
       #(Clock derivedClockIn, Reset derivedResetIn)
`else
// otherwise no params
`endif
`endif
       (ConnectalTop#(Pins));
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();
`ifdef IMPORT_HOST_CLOCKS // enables synthesis boundary
   HostInterface host = (interface HostInterface;
                           interface Clock derivedClock = derivedClockIn;
                           interface Reset derivedReset = derivedResetIn;
                         endinterface);
`endif
   BlockDevRequestInput lBlockDevRequestInput <- mkBlockDevRequestInput;
   BlockDevResponseOutput lBlockDevResponseOutput <- mkBlockDevResponseOutput;
   SerialIndicationOutput lSerialIndicationOutput <- mkSerialIndicationOutput;
   SerialRequestInput lSerialRequestInput <- mkSerialRequestInput;
   SimpleRequestInput lSimpleRequestInput <- mkSimpleRequestInput;
   SimpleRequestOutput lSimpleRequestOutput <- mkSimpleRequestOutput;

   Serial lSerial <- mkSerial(lSerialIndicationOutput.ifc);

   Simple lSimple <- mkSimple(lSimpleRequestOutput.ifc);

   BlockDev lBlockDev <- mkBlockDev(lBlockDevResponseOutput.ifc);

   mkConnection(lBlockDevRequestInput.pipes, lBlockDev.request);
   mkConnection(lSerialRequestInput.pipes, lSerial.request);
   mkConnection(lSimpleRequestInput.pipes, lSimple.request);

   Vector#(6,StdPortal) portals;
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_0 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_SerialIndicationH2S)), lSerialIndicationOutput.portalIfc.intr);
   let memslave_0 <- mkMemMethodMuxOut(ctrlPort_0.memSlave,lSerialIndicationOutput.portalIfc.indications);
   portals[0] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_0;
       interface ReadOnly interrupt = ctrlPort_0.interrupt;
       interface WriteOnly num_portals = ctrlPort_0.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_1 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_SimpleRequestH2S)), lSimpleRequestOutput.portalIfc.intr);
   let memslave_1 <- mkMemMethodMuxOut(ctrlPort_1.memSlave,lSimpleRequestOutput.portalIfc.indications);
   portals[1] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_1;
       interface ReadOnly interrupt = ctrlPort_1.interrupt;
       interface WriteOnly num_portals = ctrlPort_1.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_2 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_BlockDevResponseH2S)), lBlockDevResponseOutput.portalIfc.intr);
   let memslave_2 <- mkMemMethodMuxOut(ctrlPort_2.memSlave,lBlockDevResponseOutput.portalIfc.indications);
   portals[2] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_2;
       interface ReadOnly interrupt = ctrlPort_2.interrupt;
       interface WriteOnly num_portals = ctrlPort_2.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_3 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_SerialRequestS2H)), lSerialRequestInput.portalIfc.intr);
   let memslave_3 <- mkMemMethodMuxIn(ctrlPort_3.memSlave,lSerialRequestInput.portalIfc.requests);
   portals[3] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_3;
       interface ReadOnly interrupt = ctrlPort_3.interrupt;
       interface WriteOnly num_portals = ctrlPort_3.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_4 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_SimpleRequestS2H)), lSimpleRequestInput.portalIfc.intr);
   let memslave_4 <- mkMemMethodMuxIn(ctrlPort_4.memSlave,lSimpleRequestInput.portalIfc.requests);
   portals[4] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_4;
       interface ReadOnly interrupt = ctrlPort_4.interrupt;
       interface WriteOnly num_portals = ctrlPort_4.num_portals;
       endinterface);
   PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort_5 <- mkPortalCtrlMemSlave(extend(pack(AccelIfcNames_BlockDevRequestS2H)), lBlockDevRequestInput.portalIfc.intr);
   let memslave_5 <- mkMemMethodMuxIn(ctrlPort_5.memSlave,lBlockDevRequestInput.portalIfc.requests);
   portals[5] = (interface MemPortal;
       interface PhysMemSlave slave = memslave_5;
       interface ReadOnly interrupt = ctrlPort_5.interrupt;
       interface WriteOnly num_portals = ctrlPort_5.num_portals;
       endinterface);
   let ctrl_mux <- mkSlaveMux(portals);
   Vector#(NumWriteClients,MemWriteClient#(DataBusWidth)) nullWriters = replicate(null_mem_write_client());
   Vector#(NumReadClients,MemReadClient#(DataBusWidth)) nullReaders = replicate(null_mem_read_client());
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface readers = take(nullReaders);
   interface writers = take(nullWriters);
`ifdef TOP_SOURCES_PORTAL_CLOCK
   interface portalClockSource = None;
`endif

   interface Pins pins;
      interface pins0 = lSerial.port;
      interface pins1 = lBlockDev.client;
   endinterface 
endmodule : mkAccelTop
export mkAccelTop;
export `PinTypeInclude::*;
export Pins(..);
