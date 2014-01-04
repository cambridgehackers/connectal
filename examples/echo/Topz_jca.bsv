// bsv libraries
import Clocks :: *;

// portz libraries
import Leds::*;
import Top::*;
import PS7Helper::*;
import Portal::*;

(* always_ready, always_enabled *)
interface EchoPins;
    (* prefix="" *)
    interface ZynqPins zynq;
    (* prefix="GPIO" *)
    interface LEDS                          leds;
endinterface

module mkZynqTop(EchoPins);
    Clock defaultClock <- exposeCurrentClock();
    Reset defaultReset <- exposeCurrentReset();
    let axiTop <- mkPortalTop();
    ZynqPins ps7 <- mkPS7Slave(defaultClock, defaultReset, axiTop);

    interface ZynqPins zynq = ps7;
    interface LEDS    leds = axiTop.leds;
endmodule : mkZynqTop
