
import AxiEthBvi::*;

interface EthPins;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
endinterface

(* always_ready, always_enabled *)
interface AxiEthPins;
   interface EthPins eth;
endinterface