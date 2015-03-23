import Vector::*;
import FIFO::*;
import Connectable::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import MemTypes::*;
import PcieTestBenchIndicationProxy::*;
import PcieTestBenchRequestWrapper::*;
import PcieTestBench::*;

typedef enum {PcieTestBenchIndication, PcieTestBenchRequest} IfcNames deriving (Eq,Bits);

module mkConnectalTop(StdConnectalTop#(addrWidth));
   PcieTestBenchIndicationProxy pcieTestBenchIndicationProxy <- mkPcieTestBenchIndicationProxy(PcieTestBenchIndication);
   PcieTestBenchRequest pcieTestBenchRequest <- mkPcieTestBenchRequest(pcieTestBenchIndicationProxy.ifc);
   PcieTestBenchRequestWrapper pcieTestBenchRequestWrapper <- mkPcieTestBenchRequestWrapper(PcieTestBenchRequest,pcieTestBenchRequest);
   
   Vector#(2,StdPortal) portals;
   portals[0] = pcieTestBenchRequestWrapper.portalIfc; 
   portals[1] = pcieTestBenchIndicationProxy.portalIfc;
   StdDirectory dir <- mkStdDirectory(portals);
   let ctrl_mux <- mkSlaveMux(dir,portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = nil;
endmodule : mkConnectalTop


