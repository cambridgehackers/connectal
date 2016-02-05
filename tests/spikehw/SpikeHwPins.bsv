
import AxiEthBvi::*;
import BpiFlash::*;

interface EthPins;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
endinterface

(* always_ready, always_enabled *)
interface SpikeHwPins;
`ifdef IncludeEthernet
   interface EthPins eth;
`endif
   interface BpiFlashPins flash;
endinterface
