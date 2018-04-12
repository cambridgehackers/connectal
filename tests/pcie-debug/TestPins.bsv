import Clocks::*;

(* always_ready, always_enabled *)
interface UartPins;
   method Bit#(1) sout();
   method Action sin(Bit#(1) v);
   interface Clock deleteme_unused_clock;
endinterface
interface TestPins;
   interface UartPins uart;
endinterface
