
import BRAM         :: *;
import Connectable  :: *;
import GetPut       :: *;
import DefaultValue :: *;
import PCIE         :: *;
import StmtFSM      :: *;

import BlueCheck         :: *;
import CheckMPM          :: *;
import ConnectalMemTypes :: *;
import PcieToMem         :: *;
import PhysMemSlaveFromBram :: *;
import MemToPcie         :: *;

interface PcieMemCheckRequest;
   method Action startCheck(Bit#(32) numIterations);
endinterface
interface PcieMemCheckIndication;
   method Action checkFinished();
endinterface

interface PcieMemCheck;
   interface PcieMemCheckRequest request;
endinterface

module [Module] mkPcieMemCheck#(PcieMemCheckIndication ind)(PcieMemCheck);
   PcieMemChecker checker <- mkPcieMemChecker();

   interface PcieMemCheckRequest request;
      method Action startCheck(Bit#(32) numIterations);
	 checker.start(numIterations);
      endmethod
   endinterface
endmodule
