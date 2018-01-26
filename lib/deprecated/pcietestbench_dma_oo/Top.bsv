import Vector::*;
import FIFO::*;
import Connectable::*;
import Directory::*;
import CtrlMux::*;
import Portal::*;
import ConnectalMemTypes::*;
import PcieTestBenchIndicationProxy::*;
import PcieTestBenchRequestWrapper::*;
import PcieTestBench::*;

module mkConnectalTop(StdConnectalDmaTop#(40));

   // instantiate user portals
   PcieTestBenchIndicationProxy pcieTestBenchIndicationProxy <- mkPcieTestBenchIndicationProxy(IfcNames_TestBenchIndication);
   PcieTestBench#(40,64) pcieTestBench <- mkPcieTestBench(pcieTestBenchIndicationProxy.ifc);
   PcieTestBenchRequestWrapper pcieTestBenchRequestWrapper <- mkPcieTestBenchRequestWrapper(IfcNames_TestBenchRequest,pcieTestBench.request);
   
   Vector#(4,StdPortal) portals;
   portals[0] = pcieTestBenchRequestWrapper.portalIfc; 
   portals[1] = pcieTestBenchIndicationProxy.portalIfc;
   portals[2] = pcieTestBench.dmaConfig;
   portals[3] = pcieTestBench.dmaIndication;
   
   StdDirectory dir <- mkStdDirectory(portals);
   let ctrl_mux <- mkSlaveMux(dir,portals);
   
   interface interrupt = getInterruptVector(portals);
   interface slave = ctrl_mux;
   interface masters = pcieTestBench.masters;
endmodule : mkConnectalTop


