
/*
   scripts/importbvi.py
   -o
   PPS7LIB.bsv
   -C
   PS7
   -I
   PPS7LIB
   -P
   PPS7
   -f
   DDR
   -f
   FTMT
   -f
   FTMD
   -f
   IRQ
   -f
   EMIOGPIO
   -f
   EMIOPJTAG
   -f
   EMIOTRACE
   -f
   EMIOWDT
   -f
   EVENT
   -f
   PS
   -f
   SAXIACP
   -c
   MAXIGP0ACLK
   -c
   MAXIGP1ACLK
   -c
   SAXIACPACLK
   -c
   SAXIGP0ACLK
   -c
   SAXIGP1ACLK
   -c
   SAXIHP0ACLK
   -c
   SAXIHP1ACLK
   -c
   SAXIHP2ACLK
   -c
   SAXIHP3ACLK
   -i
   PS7EXTENDED:Pps7Emiocan:Pps7Emioenet:Pps7Emiopjtag:Pps7Emiosdio:Pps7Emiospi:Pps7Emiotrace:Pps7Emiottc:Pps7Emiouart:Pps7Emiousb:Pps7Emiowdt:Pps7Dma:Pps7Ftmd:Pps7Ftmt
   --notdef
   Pps7Maxigp
   --notdef
   Pps7Saxigp
   --notdef
   Pps7Saxihp
   --notdef
   Pps7Saxiacp
   ../../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;
`include "ConnectalProjectConfig.bsv"

(* always_ready, always_enabled *)
interface Pps7Ddr;
    interface Inout#(Bit#(15))     a;
    method Action      arb(Bit#(4) v);
    interface Inout#(Bit#(3))     ba;
    interface Inout#(Bit#(1))     casb;
    interface Inout#(Bit#(1))     cke;
    interface Inout#(Bit#(1))     ckn;
    interface Inout#(Bit#(1))     ckp;
    interface Inout#(Bit#(1))     csb;
    interface Inout#(Bit#(4))     dm;
    interface Inout#(Bit#(32))     dq;
    interface Inout#(Bit#(4))     dqsn;
    interface Inout#(Bit#(4))     dqsp;
    interface Inout#(Bit#(1))     drstb;
    interface Inout#(Bit#(1))     odt;
    interface Inout#(Bit#(1))     rasb;
    interface Inout#(Bit#(1))     vrn;
    interface Inout#(Bit#(1))     vrp;
    interface Inout#(Bit#(1))     web;
endinterface
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Dma;
    method Action      aclk(Bit#(1) v);
    method Action      daready(Bit#(1) v);
    method Bit#(2)     datype();
    method Bit#(1)     davalid();
    method Action      drlast(Bit#(1) v);
    method Bit#(1)     drready();
    method Action      drtype(Bit#(2) v);
    method Action      drvalid(Bit#(1) v);
    method Bit#(1)     rstn();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiocan;
    method Action      phyrx(Bit#(1) v);
    method Bit#(1)     phytx();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emioenet;
    method Action      extintin(Bit#(1) v);
    method Action      gmiicol(Bit#(1) v);
    method Action      gmiicrs(Bit#(1) v);
    method Action      gmiirxclk(Bit#(1) v);
    method Action      gmiirxd(Bit#(8) v);
    method Action      gmiirxdv(Bit#(1) v);
    method Action      gmiirxer(Bit#(1) v);
    method Action      gmiitxclk(Bit#(1) v);
    method Bit#(8)     gmiitxd();
    method Bit#(1)     gmiitxen();
    method Bit#(1)     gmiitxer();
    method Action      mdioi(Bit#(1) v);
    method Bit#(1)     mdiomdc();
    method Bit#(1)     mdioo();
    method Bit#(1)     mdiotn();
    method Bit#(1)     ptpdelayreqrx();
    method Bit#(1)     ptpdelayreqtx();
    method Bit#(1)     ptppdelayreqrx();
    method Bit#(1)     ptppdelayreqtx();
    method Bit#(1)     ptppdelayresprx();
    method Bit#(1)     ptppdelayresptx();
    method Bit#(1)     ptpsyncframerx();
    method Bit#(1)     ptpsyncframetx();
    method Bit#(1)     sofrx();
    method Bit#(1)     softx();
endinterface
`endif
(* always_ready, always_enabled *)
interface Pps7Emiogpio;
    method Action      i(Bit#(64) v);
    method Bit#(64)     o();
    method Bit#(64)     tn();
endinterface
(* always_ready, always_enabled *)
interface Pps7Emioi2c;
    method Action      scli(Bit#(1) v);
    method Bit#(1)     sclo();
    method Bit#(1)     scltn();
    method Action      sdai(Bit#(1) v);
    method Bit#(1)     sdao();
    method Bit#(1)     sdatn();
endinterface
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiopjtag;
    method Action      tck(Bit#(1) v);
    method Action      tdi(Bit#(1) v);
    method Bit#(1)     tdo();
    method Bit#(1)     tdtn();
    method Action      tms(Bit#(1) v);
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiosdio;
    method Bit#(1)     buspow();
    method Bit#(3)     busvolt();
    method Action      cdn(Bit#(1) v);
    method Bit#(1)     clk();
    method Action      clkfb(Bit#(1) v);
    method Action      cmdi(Bit#(1) v);
    method Bit#(1)     cmdo();
    method Bit#(1)     cmdtn();
    method Action      datai(Bit#(4) v);
    method Bit#(4)     datao();
    method Bit#(4)     datatn();
    method Bit#(1)     led();
    method Action      wp(Bit#(1) v);
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiospi;
    method Action      mi(Bit#(1) v);
    method Bit#(1)     mo();
    method Bit#(1)     motn();
    method Action      sclki(Bit#(1) v);
    method Bit#(1)     sclko();
    method Bit#(1)     sclktn();
    method Action      si(Bit#(1) v);
    method Bit#(1)     so();
    method Action      ssin(Bit#(1) v);
    method Bit#(1)     ssntn();
    method Bit#(3)     sson();
    method Bit#(1)     stn();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiotrace;
    method Action      clk(Bit#(1) v);
    method Bit#(1)     ctl();
    method Bit#(32)     data();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiottc;
    method Action      clki(Bit#(3) v);
    method Bit#(3)     waveo();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiouart;
    method Action      ctsn(Bit#(1) v);
    method Action      dcdn(Bit#(1) v);
    method Action      dsrn(Bit#(1) v);
    method Bit#(1)     dtrn();
    method Action      rin(Bit#(1) v);
    method Bit#(1)     rtsn();
    method Action      rx(Bit#(1) v);
    method Bit#(1)     tx();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiousb;
    method Bit#(2)     portindctl();
    method Action      vbuspwrfault(Bit#(1) v);
    method Bit#(1)     vbuspwrselect();
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Emiowdt;
    method Action      clki(Bit#(1) v);
    method Bit#(1)     rsto();
endinterface
`endif
(* always_ready, always_enabled *)
interface Pps7Event;
    method Action      eventi(Bit#(1) v);
    method Bit#(1)     evento();
    method Bit#(2)     standbywfe();
    method Bit#(2)     standbywfi();
endinterface
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Ftmd;
    method Action      traceinatid(Bit#(4) v);
    method Action      traceinclock(Bit#(1) v);
    method Action      traceindata(Bit#(32) v);
    method Action      traceinvalid(Bit#(1) v);
endinterface
`endif
`ifdef PS7EXTENDED
(* always_ready, always_enabled *)
interface Pps7Ftmt;
    method Action      f2pdebug(Bit#(32) v);
    method Action      f2ptrig(Bit#(4) v);
    method Bit#(4)     f2ptrigack();
    method Bit#(32)     p2fdebug();
    method Bit#(4)     p2ftrig();
    method Action      p2ftrigack(Bit#(4) v);
endinterface
`endif
(* always_ready, always_enabled *)
interface Pps7Irq;
    method Action      f2p(Bit#(20) v);
    method Bit#(29)     p2f();
endinterface
(* always_ready, always_enabled *)
interface Pps7Ps;
    interface Inout#(Bit#(1))     clk;
    interface Inout#(Bit#(1))     porb;
    interface Inout#(Bit#(1))     srstb;
endinterface
(* always_ready, always_enabled *)
interface PPS7LIB;
    interface Pps7Ddr     ddr;
`ifdef PS7EXTENDED
    interface Pps7Dma     dma0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma2;
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma3;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiocan     emiocan0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiocan     emiocan1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emioenet     emioenet0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emioenet     emioenet1;
`endif
    interface Pps7Emiogpio     emiogpio;
    interface Pps7Emioi2c     emioi2c0;
    interface Pps7Emioi2c     emioi2c1;
`ifdef PS7EXTENDED
    interface Pps7Emiopjtag     emiopjtag;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiosdio     emiosdio0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiosdio     emiosdio1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiospi     emiospi0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiospi     emiospi1;
`endif
    method Action      emiosramintin(Bit#(1) v);
`ifdef PS7EXTENDED
    interface Pps7Emiotrace     emiotrace;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiottc     emiottc0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiottc     emiottc1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiouart     emiouart0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiouart     emiouart1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiousb     emiousb0;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiousb     emiousb1;
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiowdt     emiowdt;
`endif
    interface Pps7Event     event_;
    method Bit#(4)     fclkclk();
    method Action      fclkclktrign(Bit#(4) v);
    method Bit#(4)     fclkresetn();
    method Action      fpgaidlen(Bit#(1) v);
`ifdef PS7EXTENDED
    interface Pps7Ftmd     ftmd;
`endif
`ifdef PS7EXTENDED
    interface Pps7Ftmt     ftmt;
`endif
    interface Pps7Irq     irq;
    interface Pps7Maxigp     maxigp0;
    interface Pps7Maxigp     maxigp1;
    interface Inout#(Bit#(54))     mio;
    interface Pps7Ps     ps;
    interface Pps7Saxiacp     saxiacp;
    interface Pps7Saxigp     saxigp0;
    interface Pps7Saxigp     saxigp1;
    interface Pps7Saxihp     saxihp0;
    interface Pps7Saxihp     saxihp1;
    interface Pps7Saxihp     saxihp2;
    interface Pps7Saxihp     saxihp3;
endinterface
import "BVI" PS7 =
module mkPPS7LIB#(Clock maxigp0aclk, Clock maxigp1aclk, Clock saxiacpaclk, Clock saxigp0aclk, Clock saxigp1aclk, Clock saxihp0aclk, Clock saxihp1aclk, Clock saxihp2aclk, Clock saxihp3aclk, Reset maxigp0aclk_reset, Reset maxigp1aclk_reset, Reset saxiacpaclk_reset, Reset saxigp0aclk_reset, Reset saxigp1aclk_reset, Reset saxihp0aclk_reset, Reset saxihp1aclk_reset, Reset saxihp2aclk_reset, Reset saxihp3aclk_reset)(PPS7LIB);
    default_clock clk();
    default_reset rst();
        input_clock maxigp0aclk(MAXIGP0ACLK) = maxigp0aclk;
        input_reset maxigp0aclk_reset() = maxigp0aclk_reset; /* from clock*/
        input_clock maxigp1aclk(MAXIGP1ACLK) = maxigp1aclk;
        input_reset maxigp1aclk_reset() = maxigp1aclk_reset; /* from clock*/
        input_clock saxiacpaclk(SAXIACPACLK) = saxiacpaclk;
        input_reset saxiacpaclk_reset() = saxiacpaclk_reset; /* from clock*/
        input_clock saxigp0aclk(SAXIGP0ACLK) = saxigp0aclk;
        input_reset saxigp0aclk_reset() = saxigp0aclk_reset; /* from clock*/
        input_clock saxigp1aclk(SAXIGP1ACLK) = saxigp1aclk;
        input_reset saxigp1aclk_reset() = saxigp1aclk_reset; /* from clock*/
        input_clock saxihp0aclk(SAXIHP0ACLK) = saxihp0aclk;
        input_reset saxihp0aclk_reset() = saxihp0aclk_reset; /* from clock*/
        input_clock saxihp1aclk(SAXIHP1ACLK) = saxihp1aclk;
        input_reset saxihp1aclk_reset() = saxihp1aclk_reset; /* from clock*/
        input_clock saxihp2aclk(SAXIHP2ACLK) = saxihp2aclk;
        input_reset saxihp2aclk_reset() = saxihp2aclk_reset; /* from clock*/
        input_clock saxihp3aclk(SAXIHP3ACLK) = saxihp3aclk;
        input_reset saxihp3aclk_reset() = saxihp3aclk_reset; /* from clock*/
    interface Pps7Ddr     ddr;
        ifc_inout a(DDRA);
        method arb(DDRARB) enable((*inhigh*) EN_DDRARB);
        ifc_inout ba(DDRBA);
        ifc_inout casb(DDRCASB);
        ifc_inout cke(DDRCKE);
        ifc_inout ckn(DDRCKN);
        ifc_inout ckp(DDRCKP);
        ifc_inout csb(DDRCSB);
        ifc_inout dm(DDRDM);
        ifc_inout dq(DDRDQ);
        ifc_inout dqsn(DDRDQSN);
        ifc_inout dqsp(DDRDQSP);
        ifc_inout drstb(DDRDRSTB);
        ifc_inout odt(DDRODT);
        ifc_inout rasb(DDRRASB);
        ifc_inout vrn(DDRVRN);
        ifc_inout vrp(DDRVRP);
        ifc_inout web(DDRWEB);
    endinterface
`ifdef PS7EXTENDED
    interface Pps7Dma     dma0;
        method aclk(DMA0ACLK) enable((*inhigh*) EN_DMA0ACLK);
        method daready(DMA0DAREADY) enable((*inhigh*) EN_DMA0DAREADY);
        method DMA0DATYPE datype();
        method DMA0DAVALID davalid();
        method drlast(DMA0DRLAST) enable((*inhigh*) EN_DMA0DRLAST);
        method DMA0DRREADY drready();
        method drtype(DMA0DRTYPE) enable((*inhigh*) EN_DMA0DRTYPE);
        method drvalid(DMA0DRVALID) enable((*inhigh*) EN_DMA0DRVALID);
        method DMA0RSTN rstn();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma1;
        method aclk(DMA1ACLK) enable((*inhigh*) EN_DMA1ACLK);
        method daready(DMA1DAREADY) enable((*inhigh*) EN_DMA1DAREADY);
        method DMA1DATYPE datype();
        method DMA1DAVALID davalid();
        method drlast(DMA1DRLAST) enable((*inhigh*) EN_DMA1DRLAST);
        method DMA1DRREADY drready();
        method drtype(DMA1DRTYPE) enable((*inhigh*) EN_DMA1DRTYPE);
        method drvalid(DMA1DRVALID) enable((*inhigh*) EN_DMA1DRVALID);
        method DMA1RSTN rstn();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma2;
        method aclk(DMA2ACLK) enable((*inhigh*) EN_DMA2ACLK);
        method daready(DMA2DAREADY) enable((*inhigh*) EN_DMA2DAREADY);
        method DMA2DATYPE datype();
        method DMA2DAVALID davalid();
        method drlast(DMA2DRLAST) enable((*inhigh*) EN_DMA2DRLAST);
        method DMA2DRREADY drready();
        method drtype(DMA2DRTYPE) enable((*inhigh*) EN_DMA2DRTYPE);
        method drvalid(DMA2DRVALID) enable((*inhigh*) EN_DMA2DRVALID);
        method DMA2RSTN rstn();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Dma     dma3;
        method aclk(DMA3ACLK) enable((*inhigh*) EN_DMA3ACLK);
        method daready(DMA3DAREADY) enable((*inhigh*) EN_DMA3DAREADY);
        method DMA3DATYPE datype();
        method DMA3DAVALID davalid();
        method drlast(DMA3DRLAST) enable((*inhigh*) EN_DMA3DRLAST);
        method DMA3DRREADY drready();
        method drtype(DMA3DRTYPE) enable((*inhigh*) EN_DMA3DRTYPE);
        method drvalid(DMA3DRVALID) enable((*inhigh*) EN_DMA3DRVALID);
        method DMA3RSTN rstn();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiocan     emiocan0;
        method phyrx(EMIOCAN0PHYRX) enable((*inhigh*) EN_EMIOCAN0PHYRX);
        method EMIOCAN0PHYTX phytx();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiocan     emiocan1;
        method phyrx(EMIOCAN1PHYRX) enable((*inhigh*) EN_EMIOCAN1PHYRX);
        method EMIOCAN1PHYTX phytx();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emioenet     emioenet0;
        method extintin(EMIOENET0EXTINTIN) enable((*inhigh*) EN_EMIOENET0EXTINTIN);
        method gmiicol(EMIOENET0GMIICOL) enable((*inhigh*) EN_EMIOENET0GMIICOL);
        method gmiicrs(EMIOENET0GMIICRS) enable((*inhigh*) EN_EMIOENET0GMIICRS);
        method gmiirxclk(EMIOENET0GMIIRXCLK) enable((*inhigh*) EN_EMIOENET0GMIIRXCLK);
        method gmiirxd(EMIOENET0GMIIRXD) enable((*inhigh*) EN_EMIOENET0GMIIRXD);
        method gmiirxdv(EMIOENET0GMIIRXDV) enable((*inhigh*) EN_EMIOENET0GMIIRXDV);
        method gmiirxer(EMIOENET0GMIIRXER) enable((*inhigh*) EN_EMIOENET0GMIIRXER);
        method gmiitxclk(EMIOENET0GMIITXCLK) enable((*inhigh*) EN_EMIOENET0GMIITXCLK);
        method EMIOENET0GMIITXD gmiitxd();
        method EMIOENET0GMIITXEN gmiitxen();
        method EMIOENET0GMIITXER gmiitxer();
        method mdioi(EMIOENET0MDIOI) enable((*inhigh*) EN_EMIOENET0MDIOI);
        method EMIOENET0MDIOMDC mdiomdc();
        method EMIOENET0MDIOO mdioo();
        method EMIOENET0MDIOTN mdiotn();
        method EMIOENET0PTPDELAYREQRX ptpdelayreqrx();
        method EMIOENET0PTPDELAYREQTX ptpdelayreqtx();
        method EMIOENET0PTPPDELAYREQRX ptppdelayreqrx();
        method EMIOENET0PTPPDELAYREQTX ptppdelayreqtx();
        method EMIOENET0PTPPDELAYRESPRX ptppdelayresprx();
        method EMIOENET0PTPPDELAYRESPTX ptppdelayresptx();
        method EMIOENET0PTPSYNCFRAMERX ptpsyncframerx();
        method EMIOENET0PTPSYNCFRAMETX ptpsyncframetx();
        method EMIOENET0SOFRX sofrx();
        method EMIOENET0SOFTX softx();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emioenet     emioenet1;
        method extintin(EMIOENET1EXTINTIN) enable((*inhigh*) EN_EMIOENET1EXTINTIN);
        method gmiicol(EMIOENET1GMIICOL) enable((*inhigh*) EN_EMIOENET1GMIICOL);
        method gmiicrs(EMIOENET1GMIICRS) enable((*inhigh*) EN_EMIOENET1GMIICRS);
        method gmiirxclk(EMIOENET1GMIIRXCLK) enable((*inhigh*) EN_EMIOENET1GMIIRXCLK);
        method gmiirxd(EMIOENET1GMIIRXD) enable((*inhigh*) EN_EMIOENET1GMIIRXD);
        method gmiirxdv(EMIOENET1GMIIRXDV) enable((*inhigh*) EN_EMIOENET1GMIIRXDV);
        method gmiirxer(EMIOENET1GMIIRXER) enable((*inhigh*) EN_EMIOENET1GMIIRXER);
        method gmiitxclk(EMIOENET1GMIITXCLK) enable((*inhigh*) EN_EMIOENET1GMIITXCLK);
        method EMIOENET1GMIITXD gmiitxd();
        method EMIOENET1GMIITXEN gmiitxen();
        method EMIOENET1GMIITXER gmiitxer();
        method mdioi(EMIOENET1MDIOI) enable((*inhigh*) EN_EMIOENET1MDIOI);
        method EMIOENET1MDIOMDC mdiomdc();
        method EMIOENET1MDIOO mdioo();
        method EMIOENET1MDIOTN mdiotn();
        method EMIOENET1PTPDELAYREQRX ptpdelayreqrx();
        method EMIOENET1PTPDELAYREQTX ptpdelayreqtx();
        method EMIOENET1PTPPDELAYREQRX ptppdelayreqrx();
        method EMIOENET1PTPPDELAYREQTX ptppdelayreqtx();
        method EMIOENET1PTPPDELAYRESPRX ptppdelayresprx();
        method EMIOENET1PTPPDELAYRESPTX ptppdelayresptx();
        method EMIOENET1PTPSYNCFRAMERX ptpsyncframerx();
        method EMIOENET1PTPSYNCFRAMETX ptpsyncframetx();
        method EMIOENET1SOFRX sofrx();
        method EMIOENET1SOFTX softx();
    endinterface
`endif
    interface Pps7Emiogpio     emiogpio;
        method i(EMIOGPIOI) enable((*inhigh*) EN_EMIOGPIOI);
        method EMIOGPIOO o();
        method EMIOGPIOTN tn();
    endinterface
    interface Pps7Emioi2c     emioi2c0;
        method scli(EMIOI2C0SCLI) enable((*inhigh*) EN_EMIOI2C0SCLI);
        method EMIOI2C0SCLO sclo();
        method EMIOI2C0SCLTN scltn();
        method sdai(EMIOI2C0SDAI) enable((*inhigh*) EN_EMIOI2C0SDAI);
        method EMIOI2C0SDAO sdao();
        method EMIOI2C0SDATN sdatn();
    endinterface
    interface Pps7Emioi2c     emioi2c1;
        method scli(EMIOI2C1SCLI) enable((*inhigh*) EN_EMIOI2C1SCLI);
        method EMIOI2C1SCLO sclo();
        method EMIOI2C1SCLTN scltn();
        method sdai(EMIOI2C1SDAI) enable((*inhigh*) EN_EMIOI2C1SDAI);
        method EMIOI2C1SDAO sdao();
        method EMIOI2C1SDATN sdatn();
    endinterface
`ifdef PS7EXTENDED
    interface Pps7Emiopjtag     emiopjtag;
        method tck(EMIOPJTAGTCK) enable((*inhigh*) EN_EMIOPJTAGTCK);
        method tdi(EMIOPJTAGTDI) enable((*inhigh*) EN_EMIOPJTAGTDI);
        method EMIOPJTAGTDO tdo();
        method EMIOPJTAGTDTN tdtn();
        method tms(EMIOPJTAGTMS) enable((*inhigh*) EN_EMIOPJTAGTMS);
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiosdio     emiosdio0;
        method EMIOSDIO0BUSPOW buspow();
        method EMIOSDIO0BUSVOLT busvolt();
        method cdn(EMIOSDIO0CDN) enable((*inhigh*) EN_EMIOSDIO0CDN);
        method EMIOSDIO0CLK clk();
        method clkfb(EMIOSDIO0CLKFB) enable((*inhigh*) EN_EMIOSDIO0CLKFB);
        method cmdi(EMIOSDIO0CMDI) enable((*inhigh*) EN_EMIOSDIO0CMDI);
        method EMIOSDIO0CMDO cmdo();
        method EMIOSDIO0CMDTN cmdtn();
        method datai(EMIOSDIO0DATAI) enable((*inhigh*) EN_EMIOSDIO0DATAI);
        method EMIOSDIO0DATAO datao();
        method EMIOSDIO0DATATN datatn();
        method EMIOSDIO0LED led();
        method wp(EMIOSDIO0WP) enable((*inhigh*) EN_EMIOSDIO0WP);
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiosdio     emiosdio1;
        method EMIOSDIO1BUSPOW buspow();
        method EMIOSDIO1BUSVOLT busvolt();
        method cdn(EMIOSDIO1CDN) enable((*inhigh*) EN_EMIOSDIO1CDN);
        method EMIOSDIO1CLK clk();
        method clkfb(EMIOSDIO1CLKFB) enable((*inhigh*) EN_EMIOSDIO1CLKFB);
        method cmdi(EMIOSDIO1CMDI) enable((*inhigh*) EN_EMIOSDIO1CMDI);
        method EMIOSDIO1CMDO cmdo();
        method EMIOSDIO1CMDTN cmdtn();
        method datai(EMIOSDIO1DATAI) enable((*inhigh*) EN_EMIOSDIO1DATAI);
        method EMIOSDIO1DATAO datao();
        method EMIOSDIO1DATATN datatn();
        method EMIOSDIO1LED led();
        method wp(EMIOSDIO1WP) enable((*inhigh*) EN_EMIOSDIO1WP);
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiospi     emiospi0;
        method mi(EMIOSPI0MI) enable((*inhigh*) EN_EMIOSPI0MI);
        method EMIOSPI0MO mo();
        method EMIOSPI0MOTN motn();
        method sclki(EMIOSPI0SCLKI) enable((*inhigh*) EN_EMIOSPI0SCLKI);
        method EMIOSPI0SCLKO sclko();
        method EMIOSPI0SCLKTN sclktn();
        method si(EMIOSPI0SI) enable((*inhigh*) EN_EMIOSPI0SI);
        method EMIOSPI0SO so();
        method ssin(EMIOSPI0SSIN) enable((*inhigh*) EN_EMIOSPI0SSIN);
        method EMIOSPI0SSNTN ssntn();
        method EMIOSPI0SSON sson();
        method EMIOSPI0STN stn();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiospi     emiospi1;
        method mi(EMIOSPI1MI) enable((*inhigh*) EN_EMIOSPI1MI);
        method EMIOSPI1MO mo();
        method EMIOSPI1MOTN motn();
        method sclki(EMIOSPI1SCLKI) enable((*inhigh*) EN_EMIOSPI1SCLKI);
        method EMIOSPI1SCLKO sclko();
        method EMIOSPI1SCLKTN sclktn();
        method si(EMIOSPI1SI) enable((*inhigh*) EN_EMIOSPI1SI);
        method EMIOSPI1SO so();
        method ssin(EMIOSPI1SSIN) enable((*inhigh*) EN_EMIOSPI1SSIN);
        method EMIOSPI1SSNTN ssntn();
        method EMIOSPI1SSON sson();
        method EMIOSPI1STN stn();
    endinterface
`endif
    method emiosramintin(EMIOSRAMINTIN) enable((*inhigh*) EN_EMIOSRAMINTIN);
`ifdef PS7EXTENDED
    interface Pps7Emiotrace     emiotrace;
        method clk(EMIOTRACECLK) enable((*inhigh*) EN_EMIOTRACECLK);
        method EMIOTRACECTL ctl();
        method EMIOTRACEDATA data();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiottc     emiottc0;
        method clki(EMIOTTC0CLKI) enable((*inhigh*) EN_EMIOTTC0CLKI);
        method EMIOTTC0WAVEO waveo();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiottc     emiottc1;
        method clki(EMIOTTC1CLKI) enable((*inhigh*) EN_EMIOTTC1CLKI);
        method EMIOTTC1WAVEO waveo();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiouart     emiouart0;
        method ctsn(EMIOUART0CTSN) enable((*inhigh*) EN_EMIOUART0CTSN);
        method dcdn(EMIOUART0DCDN) enable((*inhigh*) EN_EMIOUART0DCDN);
        method dsrn(EMIOUART0DSRN) enable((*inhigh*) EN_EMIOUART0DSRN);
        method EMIOUART0DTRN dtrn();
        method rin(EMIOUART0RIN) enable((*inhigh*) EN_EMIOUART0RIN);
        method EMIOUART0RTSN rtsn();
        method rx(EMIOUART0RX) enable((*inhigh*) EN_EMIOUART0RX);
        method EMIOUART0TX tx();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiouart     emiouart1;
        method ctsn(EMIOUART1CTSN) enable((*inhigh*) EN_EMIOUART1CTSN);
        method dcdn(EMIOUART1DCDN) enable((*inhigh*) EN_EMIOUART1DCDN);
        method dsrn(EMIOUART1DSRN) enable((*inhigh*) EN_EMIOUART1DSRN);
        method EMIOUART1DTRN dtrn();
        method rin(EMIOUART1RIN) enable((*inhigh*) EN_EMIOUART1RIN);
        method EMIOUART1RTSN rtsn();
        method rx(EMIOUART1RX) enable((*inhigh*) EN_EMIOUART1RX);
        method EMIOUART1TX tx();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiousb     emiousb0;
        method EMIOUSB0PORTINDCTL portindctl();
        method vbuspwrfault(EMIOUSB0VBUSPWRFAULT) enable((*inhigh*) EN_EMIOUSB0VBUSPWRFAULT);
        method EMIOUSB0VBUSPWRSELECT vbuspwrselect();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiousb     emiousb1;
        method EMIOUSB1PORTINDCTL portindctl();
        method vbuspwrfault(EMIOUSB1VBUSPWRFAULT) enable((*inhigh*) EN_EMIOUSB1VBUSPWRFAULT);
        method EMIOUSB1VBUSPWRSELECT vbuspwrselect();
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Emiowdt     emiowdt;
        method clki(EMIOWDTCLKI) enable((*inhigh*) EN_EMIOWDTCLKI);
        method EMIOWDTRSTO rsto();
    endinterface
`endif
    interface Pps7Event     event_;
        method eventi(EVENTEVENTI) enable((*inhigh*) EN_EVENTEVENTI);
        method EVENTEVENTO evento();
        method EVENTSTANDBYWFE standbywfe();
        method EVENTSTANDBYWFI standbywfi();
    endinterface
    method FCLKCLK fclkclk();
    method fclkclktrign(FCLKCLKTRIGN) enable((*inhigh*) EN_FCLKCLKTRIGN);
    method FCLKRESETN fclkresetn();
    method fpgaidlen(FPGAIDLEN) enable((*inhigh*) EN_FPGAIDLEN);
`ifdef PS7EXTENDED
    interface Pps7Ftmd     ftmd;
        method traceinatid(FTMDTRACEINATID) enable((*inhigh*) EN_FTMDTRACEINATID);
        method traceinclock(FTMDTRACEINCLOCK) enable((*inhigh*) EN_FTMDTRACEINCLOCK);
        method traceindata(FTMDTRACEINDATA) enable((*inhigh*) EN_FTMDTRACEINDATA);
        method traceinvalid(FTMDTRACEINVALID) enable((*inhigh*) EN_FTMDTRACEINVALID);
    endinterface
`endif
`ifdef PS7EXTENDED
    interface Pps7Ftmt     ftmt;
        method f2pdebug(FTMTF2PDEBUG) enable((*inhigh*) EN_FTMTF2PDEBUG);
        method f2ptrig(FTMTF2PTRIG) enable((*inhigh*) EN_FTMTF2PTRIG);
        method FTMTF2PTRIGACK f2ptrigack();
        method FTMTP2FDEBUG p2fdebug();
        method FTMTP2FTRIG p2ftrig();
        method p2ftrigack(FTMTP2FTRIGACK) enable((*inhigh*) EN_FTMTP2FTRIGACK);
    endinterface
`endif
    interface Pps7Irq     irq;
        method f2p(IRQF2P) enable((*inhigh*) EN_IRQF2P);
        method IRQP2F p2f();
    endinterface
    interface Pps7Maxigp     maxigp0;
        method MAXIGP0ARADDR araddr() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARBURST arburst() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARCACHE arcache() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARESETN aresetn() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARID arid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARLEN arlen() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARLOCK arlock() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARPROT arprot() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARQOS arqos() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method arready(MAXIGP0ARREADY) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0ARREADY);
        method MAXIGP0ARSIZE arsize() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0ARVALID arvalid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWADDR awaddr() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWBURST awburst() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWCACHE awcache() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWID awid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWLEN awlen() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWLOCK awlock() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWPROT awprot() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWQOS awqos() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method awready(MAXIGP0AWREADY) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0AWREADY);
        method MAXIGP0AWSIZE awsize() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0AWVALID awvalid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method bid(MAXIGP0BID) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0BID);
        method MAXIGP0BREADY bready() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method bresp(MAXIGP0BRESP) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0BRESP);
        method bvalid(MAXIGP0BVALID) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0BVALID);
        method rdata(MAXIGP0RDATA) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0RDATA);
        method rid(MAXIGP0RID) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0RID);
        method rlast(MAXIGP0RLAST) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0RLAST);
        method MAXIGP0RREADY rready() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method rresp(MAXIGP0RRESP) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0RRESP);
        method rvalid(MAXIGP0RVALID) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0RVALID);
        method MAXIGP0WDATA wdata() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0WID wid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0WLAST wlast() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method wready(MAXIGP0WREADY) clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset) enable((*inhigh*) EN_MAXIGP0WREADY);
        method MAXIGP0WSTRB wstrb() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
        method MAXIGP0WVALID wvalid() clocked_by (maxigp0aclk) reset_by (maxigp0aclk_reset);
    endinterface
    interface Pps7Maxigp     maxigp1;
        method MAXIGP1ARADDR araddr() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARBURST arburst() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARCACHE arcache() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARESETN aresetn() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARID arid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARLEN arlen() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARLOCK arlock() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARPROT arprot() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARQOS arqos() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method arready(MAXIGP1ARREADY) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1ARREADY);
        method MAXIGP1ARSIZE arsize() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1ARVALID arvalid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWADDR awaddr() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWBURST awburst() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWCACHE awcache() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWID awid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWLEN awlen() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWLOCK awlock() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWPROT awprot() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWQOS awqos() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method awready(MAXIGP1AWREADY) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1AWREADY);
        method MAXIGP1AWSIZE awsize() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1AWVALID awvalid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method bid(MAXIGP1BID) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1BID);
        method MAXIGP1BREADY bready() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method bresp(MAXIGP1BRESP) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1BRESP);
        method bvalid(MAXIGP1BVALID) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1BVALID);
        method rdata(MAXIGP1RDATA) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1RDATA);
        method rid(MAXIGP1RID) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1RID);
        method rlast(MAXIGP1RLAST) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1RLAST);
        method MAXIGP1RREADY rready() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method rresp(MAXIGP1RRESP) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1RRESP);
        method rvalid(MAXIGP1RVALID) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1RVALID);
        method MAXIGP1WDATA wdata() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1WID wid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1WLAST wlast() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method wready(MAXIGP1WREADY) clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset) enable((*inhigh*) EN_MAXIGP1WREADY);
        method MAXIGP1WSTRB wstrb() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
        method MAXIGP1WVALID wvalid() clocked_by (maxigp1aclk) reset_by (maxigp1aclk_reset);
    endinterface
    ifc_inout mio(MIO);
    interface Pps7Ps     ps;
        ifc_inout clk(PSCLK);
        ifc_inout porb(PSPORB);
        ifc_inout srstb(PSSRSTB);
    endinterface
    interface Pps7Saxiacp     saxiacp;
        method araddr(SAXIACPARADDR) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARADDR);
        method arburst(SAXIACPARBURST) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARBURST);
        method arcache(SAXIACPARCACHE) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARCACHE);
        method SAXIACPARESETN aresetn() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method arid(SAXIACPARID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARID);
        method arlen(SAXIACPARLEN) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARLEN);
        method arlock(SAXIACPARLOCK) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARLOCK);
        method arprot(SAXIACPARPROT) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARPROT);
        method arqos(SAXIACPARQOS) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARQOS);
        method SAXIACPARREADY arready() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method arsize(SAXIACPARSIZE) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARSIZE);
        method arvalid(SAXIACPARVALID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARVALID);
        method awaddr(SAXIACPAWADDR) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWADDR);
        method awburst(SAXIACPAWBURST) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWBURST);
        method awcache(SAXIACPAWCACHE) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWCACHE);
        method awid(SAXIACPAWID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWID);
        method awlen(SAXIACPAWLEN) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWLEN);
        method awlock(SAXIACPAWLOCK) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWLOCK);
        method awprot(SAXIACPAWPROT) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWPROT);
        method awqos(SAXIACPAWQOS) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWQOS);
        method SAXIACPAWREADY awready() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method awsize(SAXIACPAWSIZE) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWSIZE);
interface ACPType extra;
        method aruser(SAXIACPARUSER) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPARUSER);
        method awuser(SAXIACPAWUSER) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWUSER);
endinterface
        method awvalid(SAXIACPAWVALID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPAWVALID);
        method SAXIACPBID bid() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method bready(SAXIACPBREADY) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPBREADY);
        method SAXIACPBRESP bresp() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method SAXIACPBVALID bvalid() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method SAXIACPRDATA rdata() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method SAXIACPRID rid() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method SAXIACPRLAST rlast() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method rready(SAXIACPRREADY) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPRREADY);
        method SAXIACPRRESP rresp() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method SAXIACPRVALID rvalid() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method wdata(SAXIACPWDATA) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPWDATA);
        method wid(SAXIACPWID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPWID);
        method wlast(SAXIACPWLAST) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPWLAST);
        method SAXIACPWREADY wready() clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset);
        method wstrb(SAXIACPWSTRB) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPWSTRB);
        method wvalid(SAXIACPWVALID) clocked_by (saxiacpaclk) reset_by (saxiacpaclk_reset) enable((*inhigh*) EN_SAXIACPWVALID);
    endinterface
    interface Pps7Saxigp     saxigp0;
        method araddr(SAXIGP0ARADDR) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARADDR);
        method arburst(SAXIGP0ARBURST) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARBURST);
        method arcache(SAXIGP0ARCACHE) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARCACHE);
        method SAXIGP0ARESETN aresetn() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method arid(SAXIGP0ARID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARID);
        method arlen(SAXIGP0ARLEN) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARLEN);
        method arlock(SAXIGP0ARLOCK) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARLOCK);
        method arprot(SAXIGP0ARPROT) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARPROT);
        method arqos(SAXIGP0ARQOS) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARQOS);
        method SAXIGP0ARREADY arready() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method arsize(SAXIGP0ARSIZE) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARSIZE);
        method arvalid(SAXIGP0ARVALID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0ARVALID);
        method awaddr(SAXIGP0AWADDR) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWADDR);
        method awburst(SAXIGP0AWBURST) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWBURST);
        method awcache(SAXIGP0AWCACHE) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWCACHE);
        method awid(SAXIGP0AWID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWID);
        method awlen(SAXIGP0AWLEN) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWLEN);
        method awlock(SAXIGP0AWLOCK) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWLOCK);
        method awprot(SAXIGP0AWPROT) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWPROT);
        method awqos(SAXIGP0AWQOS) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWQOS);
        method SAXIGP0AWREADY awready() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method awsize(SAXIGP0AWSIZE) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWSIZE);
        method awvalid(SAXIGP0AWVALID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0AWVALID);
        method SAXIGP0BID bid() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method bready(SAXIGP0BREADY) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0BREADY);
        method SAXIGP0BRESP bresp() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method SAXIGP0BVALID bvalid() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method SAXIGP0RDATA rdata() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method SAXIGP0RID rid() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method SAXIGP0RLAST rlast() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method rready(SAXIGP0RREADY) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0RREADY);
        method SAXIGP0RRESP rresp() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method SAXIGP0RVALID rvalid() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method wdata(SAXIGP0WDATA) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0WDATA);
        method wid(SAXIGP0WID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0WID);
        method wlast(SAXIGP0WLAST) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0WLAST);
        method SAXIGP0WREADY wready() clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset);
        method wstrb(SAXIGP0WSTRB) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0WSTRB);
        method wvalid(SAXIGP0WVALID) clocked_by (saxigp0aclk) reset_by (saxigp0aclk_reset) enable((*inhigh*) EN_SAXIGP0WVALID);
    endinterface
    interface Pps7Saxigp     saxigp1;
        method araddr(SAXIGP1ARADDR) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARADDR);
        method arburst(SAXIGP1ARBURST) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARBURST);
        method arcache(SAXIGP1ARCACHE) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARCACHE);
        method SAXIGP1ARESETN aresetn() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method arid(SAXIGP1ARID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARID);
        method arlen(SAXIGP1ARLEN) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARLEN);
        method arlock(SAXIGP1ARLOCK) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARLOCK);
        method arprot(SAXIGP1ARPROT) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARPROT);
        method arqos(SAXIGP1ARQOS) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARQOS);
        method SAXIGP1ARREADY arready() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method arsize(SAXIGP1ARSIZE) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARSIZE);
        method arvalid(SAXIGP1ARVALID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1ARVALID);
        method awaddr(SAXIGP1AWADDR) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWADDR);
        method awburst(SAXIGP1AWBURST) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWBURST);
        method awcache(SAXIGP1AWCACHE) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWCACHE);
        method awid(SAXIGP1AWID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWID);
        method awlen(SAXIGP1AWLEN) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWLEN);
        method awlock(SAXIGP1AWLOCK) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWLOCK);
        method awprot(SAXIGP1AWPROT) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWPROT);
        method awqos(SAXIGP1AWQOS) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWQOS);
        method SAXIGP1AWREADY awready() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method awsize(SAXIGP1AWSIZE) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWSIZE);
        method awvalid(SAXIGP1AWVALID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1AWVALID);
        method SAXIGP1BID bid() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method bready(SAXIGP1BREADY) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1BREADY);
        method SAXIGP1BRESP bresp() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method SAXIGP1BVALID bvalid() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method SAXIGP1RDATA rdata() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method SAXIGP1RID rid() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method SAXIGP1RLAST rlast() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method rready(SAXIGP1RREADY) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1RREADY);
        method SAXIGP1RRESP rresp() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method SAXIGP1RVALID rvalid() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method wdata(SAXIGP1WDATA) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1WDATA);
        method wid(SAXIGP1WID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1WID);
        method wlast(SAXIGP1WLAST) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1WLAST);
        method SAXIGP1WREADY wready() clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset);
        method wstrb(SAXIGP1WSTRB) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1WSTRB);
        method wvalid(SAXIGP1WVALID) clocked_by (saxigp1aclk) reset_by (saxigp1aclk_reset) enable((*inhigh*) EN_SAXIGP1WVALID);
    endinterface
    interface Pps7Saxihp     saxihp0;
        method araddr(SAXIHP0ARADDR) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARADDR);
        method arburst(SAXIHP0ARBURST) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARBURST);
        method arcache(SAXIHP0ARCACHE) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARCACHE);
        method SAXIHP0ARESETN aresetn() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method arid(SAXIHP0ARID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARID);
        method arlen(SAXIHP0ARLEN) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARLEN);
        method arlock(SAXIHP0ARLOCK) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARLOCK);
        method arprot(SAXIHP0ARPROT) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARPROT);
        method arqos(SAXIHP0ARQOS) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARQOS);
        method SAXIHP0ARREADY arready() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method arsize(SAXIHP0ARSIZE) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARSIZE);
        method arvalid(SAXIHP0ARVALID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0ARVALID);
        method awaddr(SAXIHP0AWADDR) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWADDR);
        method awburst(SAXIHP0AWBURST) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWBURST);
        method awcache(SAXIHP0AWCACHE) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWCACHE);
        method awid(SAXIHP0AWID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWID);
        method awlen(SAXIHP0AWLEN) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWLEN);
        method awlock(SAXIHP0AWLOCK) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWLOCK);
        method awprot(SAXIHP0AWPROT) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWPROT);
        method awqos(SAXIHP0AWQOS) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWQOS);
        method SAXIHP0AWREADY awready() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method awsize(SAXIHP0AWSIZE) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWSIZE);
        method awvalid(SAXIHP0AWVALID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0AWVALID);
        method SAXIHP0BID bid() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method bready(SAXIHP0BREADY) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0BREADY);
        method SAXIHP0BRESP bresp() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0BVALID bvalid() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0RDATA rdata() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0RID rid() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0RLAST rlast() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method rready(SAXIHP0RREADY) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0RREADY);
        method SAXIHP0RRESP rresp() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0RVALID rvalid() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
interface HPType extra;
        method rdissuecap1en(SAXIHP0RDISSUECAP1EN) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0RDISSUECAP1EN);
        method SAXIHP0RACOUNT racount() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0RCOUNT rcount() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0WACOUNT wacount() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method SAXIHP0WCOUNT wcount() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method wrissuecap1en(SAXIHP0WRISSUECAP1EN) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WRISSUECAP1EN);
endinterface
        method wdata(SAXIHP0WDATA) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WDATA);
        method wid(SAXIHP0WID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WID);
        method wlast(SAXIHP0WLAST) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WLAST);
        method SAXIHP0WREADY wready() clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset);
        method wstrb(SAXIHP0WSTRB) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WSTRB);
        method wvalid(SAXIHP0WVALID) clocked_by (saxihp0aclk) reset_by (saxihp0aclk_reset) enable((*inhigh*) EN_SAXIHP0WVALID);
    endinterface
    interface Pps7Saxihp     saxihp1;
        method araddr(SAXIHP1ARADDR) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARADDR);
        method arburst(SAXIHP1ARBURST) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARBURST);
        method arcache(SAXIHP1ARCACHE) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARCACHE);
        method SAXIHP1ARESETN aresetn() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method arid(SAXIHP1ARID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARID);
        method arlen(SAXIHP1ARLEN) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARLEN);
        method arlock(SAXIHP1ARLOCK) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARLOCK);
        method arprot(SAXIHP1ARPROT) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARPROT);
        method arqos(SAXIHP1ARQOS) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARQOS);
        method SAXIHP1ARREADY arready() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method arsize(SAXIHP1ARSIZE) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARSIZE);
        method arvalid(SAXIHP1ARVALID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1ARVALID);
        method awaddr(SAXIHP1AWADDR) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWADDR);
        method awburst(SAXIHP1AWBURST) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWBURST);
        method awcache(SAXIHP1AWCACHE) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWCACHE);
        method awid(SAXIHP1AWID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWID);
        method awlen(SAXIHP1AWLEN) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWLEN);
        method awlock(SAXIHP1AWLOCK) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWLOCK);
        method awprot(SAXIHP1AWPROT) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWPROT);
        method awqos(SAXIHP1AWQOS) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWQOS);
        method SAXIHP1AWREADY awready() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method awsize(SAXIHP1AWSIZE) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWSIZE);
        method awvalid(SAXIHP1AWVALID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1AWVALID);
        method SAXIHP1BID bid() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method bready(SAXIHP1BREADY) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1BREADY);
        method SAXIHP1BRESP bresp() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1BVALID bvalid() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1RDATA rdata() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1RID rid() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1RLAST rlast() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method rready(SAXIHP1RREADY) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1RREADY);
        method SAXIHP1RRESP rresp() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1RVALID rvalid() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
interface HPType extra;
        method rdissuecap1en(SAXIHP1RDISSUECAP1EN) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1RDISSUECAP1EN);
        method SAXIHP1RACOUNT racount() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1RCOUNT rcount() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1WACOUNT wacount() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method SAXIHP1WCOUNT wcount() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method wrissuecap1en(SAXIHP1WRISSUECAP1EN) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WRISSUECAP1EN);
endinterface
        method wdata(SAXIHP1WDATA) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WDATA);
        method wid(SAXIHP1WID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WID);
        method wlast(SAXIHP1WLAST) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WLAST);
        method SAXIHP1WREADY wready() clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset);
        method wstrb(SAXIHP1WSTRB) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WSTRB);
        method wvalid(SAXIHP1WVALID) clocked_by (saxihp1aclk) reset_by (saxihp1aclk_reset) enable((*inhigh*) EN_SAXIHP1WVALID);
    endinterface
    interface Pps7Saxihp     saxihp2;
        method araddr(SAXIHP2ARADDR) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARADDR);
        method arburst(SAXIHP2ARBURST) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARBURST);
        method arcache(SAXIHP2ARCACHE) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARCACHE);
        method SAXIHP2ARESETN aresetn() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method arid(SAXIHP2ARID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARID);
        method arlen(SAXIHP2ARLEN) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARLEN);
        method arlock(SAXIHP2ARLOCK) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARLOCK);
        method arprot(SAXIHP2ARPROT) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARPROT);
        method arqos(SAXIHP2ARQOS) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARQOS);
        method SAXIHP2ARREADY arready() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method arsize(SAXIHP2ARSIZE) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARSIZE);
        method arvalid(SAXIHP2ARVALID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2ARVALID);
        method awaddr(SAXIHP2AWADDR) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWADDR);
        method awburst(SAXIHP2AWBURST) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWBURST);
        method awcache(SAXIHP2AWCACHE) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWCACHE);
        method awid(SAXIHP2AWID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWID);
        method awlen(SAXIHP2AWLEN) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWLEN);
        method awlock(SAXIHP2AWLOCK) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWLOCK);
        method awprot(SAXIHP2AWPROT) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWPROT);
        method awqos(SAXIHP2AWQOS) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWQOS);
        method SAXIHP2AWREADY awready() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method awsize(SAXIHP2AWSIZE) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWSIZE);
        method awvalid(SAXIHP2AWVALID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2AWVALID);
        method SAXIHP2BID bid() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method bready(SAXIHP2BREADY) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2BREADY);
        method SAXIHP2BRESP bresp() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2BVALID bvalid() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2RDATA rdata() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2RID rid() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2RLAST rlast() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method rready(SAXIHP2RREADY) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2RREADY);
        method SAXIHP2RRESP rresp() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2RVALID rvalid() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
interface HPType extra;
        method rdissuecap1en(SAXIHP2RDISSUECAP1EN) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2RDISSUECAP1EN);
        method SAXIHP2RACOUNT racount() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2RCOUNT rcount() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2WACOUNT wacount() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method SAXIHP2WCOUNT wcount() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method wrissuecap1en(SAXIHP2WRISSUECAP1EN) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WRISSUECAP1EN);
endinterface
        method wdata(SAXIHP2WDATA) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WDATA);
        method wid(SAXIHP2WID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WID);
        method wlast(SAXIHP2WLAST) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WLAST);
        method SAXIHP2WREADY wready() clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset);
        method wstrb(SAXIHP2WSTRB) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WSTRB);
        method wvalid(SAXIHP2WVALID) clocked_by (saxihp2aclk) reset_by (saxihp2aclk_reset) enable((*inhigh*) EN_SAXIHP2WVALID);
    endinterface
    interface Pps7Saxihp     saxihp3;
        method araddr(SAXIHP3ARADDR) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARADDR);
        method arburst(SAXIHP3ARBURST) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARBURST);
        method arcache(SAXIHP3ARCACHE) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARCACHE);
        method SAXIHP3ARESETN aresetn() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method arid(SAXIHP3ARID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARID);
        method arlen(SAXIHP3ARLEN) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARLEN);
        method arlock(SAXIHP3ARLOCK) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARLOCK);
        method arprot(SAXIHP3ARPROT) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARPROT);
        method arqos(SAXIHP3ARQOS) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARQOS);
        method SAXIHP3ARREADY arready() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method arsize(SAXIHP3ARSIZE) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARSIZE);
        method arvalid(SAXIHP3ARVALID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3ARVALID);
        method awaddr(SAXIHP3AWADDR) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWADDR);
        method awburst(SAXIHP3AWBURST) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWBURST);
        method awcache(SAXIHP3AWCACHE) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWCACHE);
        method awid(SAXIHP3AWID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWID);
        method awlen(SAXIHP3AWLEN) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWLEN);
        method awlock(SAXIHP3AWLOCK) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWLOCK);
        method awprot(SAXIHP3AWPROT) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWPROT);
        method awqos(SAXIHP3AWQOS) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWQOS);
        method SAXIHP3AWREADY awready() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method awsize(SAXIHP3AWSIZE) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWSIZE);
        method awvalid(SAXIHP3AWVALID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3AWVALID);
        method SAXIHP3BID bid() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method bready(SAXIHP3BREADY) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3BREADY);
        method SAXIHP3BRESP bresp() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3BVALID bvalid() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3RDATA rdata() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3RID rid() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3RLAST rlast() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method rready(SAXIHP3RREADY) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3RREADY);
        method SAXIHP3RRESP rresp() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3RVALID rvalid() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
interface HPType extra;
        method rdissuecap1en(SAXIHP3RDISSUECAP1EN) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3RDISSUECAP1EN);
        method SAXIHP3RACOUNT racount() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3RCOUNT rcount() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3WACOUNT wacount() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method SAXIHP3WCOUNT wcount() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method wrissuecap1en(SAXIHP3WRISSUECAP1EN) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WRISSUECAP1EN);
endinterface
        method wdata(SAXIHP3WDATA) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WDATA);
        method wid(SAXIHP3WID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WID);
        method wlast(SAXIHP3WLAST) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WLAST);
        method SAXIHP3WREADY wready() clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset);
        method wstrb(SAXIHP3WSTRB) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WSTRB);
        method wvalid(SAXIHP3WVALID) clocked_by (saxihp3aclk) reset_by (saxihp3aclk_reset) enable((*inhigh*) EN_SAXIHP3WVALID);
    endinterface
`ifdef PS7EXTENDED
    schedule (
ddr.arb, emiogpio.i, emiogpio.o, emiogpio.tn, emioi2c0.scli, emioi2c0.sclo, emioi2c0.scltn, emioi2c0.sdai, emioi2c0.sdao, emioi2c0.sdatn, emioi2c1.scli, emioi2c1.sclo, emioi2c1.scltn, emioi2c1.sdai, emioi2c1.sdao, emioi2c1.sdatn, emiosramintin, event_.eventi, event_.evento, event_.standbywfe, event_.standbywfi, fclkclk, fclkclktrign, fclkresetn, fpgaidlen, irq.f2p, irq.p2f, maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.aresetn, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wid, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp1.araddr, maxigp1.arburst, maxigp1.arcache, maxigp1.aresetn, maxigp1.arid, maxigp1.arlen, maxigp1.arlock, maxigp1.arprot, maxigp1.arqos, maxigp1.arready, maxigp1.arsize, maxigp1.arvalid, maxigp1.awaddr, maxigp1.awburst, maxigp1.awcache, maxigp1.awid, maxigp1.awlen, maxigp1.awlock, maxigp1.awprot, maxigp1.awqos, maxigp1.awready, maxigp1.awsize, maxigp1.awvalid, maxigp1.bid, maxigp1.bready, maxigp1.bresp, maxigp1.bvalid, maxigp1.rdata, maxigp1.rid, maxigp1.rlast, maxigp1.rready, maxigp1.rresp, maxigp1.rvalid, maxigp1.wdata, maxigp1.wid, maxigp1.wlast, maxigp1.wready, maxigp1.wstrb, maxigp1.wvalid, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.aresetn, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.extra.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.extra.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wid, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.aresetn, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wid, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid, saxigp1.araddr, saxigp1.arburst, saxigp1.arcache, saxigp1.aresetn, saxigp1.arid, saxigp1.arlen, saxigp1.arlock, saxigp1.arprot, saxigp1.arqos, saxigp1.arready, saxigp1.arsize, saxigp1.arvalid, saxigp1.awaddr, saxigp1.awburst, saxigp1.awcache, saxigp1.awid, saxigp1.awlen, saxigp1.awlock, saxigp1.awprot, saxigp1.awqos, saxigp1.awready, saxigp1.awsize, saxigp1.awvalid, saxigp1.bid, saxigp1.bready, saxigp1.bresp, saxigp1.bvalid, saxigp1.rdata, saxigp1.rid, saxigp1.rlast, saxigp1.rready, saxigp1.rresp, saxigp1.rvalid, saxigp1.wdata, saxigp1.wid, saxigp1.wlast, saxigp1.wready, saxigp1.wstrb, saxigp1.wvalid, saxihp0.araddr, saxihp0.arburst, saxihp0.arcache, saxihp0.aresetn, saxihp0.arid, saxihp0.arlen, saxihp0.arlock, saxihp0.arprot, saxihp0.arqos, saxihp0.arready, saxihp0.arsize, saxihp0.arvalid, saxihp0.awaddr, saxihp0.awburst, saxihp0.awcache, saxihp0.awid, saxihp0.awlen, saxihp0.awlock, saxihp0.awprot, saxihp0.awqos, saxihp0.awready, saxihp0.awsize, saxihp0.awvalid, saxihp0.bid, saxihp0.bready, saxihp0.bresp, saxihp0.bvalid, saxihp0.extra.racount, saxihp0.extra.rcount, saxihp0.rdata, saxihp0.extra.rdissuecap1en, saxihp0.rid, saxihp0.rlast, saxihp0.rready, saxihp0.rresp, saxihp0.rvalid, saxihp0.extra.wacount, saxihp0.extra.wcount, saxihp0.wdata, saxihp0.wid, saxihp0.wlast, saxihp0.wready, saxihp0.extra.wrissuecap1en, saxihp0.wstrb, saxihp0.wvalid, saxihp1.araddr, saxihp1.arburst, saxihp1.arcache, saxihp1.aresetn, saxihp1.arid, saxihp1.arlen, saxihp1.arlock, saxihp1.arprot, saxihp1.arqos, saxihp1.arready, saxihp1.arsize, saxihp1.arvalid, saxihp1.awaddr, saxihp1.awburst, saxihp1.awcache, saxihp1.awid, saxihp1.awlen, saxihp1.awlock, saxihp1.awprot, saxihp1.awqos, saxihp1.awready, saxihp1.awsize, saxihp1.awvalid, saxihp1.bid, saxihp1.bready, saxihp1.bresp, saxihp1.bvalid, saxihp1.extra.racount, saxihp1.extra.rcount, saxihp1.rdata, saxihp1.extra.rdissuecap1en, saxihp1.rid, saxihp1.rlast, saxihp1.rready, saxihp1.rresp, saxihp1.rvalid, saxihp1.extra.wacount, saxihp1.extra.wcount, saxihp1.wdata, saxihp1.wid, saxihp1.wlast, saxihp1.wready, saxihp1.extra.wrissuecap1en, saxihp1.wstrb, saxihp1.wvalid, saxihp2.araddr, saxihp2.arburst, saxihp2.arcache, saxihp2.aresetn, saxihp2.arid, saxihp2.arlen, saxihp2.arlock, saxihp2.arprot, saxihp2.arqos, saxihp2.arready, saxihp2.arsize, saxihp2.arvalid, saxihp2.awaddr, saxihp2.awburst, saxihp2.awcache, saxihp2.awid, saxihp2.awlen, saxihp2.awlock, saxihp2.awprot, saxihp2.awqos, saxihp2.awready, saxihp2.awsize, saxihp2.awvalid, saxihp2.bid, saxihp2.bready, saxihp2.bresp, saxihp2.bvalid, saxihp2.extra.racount, saxihp2.extra.rcount, saxihp2.rdata, saxihp2.extra.rdissuecap1en, saxihp2.rid, saxihp2.rlast, saxihp2.rready, saxihp2.rresp, saxihp2.rvalid, saxihp2.extra.wacount, saxihp2.extra.wcount, saxihp2.wdata, saxihp2.wid, saxihp2.wlast, saxihp2.wready, saxihp2.extra.wrissuecap1en, saxihp2.wstrb, saxihp2.wvalid, saxihp3.araddr, saxihp3.arburst, saxihp3.arcache, saxihp3.aresetn, saxihp3.arid, saxihp3.arlen, saxihp3.arlock, saxihp3.arprot, saxihp3.arqos, saxihp3.arready, saxihp3.arsize, saxihp3.arvalid, saxihp3.awaddr, saxihp3.awburst, saxihp3.awcache, saxihp3.awid, saxihp3.awlen, saxihp3.awlock, saxihp3.awprot, saxihp3.awqos, saxihp3.awready, saxihp3.awsize, saxihp3.awvalid, saxihp3.bid, saxihp3.bready, saxihp3.bresp, saxihp3.bvalid, saxihp3.extra.racount, saxihp3.extra.rcount, saxihp3.rdata, saxihp3.extra.rdissuecap1en, saxihp3.rid, saxihp3.rlast, saxihp3.rready, saxihp3.rresp, saxihp3.rvalid, saxihp3.extra.wacount, saxihp3.extra.wcount, saxihp3.wdata, saxihp3.wid, saxihp3.wlast, saxihp3.wready, saxihp3.extra.wrissuecap1en, saxihp3.wstrb, saxihp3.wvalid, dma0.aclk, dma0.daready, dma0.datype, dma0.davalid, dma0.drlast, dma0.drready, dma0.drtype, dma0.drvalid, dma0.rstn, dma1.aclk, dma1.daready, dma1.datype, dma1.davalid, dma1.drlast, dma1.drready, dma1.drtype, dma1.drvalid, dma1.rstn, dma2.aclk, dma2.daready, dma2.datype, dma2.davalid, dma2.drlast, dma2.drready, dma2.drtype, dma2.drvalid, dma2.rstn, dma3.aclk, dma3.daready, dma3.datype, dma3.davalid, dma3.drlast, dma3.drready, dma3.drtype, dma3.drvalid, dma3.rstn, emiocan0.phyrx, emiocan0.phytx, emiocan1.phyrx, emiocan1.phytx, emioenet0.extintin, emioenet0.gmiicol, emioenet0.gmiicrs, emioenet0.gmiirxclk, emioenet0.gmiirxd, emioenet0.gmiirxdv, emioenet0.gmiirxer, emioenet0.gmiitxclk, emioenet0.gmiitxd, emioenet0.gmiitxen, emioenet0.gmiitxer, emioenet0.mdioi, emioenet0.mdiomdc, emioenet0.mdioo, emioenet0.mdiotn, emioenet0.ptpdelayreqrx, emioenet0.ptpdelayreqtx, emioenet0.ptppdelayreqrx, emioenet0.ptppdelayreqtx, emioenet0.ptppdelayresprx, emioenet0.ptppdelayresptx, emioenet0.ptpsyncframerx, emioenet0.ptpsyncframetx, emioenet0.sofrx, emioenet0.softx, emioenet1.extintin, emioenet1.gmiicol, emioenet1.gmiicrs, emioenet1.gmiirxclk, emioenet1.gmiirxd, emioenet1.gmiirxdv, emioenet1.gmiirxer, emioenet1.gmiitxclk, emioenet1.gmiitxd, emioenet1.gmiitxen, emioenet1.gmiitxer, emioenet1.mdioi, emioenet1.mdiomdc, emioenet1.mdioo, emioenet1.mdiotn, emioenet1.ptpdelayreqrx, emioenet1.ptpdelayreqtx, emioenet1.ptppdelayreqrx, emioenet1.ptppdelayreqtx, emioenet1.ptppdelayresprx, emioenet1.ptppdelayresptx, emioenet1.ptpsyncframerx, emioenet1.ptpsyncframetx, emioenet1.sofrx, emioenet1.softx, emiopjtag.tck, emiopjtag.tdi, emiopjtag.tdo, emiopjtag.tdtn, emiopjtag.tms, emiosdio0.buspow, emiosdio0.busvolt, emiosdio0.cdn, emiosdio0.clk, emiosdio0.clkfb, emiosdio0.cmdi, emiosdio0.cmdo, emiosdio0.cmdtn, emiosdio0.datai, emiosdio0.datao, emiosdio0.datatn, emiosdio0.led, emiosdio0.wp, emiosdio1.buspow, emiosdio1.busvolt, emiosdio1.cdn, emiosdio1.clk, emiosdio1.clkfb, emiosdio1.cmdi, emiosdio1.cmdo, emiosdio1.cmdtn, emiosdio1.datai, emiosdio1.datao, emiosdio1.datatn, emiosdio1.led, emiosdio1.wp, emiospi0.mi, emiospi0.mo, emiospi0.motn, emiospi0.sclki, emiospi0.sclko, emiospi0.sclktn, emiospi0.si, emiospi0.so, emiospi0.ssin, emiospi0.ssntn, emiospi0.sson, emiospi0.stn, emiospi1.mi, emiospi1.mo, emiospi1.motn, emiospi1.sclki, emiospi1.sclko, emiospi1.sclktn, emiospi1.si, emiospi1.so, emiospi1.ssin, emiospi1.ssntn, emiospi1.sson, emiospi1.stn, emiotrace.clk, emiotrace.ctl, emiotrace.data, emiottc0.clki, emiottc0.waveo, emiottc1.clki, emiottc1.waveo, emiouart0.ctsn, emiouart0.dcdn, emiouart0.dsrn, emiouart0.dtrn, emiouart0.rin, emiouart0.rtsn, emiouart0.rx, emiouart0.tx, emiouart1.ctsn, emiouart1.dcdn, emiouart1.dsrn, emiouart1.dtrn, emiouart1.rin, emiouart1.rtsn, emiouart1.rx, emiouart1.tx, emiousb0.portindctl, emiousb0.vbuspwrfault, emiousb0.vbuspwrselect, emiousb1.portindctl, emiousb1.vbuspwrfault, emiousb1.vbuspwrselect, emiowdt.clki, emiowdt.rsto, ftmd.traceinatid, ftmd.traceinclock, ftmd.traceindata, ftmd.traceinvalid, ftmt.f2pdebug, ftmt.f2ptrig, ftmt.f2ptrigack, ftmt.p2fdebug, ftmt.p2ftrig, ftmt.p2ftrigack
) CF (
ddr.arb, emiogpio.i, emiogpio.o, emiogpio.tn, emioi2c0.scli, emioi2c0.sclo, emioi2c0.scltn, emioi2c0.sdai, emioi2c0.sdao, emioi2c0.sdatn, emioi2c1.scli, emioi2c1.sclo, emioi2c1.scltn, emioi2c1.sdai, emioi2c1.sdao, emioi2c1.sdatn, emiosramintin, event_.eventi, event_.evento, event_.standbywfe, event_.standbywfi, fclkclk, fclkclktrign, fclkresetn, fpgaidlen, irq.f2p, irq.p2f, maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.aresetn, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wid, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp1.araddr, maxigp1.arburst, maxigp1.arcache, maxigp1.aresetn, maxigp1.arid, maxigp1.arlen, maxigp1.arlock, maxigp1.arprot, maxigp1.arqos, maxigp1.arready, maxigp1.arsize, maxigp1.arvalid, maxigp1.awaddr, maxigp1.awburst, maxigp1.awcache, maxigp1.awid, maxigp1.awlen, maxigp1.awlock, maxigp1.awprot, maxigp1.awqos, maxigp1.awready, maxigp1.awsize, maxigp1.awvalid, maxigp1.bid, maxigp1.bready, maxigp1.bresp, maxigp1.bvalid, maxigp1.rdata, maxigp1.rid, maxigp1.rlast, maxigp1.rready, maxigp1.rresp, maxigp1.rvalid, maxigp1.wdata, maxigp1.wid, maxigp1.wlast, maxigp1.wready, maxigp1.wstrb, maxigp1.wvalid, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.aresetn, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.extra.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.extra.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wid, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.aresetn, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wid, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid, saxigp1.araddr, saxigp1.arburst, saxigp1.arcache, saxigp1.aresetn, saxigp1.arid, saxigp1.arlen, saxigp1.arlock, saxigp1.arprot, saxigp1.arqos, saxigp1.arready, saxigp1.arsize, saxigp1.arvalid, saxigp1.awaddr, saxigp1.awburst, saxigp1.awcache, saxigp1.awid, saxigp1.awlen, saxigp1.awlock, saxigp1.awprot, saxigp1.awqos, saxigp1.awready, saxigp1.awsize, saxigp1.awvalid, saxigp1.bid, saxigp1.bready, saxigp1.bresp, saxigp1.bvalid, saxigp1.rdata, saxigp1.rid, saxigp1.rlast, saxigp1.rready, saxigp1.rresp, saxigp1.rvalid, saxigp1.wdata, saxigp1.wid, saxigp1.wlast, saxigp1.wready, saxigp1.wstrb, saxigp1.wvalid, saxihp0.araddr, saxihp0.arburst, saxihp0.arcache, saxihp0.aresetn, saxihp0.arid, saxihp0.arlen, saxihp0.arlock, saxihp0.arprot, saxihp0.arqos, saxihp0.arready, saxihp0.arsize, saxihp0.arvalid, saxihp0.awaddr, saxihp0.awburst, saxihp0.awcache, saxihp0.awid, saxihp0.awlen, saxihp0.awlock, saxihp0.awprot, saxihp0.awqos, saxihp0.awready, saxihp0.awsize, saxihp0.awvalid, saxihp0.bid, saxihp0.bready, saxihp0.bresp, saxihp0.bvalid, saxihp0.extra.racount, saxihp0.extra.rcount, saxihp0.rdata, saxihp0.extra.rdissuecap1en, saxihp0.rid, saxihp0.rlast, saxihp0.rready, saxihp0.rresp, saxihp0.rvalid, saxihp0.extra.wacount, saxihp0.extra.wcount, saxihp0.wdata, saxihp0.wid, saxihp0.wlast, saxihp0.wready, saxihp0.extra.wrissuecap1en, saxihp0.wstrb, saxihp0.wvalid, saxihp1.araddr, saxihp1.arburst, saxihp1.arcache, saxihp1.aresetn, saxihp1.arid, saxihp1.arlen, saxihp1.arlock, saxihp1.arprot, saxihp1.arqos, saxihp1.arready, saxihp1.arsize, saxihp1.arvalid, saxihp1.awaddr, saxihp1.awburst, saxihp1.awcache, saxihp1.awid, saxihp1.awlen, saxihp1.awlock, saxihp1.awprot, saxihp1.awqos, saxihp1.awready, saxihp1.awsize, saxihp1.awvalid, saxihp1.bid, saxihp1.bready, saxihp1.bresp, saxihp1.bvalid, saxihp1.extra.racount, saxihp1.extra.rcount, saxihp1.rdata, saxihp1.extra.rdissuecap1en, saxihp1.rid, saxihp1.rlast, saxihp1.rready, saxihp1.rresp, saxihp1.rvalid, saxihp1.extra.wacount, saxihp1.extra.wcount, saxihp1.wdata, saxihp1.wid, saxihp1.wlast, saxihp1.wready, saxihp1.extra.wrissuecap1en, saxihp1.wstrb, saxihp1.wvalid, saxihp2.araddr, saxihp2.arburst, saxihp2.arcache, saxihp2.aresetn, saxihp2.arid, saxihp2.arlen, saxihp2.arlock, saxihp2.arprot, saxihp2.arqos, saxihp2.arready, saxihp2.arsize, saxihp2.arvalid, saxihp2.awaddr, saxihp2.awburst, saxihp2.awcache, saxihp2.awid, saxihp2.awlen, saxihp2.awlock, saxihp2.awprot, saxihp2.awqos, saxihp2.awready, saxihp2.awsize, saxihp2.awvalid, saxihp2.bid, saxihp2.bready, saxihp2.bresp, saxihp2.bvalid, saxihp2.extra.racount, saxihp2.extra.rcount, saxihp2.rdata, saxihp2.extra.rdissuecap1en, saxihp2.rid, saxihp2.rlast, saxihp2.rready, saxihp2.rresp, saxihp2.rvalid, saxihp2.extra.wacount, saxihp2.extra.wcount, saxihp2.wdata, saxihp2.wid, saxihp2.wlast, saxihp2.wready, saxihp2.extra.wrissuecap1en, saxihp2.wstrb, saxihp2.wvalid, saxihp3.araddr, saxihp3.arburst, saxihp3.arcache, saxihp3.aresetn, saxihp3.arid, saxihp3.arlen, saxihp3.arlock, saxihp3.arprot, saxihp3.arqos, saxihp3.arready, saxihp3.arsize, saxihp3.arvalid, saxihp3.awaddr, saxihp3.awburst, saxihp3.awcache, saxihp3.awid, saxihp3.awlen, saxihp3.awlock, saxihp3.awprot, saxihp3.awqos, saxihp3.awready, saxihp3.awsize, saxihp3.awvalid, saxihp3.bid, saxihp3.bready, saxihp3.bresp, saxihp3.bvalid, saxihp3.extra.racount, saxihp3.extra.rcount, saxihp3.rdata, saxihp3.extra.rdissuecap1en, saxihp3.rid, saxihp3.rlast, saxihp3.rready, saxihp3.rresp, saxihp3.rvalid, saxihp3.extra.wacount, saxihp3.extra.wcount, saxihp3.wdata, saxihp3.wid, saxihp3.wlast, saxihp3.wready, saxihp3.extra.wrissuecap1en, saxihp3.wstrb, saxihp3.wvalid, dma0.aclk, dma0.daready, dma0.datype, dma0.davalid, dma0.drlast, dma0.drready, dma0.drtype, dma0.drvalid, dma0.rstn, dma1.aclk, dma1.daready, dma1.datype, dma1.davalid, dma1.drlast, dma1.drready, dma1.drtype, dma1.drvalid, dma1.rstn, dma2.aclk, dma2.daready, dma2.datype, dma2.davalid, dma2.drlast, dma2.drready, dma2.drtype, dma2.drvalid, dma2.rstn, dma3.aclk, dma3.daready, dma3.datype, dma3.davalid, dma3.drlast, dma3.drready, dma3.drtype, dma3.drvalid, dma3.rstn, emiocan0.phyrx, emiocan0.phytx, emiocan1.phyrx, emiocan1.phytx, emioenet0.extintin, emioenet0.gmiicol, emioenet0.gmiicrs, emioenet0.gmiirxclk, emioenet0.gmiirxd, emioenet0.gmiirxdv, emioenet0.gmiirxer, emioenet0.gmiitxclk, emioenet0.gmiitxd, emioenet0.gmiitxen, emioenet0.gmiitxer, emioenet0.mdioi, emioenet0.mdiomdc, emioenet0.mdioo, emioenet0.mdiotn, emioenet0.ptpdelayreqrx, emioenet0.ptpdelayreqtx, emioenet0.ptppdelayreqrx, emioenet0.ptppdelayreqtx, emioenet0.ptppdelayresprx, emioenet0.ptppdelayresptx, emioenet0.ptpsyncframerx, emioenet0.ptpsyncframetx, emioenet0.sofrx, emioenet0.softx, emioenet1.extintin, emioenet1.gmiicol, emioenet1.gmiicrs, emioenet1.gmiirxclk, emioenet1.gmiirxd, emioenet1.gmiirxdv, emioenet1.gmiirxer, emioenet1.gmiitxclk, emioenet1.gmiitxd, emioenet1.gmiitxen, emioenet1.gmiitxer, emioenet1.mdioi, emioenet1.mdiomdc, emioenet1.mdioo, emioenet1.mdiotn, emioenet1.ptpdelayreqrx, emioenet1.ptpdelayreqtx, emioenet1.ptppdelayreqrx, emioenet1.ptppdelayreqtx, emioenet1.ptppdelayresprx, emioenet1.ptppdelayresptx, emioenet1.ptpsyncframerx, emioenet1.ptpsyncframetx, emioenet1.sofrx, emioenet1.softx, emiopjtag.tck, emiopjtag.tdi, emiopjtag.tdo, emiopjtag.tdtn, emiopjtag.tms, emiosdio0.buspow, emiosdio0.busvolt, emiosdio0.cdn, emiosdio0.clk, emiosdio0.clkfb, emiosdio0.cmdi, emiosdio0.cmdo, emiosdio0.cmdtn, emiosdio0.datai, emiosdio0.datao, emiosdio0.datatn, emiosdio0.led, emiosdio0.wp, emiosdio1.buspow, emiosdio1.busvolt, emiosdio1.cdn, emiosdio1.clk, emiosdio1.clkfb, emiosdio1.cmdi, emiosdio1.cmdo, emiosdio1.cmdtn, emiosdio1.datai, emiosdio1.datao, emiosdio1.datatn, emiosdio1.led, emiosdio1.wp, emiospi0.mi, emiospi0.mo, emiospi0.motn, emiospi0.sclki, emiospi0.sclko, emiospi0.sclktn, emiospi0.si, emiospi0.so, emiospi0.ssin, emiospi0.ssntn, emiospi0.sson, emiospi0.stn, emiospi1.mi, emiospi1.mo, emiospi1.motn, emiospi1.sclki, emiospi1.sclko, emiospi1.sclktn, emiospi1.si, emiospi1.so, emiospi1.ssin, emiospi1.ssntn, emiospi1.sson, emiospi1.stn, emiotrace.clk, emiotrace.ctl, emiotrace.data, emiottc0.clki, emiottc0.waveo, emiottc1.clki, emiottc1.waveo, emiouart0.ctsn, emiouart0.dcdn, emiouart0.dsrn, emiouart0.dtrn, emiouart0.rin, emiouart0.rtsn, emiouart0.rx, emiouart0.tx, emiouart1.ctsn, emiouart1.dcdn, emiouart1.dsrn, emiouart1.dtrn, emiouart1.rin, emiouart1.rtsn, emiouart1.rx, emiouart1.tx, emiousb0.portindctl, emiousb0.vbuspwrfault, emiousb0.vbuspwrselect, emiousb1.portindctl, emiousb1.vbuspwrfault, emiousb1.vbuspwrselect, emiowdt.clki, emiowdt.rsto, ftmd.traceinatid, ftmd.traceinclock, ftmd.traceindata, ftmd.traceinvalid, ftmt.f2pdebug, ftmt.f2ptrig, ftmt.f2ptrigack, ftmt.p2fdebug, ftmt.p2ftrig, ftmt.p2ftrigack
);
`else
    schedule (
ddr.arb, emiogpio.i, emiogpio.o, emiogpio.tn, emioi2c0.scli, emioi2c0.sclo, emioi2c0.scltn, emioi2c0.sdai, emioi2c0.sdao, emioi2c0.sdatn, emioi2c1.scli, emioi2c1.sclo, emioi2c1.scltn, emioi2c1.sdai, emioi2c1.sdao, emioi2c1.sdatn, emiosramintin, event_.eventi, event_.evento, event_.standbywfe, event_.standbywfi, fclkclk, fclkclktrign, fclkresetn, fpgaidlen, irq.f2p, irq.p2f, maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.aresetn, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wid, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp1.araddr, maxigp1.arburst, maxigp1.arcache, maxigp1.aresetn, maxigp1.arid, maxigp1.arlen, maxigp1.arlock, maxigp1.arprot, maxigp1.arqos, maxigp1.arready, maxigp1.arsize, maxigp1.arvalid, maxigp1.awaddr, maxigp1.awburst, maxigp1.awcache, maxigp1.awid, maxigp1.awlen, maxigp1.awlock, maxigp1.awprot, maxigp1.awqos, maxigp1.awready, maxigp1.awsize, maxigp1.awvalid, maxigp1.bid, maxigp1.bready, maxigp1.bresp, maxigp1.bvalid, maxigp1.rdata, maxigp1.rid, maxigp1.rlast, maxigp1.rready, maxigp1.rresp, maxigp1.rvalid, maxigp1.wdata, maxigp1.wid, maxigp1.wlast, maxigp1.wready, maxigp1.wstrb, maxigp1.wvalid, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.aresetn, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.extra.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.extra.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wid, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.aresetn, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wid, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid, saxigp1.araddr, saxigp1.arburst, saxigp1.arcache, saxigp1.aresetn, saxigp1.arid, saxigp1.arlen, saxigp1.arlock, saxigp1.arprot, saxigp1.arqos, saxigp1.arready, saxigp1.arsize, saxigp1.arvalid, saxigp1.awaddr, saxigp1.awburst, saxigp1.awcache, saxigp1.awid, saxigp1.awlen, saxigp1.awlock, saxigp1.awprot, saxigp1.awqos, saxigp1.awready, saxigp1.awsize, saxigp1.awvalid, saxigp1.bid, saxigp1.bready, saxigp1.bresp, saxigp1.bvalid, saxigp1.rdata, saxigp1.rid, saxigp1.rlast, saxigp1.rready, saxigp1.rresp, saxigp1.rvalid, saxigp1.wdata, saxigp1.wid, saxigp1.wlast, saxigp1.wready, saxigp1.wstrb, saxigp1.wvalid, saxihp0.araddr, saxihp0.arburst, saxihp0.arcache, saxihp0.aresetn, saxihp0.arid, saxihp0.arlen, saxihp0.arlock, saxihp0.arprot, saxihp0.arqos, saxihp0.arready, saxihp0.arsize, saxihp0.arvalid, saxihp0.awaddr, saxihp0.awburst, saxihp0.awcache, saxihp0.awid, saxihp0.awlen, saxihp0.awlock, saxihp0.awprot, saxihp0.awqos, saxihp0.awready, saxihp0.awsize, saxihp0.awvalid, saxihp0.bid, saxihp0.bready, saxihp0.bresp, saxihp0.bvalid, saxihp0.extra.racount, saxihp0.extra.rcount, saxihp0.rdata, saxihp0.extra.rdissuecap1en, saxihp0.rid, saxihp0.rlast, saxihp0.rready, saxihp0.rresp, saxihp0.rvalid, saxihp0.extra.wacount, saxihp0.extra.wcount, saxihp0.wdata, saxihp0.wid, saxihp0.wlast, saxihp0.wready, saxihp0.extra.wrissuecap1en, saxihp0.wstrb, saxihp0.wvalid, saxihp1.araddr, saxihp1.arburst, saxihp1.arcache, saxihp1.aresetn, saxihp1.arid, saxihp1.arlen, saxihp1.arlock, saxihp1.arprot, saxihp1.arqos, saxihp1.arready, saxihp1.arsize, saxihp1.arvalid, saxihp1.awaddr, saxihp1.awburst, saxihp1.awcache, saxihp1.awid, saxihp1.awlen, saxihp1.awlock, saxihp1.awprot, saxihp1.awqos, saxihp1.awready, saxihp1.awsize, saxihp1.awvalid, saxihp1.bid, saxihp1.bready, saxihp1.bresp, saxihp1.bvalid, saxihp1.extra.racount, saxihp1.extra.rcount, saxihp1.rdata, saxihp1.extra.rdissuecap1en, saxihp1.rid, saxihp1.rlast, saxihp1.rready, saxihp1.rresp, saxihp1.rvalid, saxihp1.extra.wacount, saxihp1.extra.wcount, saxihp1.wdata, saxihp1.wid, saxihp1.wlast, saxihp1.wready, saxihp1.extra.wrissuecap1en, saxihp1.wstrb, saxihp1.wvalid, saxihp2.araddr, saxihp2.arburst, saxihp2.arcache, saxihp2.aresetn, saxihp2.arid, saxihp2.arlen, saxihp2.arlock, saxihp2.arprot, saxihp2.arqos, saxihp2.arready, saxihp2.arsize, saxihp2.arvalid, saxihp2.awaddr, saxihp2.awburst, saxihp2.awcache, saxihp2.awid, saxihp2.awlen, saxihp2.awlock, saxihp2.awprot, saxihp2.awqos, saxihp2.awready, saxihp2.awsize, saxihp2.awvalid, saxihp2.bid, saxihp2.bready, saxihp2.bresp, saxihp2.bvalid, saxihp2.extra.racount, saxihp2.extra.rcount, saxihp2.rdata, saxihp2.extra.rdissuecap1en, saxihp2.rid, saxihp2.rlast, saxihp2.rready, saxihp2.rresp, saxihp2.rvalid, saxihp2.extra.wacount, saxihp2.extra.wcount, saxihp2.wdata, saxihp2.wid, saxihp2.wlast, saxihp2.wready, saxihp2.extra.wrissuecap1en, saxihp2.wstrb, saxihp2.wvalid, saxihp3.araddr, saxihp3.arburst, saxihp3.arcache, saxihp3.aresetn, saxihp3.arid, saxihp3.arlen, saxihp3.arlock, saxihp3.arprot, saxihp3.arqos, saxihp3.arready, saxihp3.arsize, saxihp3.arvalid, saxihp3.awaddr, saxihp3.awburst, saxihp3.awcache, saxihp3.awid, saxihp3.awlen, saxihp3.awlock, saxihp3.awprot, saxihp3.awqos, saxihp3.awready, saxihp3.awsize, saxihp3.awvalid, saxihp3.bid, saxihp3.bready, saxihp3.bresp, saxihp3.bvalid, saxihp3.extra.racount, saxihp3.extra.rcount, saxihp3.rdata, saxihp3.extra.rdissuecap1en, saxihp3.rid, saxihp3.rlast, saxihp3.rready, saxihp3.rresp, saxihp3.rvalid, saxihp3.extra.wacount, saxihp3.extra.wcount, saxihp3.wdata, saxihp3.wid, saxihp3.wlast, saxihp3.wready, saxihp3.extra.wrissuecap1en, saxihp3.wstrb, saxihp3.wvalid
) CF (
ddr.arb, emiogpio.i, emiogpio.o, emiogpio.tn, emioi2c0.scli, emioi2c0.sclo, emioi2c0.scltn, emioi2c0.sdai, emioi2c0.sdao, emioi2c0.sdatn, emioi2c1.scli, emioi2c1.sclo, emioi2c1.scltn, emioi2c1.sdai, emioi2c1.sdao, emioi2c1.sdatn, emiosramintin, event_.eventi, event_.evento, event_.standbywfe, event_.standbywfi, fclkclk, fclkclktrign, fclkresetn, fpgaidlen, irq.f2p, irq.p2f, maxigp0.araddr, maxigp0.arburst, maxigp0.arcache, maxigp0.aresetn, maxigp0.arid, maxigp0.arlen, maxigp0.arlock, maxigp0.arprot, maxigp0.arqos, maxigp0.arready, maxigp0.arsize, maxigp0.arvalid, maxigp0.awaddr, maxigp0.awburst, maxigp0.awcache, maxigp0.awid, maxigp0.awlen, maxigp0.awlock, maxigp0.awprot, maxigp0.awqos, maxigp0.awready, maxigp0.awsize, maxigp0.awvalid, maxigp0.bid, maxigp0.bready, maxigp0.bresp, maxigp0.bvalid, maxigp0.rdata, maxigp0.rid, maxigp0.rlast, maxigp0.rready, maxigp0.rresp, maxigp0.rvalid, maxigp0.wdata, maxigp0.wid, maxigp0.wlast, maxigp0.wready, maxigp0.wstrb, maxigp0.wvalid, maxigp1.araddr, maxigp1.arburst, maxigp1.arcache, maxigp1.aresetn, maxigp1.arid, maxigp1.arlen, maxigp1.arlock, maxigp1.arprot, maxigp1.arqos, maxigp1.arready, maxigp1.arsize, maxigp1.arvalid, maxigp1.awaddr, maxigp1.awburst, maxigp1.awcache, maxigp1.awid, maxigp1.awlen, maxigp1.awlock, maxigp1.awprot, maxigp1.awqos, maxigp1.awready, maxigp1.awsize, maxigp1.awvalid, maxigp1.bid, maxigp1.bready, maxigp1.bresp, maxigp1.bvalid, maxigp1.rdata, maxigp1.rid, maxigp1.rlast, maxigp1.rready, maxigp1.rresp, maxigp1.rvalid, maxigp1.wdata, maxigp1.wid, maxigp1.wlast, maxigp1.wready, maxigp1.wstrb, maxigp1.wvalid, saxiacp.araddr, saxiacp.arburst, saxiacp.arcache, saxiacp.aresetn, saxiacp.arid, saxiacp.arlen, saxiacp.arlock, saxiacp.arprot, saxiacp.arqos, saxiacp.arready, saxiacp.arsize, saxiacp.extra.aruser, saxiacp.arvalid, saxiacp.awaddr, saxiacp.awburst, saxiacp.awcache, saxiacp.awid, saxiacp.awlen, saxiacp.awlock, saxiacp.awprot, saxiacp.awqos, saxiacp.awready, saxiacp.awsize, saxiacp.extra.awuser, saxiacp.awvalid, saxiacp.bid, saxiacp.bready, saxiacp.bresp, saxiacp.bvalid, saxiacp.rdata, saxiacp.rid, saxiacp.rlast, saxiacp.rready, saxiacp.rresp, saxiacp.rvalid, saxiacp.wdata, saxiacp.wid, saxiacp.wlast, saxiacp.wready, saxiacp.wstrb, saxiacp.wvalid, saxigp0.araddr, saxigp0.arburst, saxigp0.arcache, saxigp0.aresetn, saxigp0.arid, saxigp0.arlen, saxigp0.arlock, saxigp0.arprot, saxigp0.arqos, saxigp0.arready, saxigp0.arsize, saxigp0.arvalid, saxigp0.awaddr, saxigp0.awburst, saxigp0.awcache, saxigp0.awid, saxigp0.awlen, saxigp0.awlock, saxigp0.awprot, saxigp0.awqos, saxigp0.awready, saxigp0.awsize, saxigp0.awvalid, saxigp0.bid, saxigp0.bready, saxigp0.bresp, saxigp0.bvalid, saxigp0.rdata, saxigp0.rid, saxigp0.rlast, saxigp0.rready, saxigp0.rresp, saxigp0.rvalid, saxigp0.wdata, saxigp0.wid, saxigp0.wlast, saxigp0.wready, saxigp0.wstrb, saxigp0.wvalid, saxigp1.araddr, saxigp1.arburst, saxigp1.arcache, saxigp1.aresetn, saxigp1.arid, saxigp1.arlen, saxigp1.arlock, saxigp1.arprot, saxigp1.arqos, saxigp1.arready, saxigp1.arsize, saxigp1.arvalid, saxigp1.awaddr, saxigp1.awburst, saxigp1.awcache, saxigp1.awid, saxigp1.awlen, saxigp1.awlock, saxigp1.awprot, saxigp1.awqos, saxigp1.awready, saxigp1.awsize, saxigp1.awvalid, saxigp1.bid, saxigp1.bready, saxigp1.bresp, saxigp1.bvalid, saxigp1.rdata, saxigp1.rid, saxigp1.rlast, saxigp1.rready, saxigp1.rresp, saxigp1.rvalid, saxigp1.wdata, saxigp1.wid, saxigp1.wlast, saxigp1.wready, saxigp1.wstrb, saxigp1.wvalid, saxihp0.araddr, saxihp0.arburst, saxihp0.arcache, saxihp0.aresetn, saxihp0.arid, saxihp0.arlen, saxihp0.arlock, saxihp0.arprot, saxihp0.arqos, saxihp0.arready, saxihp0.arsize, saxihp0.arvalid, saxihp0.awaddr, saxihp0.awburst, saxihp0.awcache, saxihp0.awid, saxihp0.awlen, saxihp0.awlock, saxihp0.awprot, saxihp0.awqos, saxihp0.awready, saxihp0.awsize, saxihp0.awvalid, saxihp0.bid, saxihp0.bready, saxihp0.bresp, saxihp0.bvalid, saxihp0.extra.racount, saxihp0.extra.rcount, saxihp0.rdata, saxihp0.extra.rdissuecap1en, saxihp0.rid, saxihp0.rlast, saxihp0.rready, saxihp0.rresp, saxihp0.rvalid, saxihp0.extra.wacount, saxihp0.extra.wcount, saxihp0.wdata, saxihp0.wid, saxihp0.wlast, saxihp0.wready, saxihp0.extra.wrissuecap1en, saxihp0.wstrb, saxihp0.wvalid, saxihp1.araddr, saxihp1.arburst, saxihp1.arcache, saxihp1.aresetn, saxihp1.arid, saxihp1.arlen, saxihp1.arlock, saxihp1.arprot, saxihp1.arqos, saxihp1.arready, saxihp1.arsize, saxihp1.arvalid, saxihp1.awaddr, saxihp1.awburst, saxihp1.awcache, saxihp1.awid, saxihp1.awlen, saxihp1.awlock, saxihp1.awprot, saxihp1.awqos, saxihp1.awready, saxihp1.awsize, saxihp1.awvalid, saxihp1.bid, saxihp1.bready, saxihp1.bresp, saxihp1.bvalid, saxihp1.extra.racount, saxihp1.extra.rcount, saxihp1.rdata, saxihp1.extra.rdissuecap1en, saxihp1.rid, saxihp1.rlast, saxihp1.rready, saxihp1.rresp, saxihp1.rvalid, saxihp1.extra.wacount, saxihp1.extra.wcount, saxihp1.wdata, saxihp1.wid, saxihp1.wlast, saxihp1.wready, saxihp1.extra.wrissuecap1en, saxihp1.wstrb, saxihp1.wvalid, saxihp2.araddr, saxihp2.arburst, saxihp2.arcache, saxihp2.aresetn, saxihp2.arid, saxihp2.arlen, saxihp2.arlock, saxihp2.arprot, saxihp2.arqos, saxihp2.arready, saxihp2.arsize, saxihp2.arvalid, saxihp2.awaddr, saxihp2.awburst, saxihp2.awcache, saxihp2.awid, saxihp2.awlen, saxihp2.awlock, saxihp2.awprot, saxihp2.awqos, saxihp2.awready, saxihp2.awsize, saxihp2.awvalid, saxihp2.bid, saxihp2.bready, saxihp2.bresp, saxihp2.bvalid, saxihp2.extra.racount, saxihp2.extra.rcount, saxihp2.rdata, saxihp2.extra.rdissuecap1en, saxihp2.rid, saxihp2.rlast, saxihp2.rready, saxihp2.rresp, saxihp2.rvalid, saxihp2.extra.wacount, saxihp2.extra.wcount, saxihp2.wdata, saxihp2.wid, saxihp2.wlast, saxihp2.wready, saxihp2.extra.wrissuecap1en, saxihp2.wstrb, saxihp2.wvalid, saxihp3.araddr, saxihp3.arburst, saxihp3.arcache, saxihp3.aresetn, saxihp3.arid, saxihp3.arlen, saxihp3.arlock, saxihp3.arprot, saxihp3.arqos, saxihp3.arready, saxihp3.arsize, saxihp3.arvalid, saxihp3.awaddr, saxihp3.awburst, saxihp3.awcache, saxihp3.awid, saxihp3.awlen, saxihp3.awlock, saxihp3.awprot, saxihp3.awqos, saxihp3.awready, saxihp3.awsize, saxihp3.awvalid, saxihp3.bid, saxihp3.bready, saxihp3.bresp, saxihp3.bvalid, saxihp3.extra.racount, saxihp3.extra.rcount, saxihp3.rdata, saxihp3.extra.rdissuecap1en, saxihp3.rid, saxihp3.rlast, saxihp3.rready, saxihp3.rresp, saxihp3.rvalid, saxihp3.extra.wacount, saxihp3.extra.wcount, saxihp3.wdata, saxihp3.wid, saxihp3.wlast, saxihp3.wready, saxihp3.extra.wrissuecap1en, saxihp3.wstrb, saxihp3.wvalid
);
`endif
endmodule
