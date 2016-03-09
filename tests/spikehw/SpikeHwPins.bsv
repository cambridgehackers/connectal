
import AxiEthBvi::*;
import BpiFlash::*;

interface EthPins;
   interface AxiethbviSfp sfp;
   interface AxiethbviMgt mgt;
endinterface

(* always_ready, always_enabled *)
interface SpikeIicPins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
`ifndef BOARD_nfsume
   method Bit#(1) gpo();
`else
   method Bit#(1) mux_reset();
`endif
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
`ifndef BOARD_nfsume
   interface BpiFlashPins flash;
`endif
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
endinterface
