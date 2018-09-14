
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
   method Action startCheck(Bit#(32) numIterations, Bool verbose);
endinterface
interface PcieMemCheckIndication;
   method Action checkFinished();
endinterface

interface PcieMemCheck;
   interface PcieMemCheckRequest request;
endinterface

module [Module] mkPcieMemCheck#(PcieMemCheckIndication ind)(PcieMemCheck);
   PcieMemChecker checker <- mkPcieMemChecker();

   rule rl_done;
      let done <- checker.done();
      ind.checkFinished();
   endrule

   interface PcieMemCheckRequest request;
      method Action startCheck(Bit#(32) numIterations, Bool verbose);
	 checker.start(numIterations, verbose);
      endmethod
   endinterface
endmodule
