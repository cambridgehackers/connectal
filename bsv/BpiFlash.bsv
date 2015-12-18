
import Vector::*;
import Clocks::*;

// interface to BPI Flash (PC28F00AG18FE)

(* always_ready, always_enabled *)
interface BpiFlashPins;
   interface Clock deleteme_unused_clock;
   interface Reset rst;
   interface Vector#(16,Inout#(Bit#(1))) data;
   method Bit#(25) addr();
   method Bit#(1) adv_b();
   method Bit#(1) ce_b();
   method Bit#(1) oe_b();
   method Bit#(1) we_b();
`ifdef BPI_HAS_WP
   method Bit#(1) wp_b();
`endif
`ifdef BPI_HAS_VPP
   method Bit#(1) vpp();
`endif
   method Action wait_in(Bit#(1) b);
endinterface

interface BpiPins;
   interface BpiFlashPins flash;
endinterface
