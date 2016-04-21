
`ifdef EthernetSgmii
import AxiEthBvi::*;
`else
import AxiEth1000BaseX::*;
`endif
import BpiFlash::*;

`include "ConnectalProjectConfig.bsv"

interface EthPins;
`ifdef IncludeEthernet
`ifdef EthernetSgmii
   interface AxiethbviSgmii sgmii;
`else
   interface AxiethbviSfp sfp;
`endif
   interface AxiethbviMgt mgt;
`endif
   method Bit#(1) tx_disable();
   method Action rx_los(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface SpikeIicPins;
   interface Inout#(Bit#(1)) scl;
   interface Inout#(Bit#(1)) sda;
   method Bit#(1) mux_reset();
endinterface

(* always_ready, always_enabled *)
interface SpikeSpiPins;
   interface Inout#(Bit#(1)) miso;
   interface Inout#(Bit#(1)) mosi;
   interface Inout#(Bit#(1)) sck;
   interface Inout#(Bit#(1)) ss;
endinterface

(* always_ready, always_enabled *)
interface SpikeUartPins;
`ifndef BOARD_miniitx100
   method Bit#(1) tx;
   method Action  rx (Bit#(1) x);
`endif
`ifdef UART_HAX_RTS_CTS
   method Bit#(1) rts;
   method Action  cts(Bit#(1) x);
`endif
endinterface

(* always_ready, always_enabled *)
interface SpikeHwPins;
   interface EthPins eth;
   interface SpikeUartPins uart;
   interface SpikeIicPins iic;
   interface SpikeSpiPins spi;
`ifdef IncludeFlash
   interface BpiFlashPins flash;
`endif
   interface Clock deleteme_unused_clock;
   interface Reset deleteme_unused_reset;
`ifndef BOARD_miniitx100
   interface Clock sfp_rec_clk_p;
   interface Clock sfp_rec_clk_n;
`endif
endinterface
