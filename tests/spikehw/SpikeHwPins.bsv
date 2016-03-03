
import AxiEthBvi::*;
import BpiFlash::*;

interface EthPins;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
endinterface

(* always_ready, always_enabled *)
interface SpikeIicPins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
   method Bit#(1) gpo();
endinterface

(* always_ready, always_enabled *)
interface SpikeUartPins;
   method Bit#(1) tx;
   method Bit#(1) rts;
   method Action  rx (Bit#(1) x);
   method Action  cts(Bit#(1) x);
endinterface

(* always_ready, always_enabled *)
interface SpikeHwPins;
`ifdef IncludeEthernet
   interface EthPins eth;
`endif
   interface SpikeUartPins uart;
   interface SpikeIicPins iic;
   interface BpiFlashPins flash;
endinterface
