
/*
   scripts/importbvi.py
   -o
   PCIE_2_1.bsv
   -C
   PCIE_2_1
   -P
   PCIE
   -I
   PcieIf
   -f
   LL2
   -f
   PL2
   -f
   TL2
   -f
   PLLINK
   -f
   DBG
   -f
   DRP
   -f
   MIM
   -f
   PL
   -f
   TRN
   -f
   CFGAER
   -f
   CFGCOMMAND
   -f
   CFGDEV
   -f
   CFGPMR
   -f
   CFGDS
   -f
   CFGERR
   -f
   CFGFORCE
   -f
   CFGINTERRUPT
   -f
   CFGLINK
   -f
   CFGMGMT
   -f
   CFGMSG
   -f
   CFGPM
   -f
   CFGROOT
   -f
   CFGSUBSYS
   -f
   CFGTRANS
   -e
   C_DATA_WIDTH:64
   -e
   CFG_VEND_ID:16'h1BE7
   -e
   CFG_DEV_ID:16'hB100
   -e
   CFG_REV_ID:8'h00
   -e
   CFG_SUBSYS_VEND_ID:16'h1BE7
   -e
   CFG_SUBSYS_ID:16'hA705
   -e
   CLASS_CODE:24'h050000
   -e
   DSN_CAP_NEXTPTR:12'hffc
   -e
   LINK_CAP_ASPM_SUPPORT:0
   -e
   LINK_CAP_MAX_LINK_WIDTH:6'h8
   -e
   LINK_CAP_ASPM_OPTIONALITY:"TRUE"
   -e
   LL_REPLAY_TIMEOUT_EN:"TRUE"
   -e
   LL_REPLAY_TIMEOUT:15'h001a
   -e
   LTSSM_MAX_LINK_WIDTH:6'h8
   -e
   MSIX_CAP_PBA_OFFSET:29'ha00
   -e
   MSIX_CAP_TABLE_OFFSET:29'h800
   -e
   MSIX_CAP_TABLE_SIZE:11'h003
   -e
   MSIX_CAP_ON:"TRUE"
   -e
   PCIE_CAP_NEXTPTR:8'h9C
   -e
   PIPE_PIPELINE_STAGES:1
   -e
   PL_FAST_TRAIN:PL_FAST_TRAIN
   -e
   USER_CLK_FREQ:3
   -e
   BAR0:BAR0
   -e
   BAR1:BAR1
   -e
   BAR2:BAR2
   -e
   BAR3:BAR3
   -e
   BAR4:BAR4
   -e
   BAR5:BAR5
   ../import_components/Xilinx/Vivado/2013.2/data/parts/xilinx/zynq/zynq.lib
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;

(* always_ready, always_enabled *)
interface PcieCfgaer;
    method Bit#(1)     ecrcchecken();
    method Bit#(1)     ecrcgenen();
    method Action      interruptmsgnum(Bit#(5) v);
    method Bit#(1)     rooterrcorrerrreceived();
    method Bit#(1)     rooterrcorrerrreportingen();
    method Bit#(1)     rooterrfatalerrreceived();
    method Bit#(1)     rooterrfatalerrreportingen();
    method Bit#(1)     rooterrnonfatalerrreceived();
    method Bit#(1)     rooterrnonfatalerrreportingen();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgcommand;
    method Bit#(1)     busmasterenable();
    method Bit#(1)     interruptdisable();
    method Bit#(1)     ioenable();
    method Bit#(1)     memenable();
    method Bit#(1)     serren();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgdev;
    method Bit#(1)     control2ariforwarden();
    method Bit#(1)     control2atomicegressblock();
    method Bit#(1)     control2atomicrequesteren();
    method Bit#(1)     control2cpltimeoutdis();
    method Bit#(4)     control2cpltimeoutval();
    method Bit#(1)     control2idocplen();
    method Bit#(1)     control2idoreqen();
    method Bit#(1)     control2ltren();
    method Bit#(1)     control2tlpprefixblock();
    method Bit#(1)     controlauxpoweren();
    method Bit#(1)     controlcorrerrreportingen();
    method Bit#(1)     controlenablero();
    method Bit#(1)     controlexttagen();
    method Bit#(1)     controlfatalerrreportingen();
    method Bit#(3)     controlmaxpayload();
    method Bit#(3)     controlmaxreadreq();
    method Bit#(1)     controlnonfatalreportingen();
    method Bit#(1)     controlnosnoopen();
    method Bit#(1)     controlphantomen();
    method Bit#(1)     controlurerrreportingen();
    method Action      id(Bit#(16) v);
    method Bit#(1)     statuscorrerrdetected();
    method Bit#(1)     statusfatalerrdetected();
    method Bit#(1)     statusnonfatalerrdetected();
    method Bit#(1)     statusurdetected();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgds;
    method Action      busnumber(Bit#(8) v);
    method Action      devicenumber(Bit#(5) v);
    method Action      functionnumber(Bit#(3) v);
    method Action      n(Bit#(64) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfgerr;
    method Action      acsn(Bit#(1) v);
    method Action      aerheaderlog(Bit#(128) v);
    method Bit#(1)     aerheaderlogsetn();
    method Action      atomicegressblockedn(Bit#(1) v);
    method Action      corn(Bit#(1) v);
    method Action      cplabortn(Bit#(1) v);
    method Bit#(1)     cplrdyn();
    method Action      cpltimeoutn(Bit#(1) v);
    method Action      cplunexpectn(Bit#(1) v);
    method Action      ecrcn(Bit#(1) v);
    method Action      internalcorn(Bit#(1) v);
    method Action      internaluncorn(Bit#(1) v);
    method Action      lockedn(Bit#(1) v);
    method Action      malformedn(Bit#(1) v);
    method Action      mcblockedn(Bit#(1) v);
    method Action      norecoveryn(Bit#(1) v);
    method Action      poisonedn(Bit#(1) v);
    method Action      postedn(Bit#(1) v);
    method Action      tlpcplheader(Bit#(48) v);
    method Action      urn(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfgforce;
    method Action      commonclockoff(Bit#(1) v);
    method Action      extendedsyncon(Bit#(1) v);
    method Action      mps(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfginterrupt;
    method Action      assertn(Bit#(1) v);
    method Action      di(Bit#(8) v);
    method Bit#(8)     do();
    method Bit#(3)     mmenable();
    method Bit#(1)     msienable();
    method Bit#(1)     msixenable();
    method Bit#(1)     msixfm();
    method Action      n(Bit#(1) v);
    method Bit#(1)     rdyn();
    method Action      statn(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfglink;
    method Bit#(2)     controlaspmcontrol();
    method Bit#(1)     controlautobandwidthinten();
    method Bit#(1)     controlbandwidthinten();
    method Bit#(1)     controlclockpmen();
    method Bit#(1)     controlcommonclock();
    method Bit#(1)     controlextendedsync();
    method Bit#(1)     controlhwautowidthdis();
    method Bit#(1)     controllinkdisable();
    method Bit#(1)     controlrcb();
    method Bit#(1)     controlretrainlink();
    method Bit#(1)     statusautobandwidthstatus();
    method Bit#(1)     statusbandwidthstatus();
    method Bit#(2)     statuscurrentspeed();
    method Bit#(1)     statusdllactive();
    method Bit#(1)     statuslinktraining();
    method Bit#(4)     statusnegotiatedwidth();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgmgmt;
    method Action      byteenn(Bit#(4) v);
    method Action      di(Bit#(32) v);
    method Bit#(32)     do();
    method Action      dwaddr(Bit#(10) v);
    method Action      rdenn(Bit#(1) v);
    method Bit#(1)     rdwrdonen();
    method Action      wrenn(Bit#(1) v);
    method Action      wrreadonlyn(Bit#(1) v);
    method Action      wrrw1casrwn(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfgmsg;
    method Bit#(16)     data();
    method Bit#(1)     received();
    method Bit#(1)     receivedassertinta();
    method Bit#(1)     receivedassertintb();
    method Bit#(1)     receivedassertintc();
    method Bit#(1)     receivedassertintd();
    method Bit#(1)     receiveddeassertinta();
    method Bit#(1)     receiveddeassertintb();
    method Bit#(1)     receiveddeassertintc();
    method Bit#(1)     receiveddeassertintd();
    method Bit#(1)     receivederrcor();
    method Bit#(1)     receivederrfatal();
    method Bit#(1)     receivederrnonfatal();
    method Bit#(1)     receivedpmasnak();
    method Bit#(1)     receivedpmeto();
    method Bit#(1)     receivedpmetoack();
    method Bit#(1)     receivedpmpme();
    method Bit#(1)     receivedsetslotpowerlimit();
    method Bit#(1)     receivedunlock();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgpm;
    method Bit#(1)     csrpmeen();
    method Bit#(1)     csrpmestatus();
    method Bit#(2)     csrpowerstate();
    method Action      forcestate(Bit#(2) v);
    method Action      forcestateenn(Bit#(1) v);
    method Action      haltaspml0sn(Bit#(1) v);
    method Action      haltaspml1n(Bit#(1) v);
    method Action      sendpmeton(Bit#(1) v);
    method Action      turnoffokn(Bit#(1) v);
    method Action      waken(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfgpmr;
    method Bit#(1)     cvasreql1n();
    method Bit#(1)     cventerl1n();
    method Bit#(1)     cventerl23n();
    method Bit#(1)     cvreqackn();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgroot;
    method Bit#(1)     controlpmeinten();
    method Bit#(1)     controlsyserrcorrerren();
    method Bit#(1)     controlsyserrfatalerren();
    method Bit#(1)     controlsyserrnonfatalerren();
endinterface
(* always_ready, always_enabled *)
interface PcieCfgsubsys;
    method Action      id(Bit#(16) v);
    method Action      vendid(Bit#(16) v);
endinterface
(* always_ready, always_enabled *)
interface PcieCfgtrans;
    method Bit#(1)     action();
    method Bit#(7)     actionaddr();
    method Bit#(1)     actiontype();
endinterface
(* always_ready, always_enabled *)
interface PcieDbg;
    method Action      mode(Bit#(2) v);
    method Bit#(1)     sclra();
    method Bit#(1)     sclrb();
    method Bit#(1)     sclrc();
    method Bit#(1)     sclrd();
    method Bit#(1)     sclre();
    method Bit#(1)     sclrf();
    method Bit#(1)     sclrg();
    method Bit#(1)     sclrh();
    method Bit#(1)     sclri();
    method Bit#(1)     sclrj();
    method Bit#(1)     sclrk();
    method Action      submode(Bit#(1) v);
    method Bit#(64)     veca();
    method Bit#(64)     vecb();
    method Bit#(12)     vecc();
endinterface
(* always_ready, always_enabled *)
interface PcieDrp;
    method Action      addr(Bit#(9) v);
    method Action      clk(Bit#(1) v);
    method Action      di(Bit#(16) v);
    method Bit#(16)     do();
    method Action      en(Bit#(1) v);
    method Bit#(1)     rdy();
    method Action      we(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieLl2;
    method Bit#(1)     baddllperr();
    method Bit#(1)     badtlperr();
    method Bit#(5)     linkstatus();
    method Bit#(1)     protocolerr();
    method Bit#(1)     receivererr();
    method Bit#(1)     replayroerr();
    method Bit#(1)     replaytoerr();
    method Action      sendasreql1(Bit#(1) v);
    method Action      sendenterl1(Bit#(1) v);
    method Action      sendenterl23(Bit#(1) v);
    method Action      sendpmack(Bit#(1) v);
    method Action      suspendnow(Bit#(1) v);
    method Bit#(1)     suspendok();
    method Bit#(1)     tfcinit1seq();
    method Bit#(1)     tfcinit2seq();
    method Action      tlprcv(Bit#(1) v);
    method Bit#(1)     txidle();
endinterface
(* always_ready, always_enabled *)
interface PcieMim;
    method Bit#(13)     rxraddr();
    method Action      rxrdata(Bit#(68) v);
    method Bit#(1)     rxren();
    method Bit#(13)     rxwaddr();
    method Bit#(68)     rxwdata();
    method Bit#(1)     rxwen();
    method Bit#(13)     txraddr();
    method Action      txrdata(Bit#(69) v);
    method Bit#(1)     txren();
    method Bit#(13)     txwaddr();
    method Bit#(69)     txwdata();
    method Bit#(1)     txwen();
endinterface
(* always_ready, always_enabled *)
interface PciePiperx;
    method Action      chanisaligned(Bit#(1) v);
    method Action      charisk(Bit#(2) v);
    method Action      data(Bit#(16) v);
    method Action      elecidle(Bit#(1) v);
    method Action      phystatus(Bit#(1) v);
    method Bit#(1)     polarity();
    method Action      status(Bit#(3) v);
    method Action      valid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciePipetx;
    method Bit#(2)     charisk();
    method Bit#(1)     compliance();
    method Bit#(16)     data();
    method Bit#(1)     elecidle();
    method Bit#(2)     powerdown();
endinterface
(* always_ready, always_enabled *)
interface PciePl;
    method Action      dbgmode(Bit#(3) v);
    method Bit#(12)     dbgvec();
    method Bit#(1)     directedchangedone();
    method Action      directedlinkauton(Bit#(1) v);
    method Action      directedlinkchange(Bit#(2) v);
    method Action      directedlinkspeed(Bit#(1) v);
    method Action      directedlinkwidth(Bit#(2) v);
    method Action      directedltssmnew(Bit#(6) v);
    method Action      directedltssmnewvld(Bit#(1) v);
    method Action      directedltssmstall(Bit#(1) v);
    method Action      downstreamdeemphsource(Bit#(1) v);
    method Bit#(3)     initiallinkwidth();
    method Bit#(2)     lanereversalmode();
    method Bit#(6)     ltssmstate();
    method Bit#(1)     phylnkupn();
    method Bit#(1)     receivedhotrst();
    method Action      rstn(Bit#(1) v);
    method Bit#(2)     rxpmstate();
    method Bit#(1)     sellnkrate();
    method Bit#(2)     sellnkwidth();
    method Action      transmithotrst(Bit#(1) v);
    method Bit#(3)     txpmstate();
    method Action      upstreampreferdeemph(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PciePl2;
    method Action      directedlstate(Bit#(5) v);
    method Bit#(1)     l0req();
    method Bit#(1)     linkup();
    method Bit#(1)     receivererr();
    method Bit#(1)     recovery();
    method Bit#(1)     rxelecidle();
    method Bit#(2)     rxpmstate();
    method Bit#(1)     suspendok();
endinterface
(* always_ready, always_enabled *)
interface PciePllink;
    method Bit#(1)     gen2cap();
    method Bit#(1)     partnergen2supported();
    method Bit#(1)     upcfgcap();
endinterface
(* always_ready, always_enabled *)
interface PcieTl2;
    method Action      aspmsuspendcreditcheck(Bit#(1) v);
    method Bit#(1)     aspmsuspendcreditcheckok();
    method Bit#(1)     aspmsuspendreq();
    method Bit#(1)     errfcpe();
    method Bit#(64)     errhdr();
    method Bit#(1)     errmalformed();
    method Bit#(1)     errrxoverflow();
    method Bit#(1)     ppmsuspendok();
    method Action      ppmsuspendreq(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieTrn;
    method Bit#(12)     fccpld();
    method Bit#(8)     fccplh();
    method Bit#(12)     fcnpd();
    method Bit#(8)     fcnph();
    method Bit#(12)     fcpd();
    method Bit#(8)     fcph();
    method Action      fcsel(Bit#(3) v);
    method Bit#(1)     lnkup();
    method Bit#(8)     rbarhit();
    method Bit#(128)     rd();
    method Bit#(64)     rdllpdata();
    method Bit#(2)     rdllpsrcrdy();
    method Action      rdstrdy(Bit#(1) v);
    method Bit#(1)     recrcerr();
    method Bit#(1)     reof();
    method Bit#(1)     rerrfwd();
    method Action      rfcpret(Bit#(1) v);
    method Action      rnpok(Bit#(1) v);
    method Action      rnpreq(Bit#(1) v);
    method Bit#(2)     rrem();
    method Bit#(1)     rsof();
    method Bit#(1)     rsrcdsc();
    method Bit#(1)     rsrcrdy();
    method Bit#(6)     tbufav();
    method Action      tcfggnt(Bit#(1) v);
    method Bit#(1)     tcfgreq();
    method Action      td(Bit#(128) v);
    method Action      tdllpdata(Bit#(32) v);
    method Bit#(1)     tdllpdstrdy();
    method Action      tdllpsrcrdy(Bit#(1) v);
    method Bit#(4)     tdstrdy();
    method Action      tecrcgen(Bit#(1) v);
    method Action      teof(Bit#(1) v);
    method Bit#(1)     terrdrop();
    method Action      terrfwd(Bit#(1) v);
    method Action      trem(Bit#(2) v);
    method Action      tsof(Bit#(1) v);
    method Action      tsrcdsc(Bit#(1) v);
    method Action      tsrcrdy(Bit#(1) v);
    method Action      tstr(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PcieIf;
    interface PcieCfgaer     cfgaer;
    method Bit#(1)     cfgbridgeserren();
    interface PcieCfgcommand     cfgcommand;
    interface PcieCfgdev     cfgdev;
    interface PcieCfgds     cfgds;
    interface PcieCfgerr     cfgerr;
    interface PcieCfgforce     cfgforce;
    interface PcieCfginterrupt     cfginterrupt;
    interface PcieCfglink     cfglink;
    interface PcieCfgmgmt     cfgmgmt;
    interface PcieCfgmsg     cfgmsg;
    method Action      cfgpciecapinterruptmsgnum(Bit#(5) v);
    method Bit#(3)     cfgpcielinkstate();
    interface PcieCfgpm     cfgpm;
    interface PcieCfgpmr     cfgpmr;
    method Action      cfgportnumber(Bit#(8) v);
    method Action      cfgrevid(Bit#(8) v);
    interface PcieCfgroot     cfgroot;
    method Bit#(1)     cfgslotcontrolelectromechilctlpulse();
    interface PcieCfgsubsys     cfgsubsys;
    interface PcieCfgtrans     cfgtrans;
    method Action      cfgtrnpendingn(Bit#(1) v);
    method Bit#(7)     cfgvctcvcmap();
    method Action      cfgvendid(Bit#(16) v);
    method Action      cmrstn(Bit#(1) v);
    method Action      cmstickyrstn(Bit#(1) v);
    interface PcieDbg     dbg;
    method Action      dlrstn(Bit#(1) v);
    interface PcieDrp     drp;
    method Action      funclvlrstn(Bit#(1) v);
    interface PcieLl2     ll2;
    method Bit#(1)     lnkclken();
    interface PcieMim     mim;
    method Action      pipeclk(Bit#(1) v);
    interface PciePiperx     piperx0;
    interface PciePiperx     piperx1;
    interface PciePiperx     piperx2;
    interface PciePiperx     piperx3;
    interface PciePiperx     piperx4;
    interface PciePiperx     piperx5;
    interface PciePiperx     piperx6;
    interface PciePiperx     piperx7;
    interface PciePipetx     pipetx0;
    interface PciePipetx     pipetx1;
    interface PciePipetx     pipetx2;
    interface PciePipetx     pipetx3;
    interface PciePipetx     pipetx4;
    interface PciePipetx     pipetx5;
    interface PciePipetx     pipetx6;
    interface PciePipetx     pipetx7;
    method Bit#(1)     pipetxdeemph();
    method Bit#(3)     pipetxmargin();
    method Bit#(1)     pipetxrate();
    method Bit#(1)     pipetxrcvrdet();
    method Bit#(1)     pipetxreset();
    interface PciePl2     pl2;
    interface PciePl     pl;
    interface PciePllink     pllink;
    method Bit#(1)     receivedfunclvlrstn();
    method Action      sysrstn(Bit#(1) v);
    interface PcieTl2     tl2;
    method Action      tlrstn(Bit#(1) v);
    interface PcieTrn     trn;
    method Action      userclk(Bit#(1) v);
    method Action      userclk2(Bit#(1) v);
    method Bit#(1)     userrstn();
endinterface
import "BVI" PCIE_2_1 =
module mkPcieIf(PcieIf);
    default_clock clk();
    default_reset rst();
    parameter C_DATA_WIDTH = 64;
    parameter CFG_VEND_ID = 16'h1BE7;
    parameter CFG_DEV_ID = 16'hB100;
    parameter CFG_REV_ID = 8'h00;
    parameter CFG_SUBSYS_VEND_ID = 16'h1BE7;
    parameter CFG_SUBSYS_ID = 16'hA705;
    parameter CLASS_CODE = 24'h050000;
    parameter DSN_CAP_NEXTPTR = 12'hffc;
    parameter LINK_CAP_ASPM_SUPPORT = 0;
    parameter LINK_CAP_MAX_LINK_WIDTH = 6'h8;
    parameter LINK_CAP_ASPM_OPTIONALITY = "TRUE";
    parameter LL_REPLAY_TIMEOUT_EN = "TRUE";
    parameter LL_REPLAY_TIMEOUT = 15'h001a;
    parameter LTSSM_MAX_LINK_WIDTH = 6'h8;
    parameter MSIX_CAP_PBA_OFFSET = 29'ha00;
    parameter MSIX_CAP_TABLE_OFFSET = 29'h800;
    parameter MSIX_CAP_TABLE_SIZE = 11'h003;
    parameter MSIX_CAP_ON = "TRUE";
    parameter PCIE_CAP_NEXTPTR = 8'h9C;
    parameter PIPE_PIPELINE_STAGES = 1;
    parameter PL_FAST_TRAIN = PL_FAST_TRAIN;
    parameter USER_CLK_FREQ = 3;
    parameter BAR0 = BAR0;
    parameter BAR1 = BAR1;
    parameter BAR2 = BAR2;
    parameter BAR3 = BAR3;
    parameter BAR4 = BAR4;
    parameter BAR5 = BAR5;
    interface PcieCfgaer     cfgaer;
        method CFGAERECRCCHECKEN ecrcchecken();
        method CFGAERECRCGENEN ecrcgenen();
        method interruptmsgnum(CFGAERINTERRUPTMSGNUM) enable((*inhigh*) EN_CFGAERINTERRUPTMSGNUM);
        method CFGAERROOTERRCORRERRRECEIVED rooterrcorrerrreceived();
        method CFGAERROOTERRCORRERRREPORTINGEN rooterrcorrerrreportingen();
        method CFGAERROOTERRFATALERRRECEIVED rooterrfatalerrreceived();
        method CFGAERROOTERRFATALERRREPORTINGEN rooterrfatalerrreportingen();
        method CFGAERROOTERRNONFATALERRRECEIVED rooterrnonfatalerrreceived();
        method CFGAERROOTERRNONFATALERRREPORTINGEN rooterrnonfatalerrreportingen();
    endinterface
    method CFGBRIDGESERREN cfgbridgeserren();
    interface PcieCfgcommand     cfgcommand;
        method CFGCOMMANDBUSMASTERENABLE busmasterenable();
        method CFGCOMMANDINTERRUPTDISABLE interruptdisable();
        method CFGCOMMANDIOENABLE ioenable();
        method CFGCOMMANDMEMENABLE memenable();
        method CFGCOMMANDSERREN serren();
    endinterface
    interface PcieCfgdev     cfgdev;
        method CFGDEVCONTROL2ARIFORWARDEN control2ariforwarden();
        method CFGDEVCONTROL2ATOMICEGRESSBLOCK control2atomicegressblock();
        method CFGDEVCONTROL2ATOMICREQUESTEREN control2atomicrequesteren();
        method CFGDEVCONTROL2CPLTIMEOUTDIS control2cpltimeoutdis();
        method CFGDEVCONTROL2CPLTIMEOUTVAL control2cpltimeoutval();
        method CFGDEVCONTROL2IDOCPLEN control2idocplen();
        method CFGDEVCONTROL2IDOREQEN control2idoreqen();
        method CFGDEVCONTROL2LTREN control2ltren();
        method CFGDEVCONTROL2TLPPREFIXBLOCK control2tlpprefixblock();
        method CFGDEVCONTROLAUXPOWEREN controlauxpoweren();
        method CFGDEVCONTROLCORRERRREPORTINGEN controlcorrerrreportingen();
        method CFGDEVCONTROLENABLERO controlenablero();
        method CFGDEVCONTROLEXTTAGEN controlexttagen();
        method CFGDEVCONTROLFATALERRREPORTINGEN controlfatalerrreportingen();
        method CFGDEVCONTROLMAXPAYLOAD controlmaxpayload();
        method CFGDEVCONTROLMAXREADREQ controlmaxreadreq();
        method CFGDEVCONTROLNONFATALREPORTINGEN controlnonfatalreportingen();
        method CFGDEVCONTROLNOSNOOPEN controlnosnoopen();
        method CFGDEVCONTROLPHANTOMEN controlphantomen();
        method CFGDEVCONTROLURERRREPORTINGEN controlurerrreportingen();
        method id(CFGDEVID) enable((*inhigh*) EN_CFGDEVID);
        method CFGDEVSTATUSCORRERRDETECTED statuscorrerrdetected();
        method CFGDEVSTATUSFATALERRDETECTED statusfatalerrdetected();
        method CFGDEVSTATUSNONFATALERRDETECTED statusnonfatalerrdetected();
        method CFGDEVSTATUSURDETECTED statusurdetected();
    endinterface
    interface PcieCfgds     cfgds;
        method busnumber(CFGDSBUSNUMBER) enable((*inhigh*) EN_CFGDSBUSNUMBER);
        method devicenumber(CFGDSDEVICENUMBER) enable((*inhigh*) EN_CFGDSDEVICENUMBER);
        method functionnumber(CFGDSFUNCTIONNUMBER) enable((*inhigh*) EN_CFGDSFUNCTIONNUMBER);
        method n(CFGDSN) enable((*inhigh*) EN_CFGDSN);
    endinterface
    interface PcieCfgerr     cfgerr;
        method acsn(CFGERRACSN) enable((*inhigh*) EN_CFGERRACSN);
        method aerheaderlog(CFGERRAERHEADERLOG) enable((*inhigh*) EN_CFGERRAERHEADERLOG);
        method CFGERRAERHEADERLOGSETN aerheaderlogsetn();
        method atomicegressblockedn(CFGERRATOMICEGRESSBLOCKEDN) enable((*inhigh*) EN_CFGERRATOMICEGRESSBLOCKEDN);
        method corn(CFGERRCORN) enable((*inhigh*) EN_CFGERRCORN);
        method cplabortn(CFGERRCPLABORTN) enable((*inhigh*) EN_CFGERRCPLABORTN);
        method CFGERRCPLRDYN cplrdyn();
        method cpltimeoutn(CFGERRCPLTIMEOUTN) enable((*inhigh*) EN_CFGERRCPLTIMEOUTN);
        method cplunexpectn(CFGERRCPLUNEXPECTN) enable((*inhigh*) EN_CFGERRCPLUNEXPECTN);
        method ecrcn(CFGERRECRCN) enable((*inhigh*) EN_CFGERRECRCN);
        method internalcorn(CFGERRINTERNALCORN) enable((*inhigh*) EN_CFGERRINTERNALCORN);
        method internaluncorn(CFGERRINTERNALUNCORN) enable((*inhigh*) EN_CFGERRINTERNALUNCORN);
        method lockedn(CFGERRLOCKEDN) enable((*inhigh*) EN_CFGERRLOCKEDN);
        method malformedn(CFGERRMALFORMEDN) enable((*inhigh*) EN_CFGERRMALFORMEDN);
        method mcblockedn(CFGERRMCBLOCKEDN) enable((*inhigh*) EN_CFGERRMCBLOCKEDN);
        method norecoveryn(CFGERRNORECOVERYN) enable((*inhigh*) EN_CFGERRNORECOVERYN);
        method poisonedn(CFGERRPOISONEDN) enable((*inhigh*) EN_CFGERRPOISONEDN);
        method postedn(CFGERRPOSTEDN) enable((*inhigh*) EN_CFGERRPOSTEDN);
        method tlpcplheader(CFGERRTLPCPLHEADER) enable((*inhigh*) EN_CFGERRTLPCPLHEADER);
        method urn(CFGERRURN) enable((*inhigh*) EN_CFGERRURN);
    endinterface
    interface PcieCfgforce     cfgforce;
        method commonclockoff(CFGFORCECOMMONCLOCKOFF) enable((*inhigh*) EN_CFGFORCECOMMONCLOCKOFF);
        method extendedsyncon(CFGFORCEEXTENDEDSYNCON) enable((*inhigh*) EN_CFGFORCEEXTENDEDSYNCON);
        method mps(CFGFORCEMPS) enable((*inhigh*) EN_CFGFORCEMPS);
    endinterface
    interface PcieCfginterrupt     cfginterrupt;
        method assertn(CFGINTERRUPTASSERTN) enable((*inhigh*) EN_CFGINTERRUPTASSERTN);
        method di(CFGINTERRUPTDI) enable((*inhigh*) EN_CFGINTERRUPTDI);
        method CFGINTERRUPTDO do();
        method CFGINTERRUPTMMENABLE mmenable();
        method CFGINTERRUPTMSIENABLE msienable();
        method CFGINTERRUPTMSIXENABLE msixenable();
        method CFGINTERRUPTMSIXFM msixfm();
        method n(CFGINTERRUPTN) enable((*inhigh*) EN_CFGINTERRUPTN);
        method CFGINTERRUPTRDYN rdyn();
        method statn(CFGINTERRUPTSTATN) enable((*inhigh*) EN_CFGINTERRUPTSTATN);
    endinterface
    interface PcieCfglink     cfglink;
        method CFGLINKCONTROLASPMCONTROL controlaspmcontrol();
        method CFGLINKCONTROLAUTOBANDWIDTHINTEN controlautobandwidthinten();
        method CFGLINKCONTROLBANDWIDTHINTEN controlbandwidthinten();
        method CFGLINKCONTROLCLOCKPMEN controlclockpmen();
        method CFGLINKCONTROLCOMMONCLOCK controlcommonclock();
        method CFGLINKCONTROLEXTENDEDSYNC controlextendedsync();
        method CFGLINKCONTROLHWAUTOWIDTHDIS controlhwautowidthdis();
        method CFGLINKCONTROLLINKDISABLE controllinkdisable();
        method CFGLINKCONTROLRCB controlrcb();
        method CFGLINKCONTROLRETRAINLINK controlretrainlink();
        method CFGLINKSTATUSAUTOBANDWIDTHSTATUS statusautobandwidthstatus();
        method CFGLINKSTATUSBANDWIDTHSTATUS statusbandwidthstatus();
        method CFGLINKSTATUSCURRENTSPEED statuscurrentspeed();
        method CFGLINKSTATUSDLLACTIVE statusdllactive();
        method CFGLINKSTATUSLINKTRAINING statuslinktraining();
        method CFGLINKSTATUSNEGOTIATEDWIDTH statusnegotiatedwidth();
    endinterface
    interface PcieCfgmgmt     cfgmgmt;
        method byteenn(CFGMGMTBYTEENN) enable((*inhigh*) EN_CFGMGMTBYTEENN);
        method di(CFGMGMTDI) enable((*inhigh*) EN_CFGMGMTDI);
        method CFGMGMTDO do();
        method dwaddr(CFGMGMTDWADDR) enable((*inhigh*) EN_CFGMGMTDWADDR);
        method rdenn(CFGMGMTRDENN) enable((*inhigh*) EN_CFGMGMTRDENN);
        method CFGMGMTRDWRDONEN rdwrdonen();
        method wrenn(CFGMGMTWRENN) enable((*inhigh*) EN_CFGMGMTWRENN);
        method wrreadonlyn(CFGMGMTWRREADONLYN) enable((*inhigh*) EN_CFGMGMTWRREADONLYN);
        method wrrw1casrwn(CFGMGMTWRRW1CASRWN) enable((*inhigh*) EN_CFGMGMTWRRW1CASRWN);
    endinterface
    interface PcieCfgmsg     cfgmsg;
        method CFGMSGDATA data();
        method CFGMSGRECEIVED received();
        method CFGMSGRECEIVEDASSERTINTA receivedassertinta();
        method CFGMSGRECEIVEDASSERTINTB receivedassertintb();
        method CFGMSGRECEIVEDASSERTINTC receivedassertintc();
        method CFGMSGRECEIVEDASSERTINTD receivedassertintd();
        method CFGMSGRECEIVEDDEASSERTINTA receiveddeassertinta();
        method CFGMSGRECEIVEDDEASSERTINTB receiveddeassertintb();
        method CFGMSGRECEIVEDDEASSERTINTC receiveddeassertintc();
        method CFGMSGRECEIVEDDEASSERTINTD receiveddeassertintd();
        method CFGMSGRECEIVEDERRCOR receivederrcor();
        method CFGMSGRECEIVEDERRFATAL receivederrfatal();
        method CFGMSGRECEIVEDERRNONFATAL receivederrnonfatal();
        method CFGMSGRECEIVEDPMASNAK receivedpmasnak();
        method CFGMSGRECEIVEDPMETO receivedpmeto();
        method CFGMSGRECEIVEDPMETOACK receivedpmetoack();
        method CFGMSGRECEIVEDPMPME receivedpmpme();
        method CFGMSGRECEIVEDSETSLOTPOWERLIMIT receivedsetslotpowerlimit();
        method CFGMSGRECEIVEDUNLOCK receivedunlock();
    endinterface
    method cfgpciecapinterruptmsgnum(CFGPCIECAPINTERRUPTMSGNUM) enable((*inhigh*) EN_CFGPCIECAPINTERRUPTMSGNUM);
    method CFGPCIELINKSTATE cfgpcielinkstate();
    interface PcieCfgpm     cfgpm;
        method CFGPMCSRPMEEN csrpmeen();
        method CFGPMCSRPMESTATUS csrpmestatus();
        method CFGPMCSRPOWERSTATE csrpowerstate();
        method forcestate(CFGPMFORCESTATE) enable((*inhigh*) EN_CFGPMFORCESTATE);
        method forcestateenn(CFGPMFORCESTATEENN) enable((*inhigh*) EN_CFGPMFORCESTATEENN);
        method haltaspml0sn(CFGPMHALTASPML0SN) enable((*inhigh*) EN_CFGPMHALTASPML0SN);
        method haltaspml1n(CFGPMHALTASPML1N) enable((*inhigh*) EN_CFGPMHALTASPML1N);
        method sendpmeton(CFGPMSENDPMETON) enable((*inhigh*) EN_CFGPMSENDPMETON);
        method turnoffokn(CFGPMTURNOFFOKN) enable((*inhigh*) EN_CFGPMTURNOFFOKN);
        method waken(CFGPMWAKEN) enable((*inhigh*) EN_CFGPMWAKEN);
    endinterface
    interface PcieCfgpmr     cfgpmr;
        method CFGPMRCVASREQL1N cvasreql1n();
        method CFGPMRCVENTERL1N cventerl1n();
        method CFGPMRCVENTERL23N cventerl23n();
        method CFGPMRCVREQACKN cvreqackn();
    endinterface
    method cfgportnumber(CFGPORTNUMBER) enable((*inhigh*) EN_CFGPORTNUMBER);
    method cfgrevid(CFGREVID) enable((*inhigh*) EN_CFGREVID);
    interface PcieCfgroot     cfgroot;
        method CFGROOTCONTROLPMEINTEN controlpmeinten();
        method CFGROOTCONTROLSYSERRCORRERREN controlsyserrcorrerren();
        method CFGROOTCONTROLSYSERRFATALERREN controlsyserrfatalerren();
        method CFGROOTCONTROLSYSERRNONFATALERREN controlsyserrnonfatalerren();
    endinterface
    method CFGSLOTCONTROLELECTROMECHILCTLPULSE cfgslotcontrolelectromechilctlpulse();
    interface PcieCfgsubsys     cfgsubsys;
        method id(CFGSUBSYSID) enable((*inhigh*) EN_CFGSUBSYSID);
        method vendid(CFGSUBSYSVENDID) enable((*inhigh*) EN_CFGSUBSYSVENDID);
    endinterface
    interface PcieCfgtrans     cfgtrans;
        method CFGTRANSACTION action();
        method CFGTRANSACTIONADDR actionaddr();
        method CFGTRANSACTIONTYPE actiontype();
    endinterface
    method cfgtrnpendingn(CFGTRNPENDINGN) enable((*inhigh*) EN_CFGTRNPENDINGN);
    method CFGVCTCVCMAP cfgvctcvcmap();
    method cfgvendid(CFGVENDID) enable((*inhigh*) EN_CFGVENDID);
    method cmrstn(CMRSTN) enable((*inhigh*) EN_CMRSTN);
    method cmstickyrstn(CMSTICKYRSTN) enable((*inhigh*) EN_CMSTICKYRSTN);
    interface PcieDbg     dbg;
        method mode(DBGMODE) enable((*inhigh*) EN_DBGMODE);
        method DBGSCLRA sclra();
        method DBGSCLRB sclrb();
        method DBGSCLRC sclrc();
        method DBGSCLRD sclrd();
        method DBGSCLRE sclre();
        method DBGSCLRF sclrf();
        method DBGSCLRG sclrg();
        method DBGSCLRH sclrh();
        method DBGSCLRI sclri();
        method DBGSCLRJ sclrj();
        method DBGSCLRK sclrk();
        method submode(DBGSUBMODE) enable((*inhigh*) EN_DBGSUBMODE);
        method DBGVECA veca();
        method DBGVECB vecb();
        method DBGVECC vecc();
    endinterface
    method dlrstn(DLRSTN) enable((*inhigh*) EN_DLRSTN);
    interface PcieDrp     drp;
        method addr(DRPADDR) enable((*inhigh*) EN_DRPADDR);
        method clk(DRPCLK) enable((*inhigh*) EN_DRPCLK);
        method di(DRPDI) enable((*inhigh*) EN_DRPDI);
        method DRPDO do();
        method en(DRPEN) enable((*inhigh*) EN_DRPEN);
        method DRPRDY rdy();
        method we(DRPWE) enable((*inhigh*) EN_DRPWE);
    endinterface
    method funclvlrstn(FUNCLVLRSTN) enable((*inhigh*) EN_FUNCLVLRSTN);
    interface PcieLl2     ll2;
        method LL2BADDLLPERR baddllperr();
        method LL2BADTLPERR badtlperr();
        method LL2LINKSTATUS linkstatus();
        method LL2PROTOCOLERR protocolerr();
        method LL2RECEIVERERR receivererr();
        method LL2REPLAYROERR replayroerr();
        method LL2REPLAYTOERR replaytoerr();
        method sendasreql1(LL2SENDASREQL1) enable((*inhigh*) EN_LL2SENDASREQL1);
        method sendenterl1(LL2SENDENTERL1) enable((*inhigh*) EN_LL2SENDENTERL1);
        method sendenterl23(LL2SENDENTERL23) enable((*inhigh*) EN_LL2SENDENTERL23);
        method sendpmack(LL2SENDPMACK) enable((*inhigh*) EN_LL2SENDPMACK);
        method suspendnow(LL2SUSPENDNOW) enable((*inhigh*) EN_LL2SUSPENDNOW);
        method LL2SUSPENDOK suspendok();
        method LL2TFCINIT1SEQ tfcinit1seq();
        method LL2TFCINIT2SEQ tfcinit2seq();
        method tlprcv(LL2TLPRCV) enable((*inhigh*) EN_LL2TLPRCV);
        method LL2TXIDLE txidle();
    endinterface
    method LNKCLKEN lnkclken();
    interface PcieMim     mim;
        method MIMRXRADDR rxraddr();
        method rxrdata(MIMRXRDATA) enable((*inhigh*) EN_MIMRXRDATA);
        method MIMRXREN rxren();
        method MIMRXWADDR rxwaddr();
        method MIMRXWDATA rxwdata();
        method MIMRXWEN rxwen();
        method MIMTXRADDR txraddr();
        method txrdata(MIMTXRDATA) enable((*inhigh*) EN_MIMTXRDATA);
        method MIMTXREN txren();
        method MIMTXWADDR txwaddr();
        method MIMTXWDATA txwdata();
        method MIMTXWEN txwen();
    endinterface
    method pipeclk(PIPECLK) enable((*inhigh*) EN_PIPECLK);
    interface PciePiperx     piperx0;
        method chanisaligned(PIPERX0CHANISALIGNED) enable((*inhigh*) EN_PIPERX0CHANISALIGNED);
        method charisk(PIPERX0CHARISK) enable((*inhigh*) EN_PIPERX0CHARISK);
        method data(PIPERX0DATA) enable((*inhigh*) EN_PIPERX0DATA);
        method elecidle(PIPERX0ELECIDLE) enable((*inhigh*) EN_PIPERX0ELECIDLE);
        method phystatus(PIPERX0PHYSTATUS) enable((*inhigh*) EN_PIPERX0PHYSTATUS);
        method PIPERX0POLARITY polarity();
        method status(PIPERX0STATUS) enable((*inhigh*) EN_PIPERX0STATUS);
        method valid(PIPERX0VALID) enable((*inhigh*) EN_PIPERX0VALID);
    endinterface
    interface PciePiperx     piperx1;
        method chanisaligned(PIPERX1CHANISALIGNED) enable((*inhigh*) EN_PIPERX1CHANISALIGNED);
        method charisk(PIPERX1CHARISK) enable((*inhigh*) EN_PIPERX1CHARISK);
        method data(PIPERX1DATA) enable((*inhigh*) EN_PIPERX1DATA);
        method elecidle(PIPERX1ELECIDLE) enable((*inhigh*) EN_PIPERX1ELECIDLE);
        method phystatus(PIPERX1PHYSTATUS) enable((*inhigh*) EN_PIPERX1PHYSTATUS);
        method PIPERX1POLARITY polarity();
        method status(PIPERX1STATUS) enable((*inhigh*) EN_PIPERX1STATUS);
        method valid(PIPERX1VALID) enable((*inhigh*) EN_PIPERX1VALID);
    endinterface
    interface PciePiperx     piperx2;
        method chanisaligned(PIPERX2CHANISALIGNED) enable((*inhigh*) EN_PIPERX2CHANISALIGNED);
        method charisk(PIPERX2CHARISK) enable((*inhigh*) EN_PIPERX2CHARISK);
        method data(PIPERX2DATA) enable((*inhigh*) EN_PIPERX2DATA);
        method elecidle(PIPERX2ELECIDLE) enable((*inhigh*) EN_PIPERX2ELECIDLE);
        method phystatus(PIPERX2PHYSTATUS) enable((*inhigh*) EN_PIPERX2PHYSTATUS);
        method PIPERX2POLARITY polarity();
        method status(PIPERX2STATUS) enable((*inhigh*) EN_PIPERX2STATUS);
        method valid(PIPERX2VALID) enable((*inhigh*) EN_PIPERX2VALID);
    endinterface
    interface PciePiperx     piperx3;
        method chanisaligned(PIPERX3CHANISALIGNED) enable((*inhigh*) EN_PIPERX3CHANISALIGNED);
        method charisk(PIPERX3CHARISK) enable((*inhigh*) EN_PIPERX3CHARISK);
        method data(PIPERX3DATA) enable((*inhigh*) EN_PIPERX3DATA);
        method elecidle(PIPERX3ELECIDLE) enable((*inhigh*) EN_PIPERX3ELECIDLE);
        method phystatus(PIPERX3PHYSTATUS) enable((*inhigh*) EN_PIPERX3PHYSTATUS);
        method PIPERX3POLARITY polarity();
        method status(PIPERX3STATUS) enable((*inhigh*) EN_PIPERX3STATUS);
        method valid(PIPERX3VALID) enable((*inhigh*) EN_PIPERX3VALID);
    endinterface
    interface PciePiperx     piperx4;
        method chanisaligned(PIPERX4CHANISALIGNED) enable((*inhigh*) EN_PIPERX4CHANISALIGNED);
        method charisk(PIPERX4CHARISK) enable((*inhigh*) EN_PIPERX4CHARISK);
        method data(PIPERX4DATA) enable((*inhigh*) EN_PIPERX4DATA);
        method elecidle(PIPERX4ELECIDLE) enable((*inhigh*) EN_PIPERX4ELECIDLE);
        method phystatus(PIPERX4PHYSTATUS) enable((*inhigh*) EN_PIPERX4PHYSTATUS);
        method PIPERX4POLARITY polarity();
        method status(PIPERX4STATUS) enable((*inhigh*) EN_PIPERX4STATUS);
        method valid(PIPERX4VALID) enable((*inhigh*) EN_PIPERX4VALID);
    endinterface
    interface PciePiperx     piperx5;
        method chanisaligned(PIPERX5CHANISALIGNED) enable((*inhigh*) EN_PIPERX5CHANISALIGNED);
        method charisk(PIPERX5CHARISK) enable((*inhigh*) EN_PIPERX5CHARISK);
        method data(PIPERX5DATA) enable((*inhigh*) EN_PIPERX5DATA);
        method elecidle(PIPERX5ELECIDLE) enable((*inhigh*) EN_PIPERX5ELECIDLE);
        method phystatus(PIPERX5PHYSTATUS) enable((*inhigh*) EN_PIPERX5PHYSTATUS);
        method PIPERX5POLARITY polarity();
        method status(PIPERX5STATUS) enable((*inhigh*) EN_PIPERX5STATUS);
        method valid(PIPERX5VALID) enable((*inhigh*) EN_PIPERX5VALID);
    endinterface
    interface PciePiperx     piperx6;
        method chanisaligned(PIPERX6CHANISALIGNED) enable((*inhigh*) EN_PIPERX6CHANISALIGNED);
        method charisk(PIPERX6CHARISK) enable((*inhigh*) EN_PIPERX6CHARISK);
        method data(PIPERX6DATA) enable((*inhigh*) EN_PIPERX6DATA);
        method elecidle(PIPERX6ELECIDLE) enable((*inhigh*) EN_PIPERX6ELECIDLE);
        method phystatus(PIPERX6PHYSTATUS) enable((*inhigh*) EN_PIPERX6PHYSTATUS);
        method PIPERX6POLARITY polarity();
        method status(PIPERX6STATUS) enable((*inhigh*) EN_PIPERX6STATUS);
        method valid(PIPERX6VALID) enable((*inhigh*) EN_PIPERX6VALID);
    endinterface
    interface PciePiperx     piperx7;
        method chanisaligned(PIPERX7CHANISALIGNED) enable((*inhigh*) EN_PIPERX7CHANISALIGNED);
        method charisk(PIPERX7CHARISK) enable((*inhigh*) EN_PIPERX7CHARISK);
        method data(PIPERX7DATA) enable((*inhigh*) EN_PIPERX7DATA);
        method elecidle(PIPERX7ELECIDLE) enable((*inhigh*) EN_PIPERX7ELECIDLE);
        method phystatus(PIPERX7PHYSTATUS) enable((*inhigh*) EN_PIPERX7PHYSTATUS);
        method PIPERX7POLARITY polarity();
        method status(PIPERX7STATUS) enable((*inhigh*) EN_PIPERX7STATUS);
        method valid(PIPERX7VALID) enable((*inhigh*) EN_PIPERX7VALID);
    endinterface
    interface PciePipetx     pipetx0;
        method PIPETX0CHARISK charisk();
        method PIPETX0COMPLIANCE compliance();
        method PIPETX0DATA data();
        method PIPETX0ELECIDLE elecidle();
        method PIPETX0POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx1;
        method PIPETX1CHARISK charisk();
        method PIPETX1COMPLIANCE compliance();
        method PIPETX1DATA data();
        method PIPETX1ELECIDLE elecidle();
        method PIPETX1POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx2;
        method PIPETX2CHARISK charisk();
        method PIPETX2COMPLIANCE compliance();
        method PIPETX2DATA data();
        method PIPETX2ELECIDLE elecidle();
        method PIPETX2POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx3;
        method PIPETX3CHARISK charisk();
        method PIPETX3COMPLIANCE compliance();
        method PIPETX3DATA data();
        method PIPETX3ELECIDLE elecidle();
        method PIPETX3POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx4;
        method PIPETX4CHARISK charisk();
        method PIPETX4COMPLIANCE compliance();
        method PIPETX4DATA data();
        method PIPETX4ELECIDLE elecidle();
        method PIPETX4POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx5;
        method PIPETX5CHARISK charisk();
        method PIPETX5COMPLIANCE compliance();
        method PIPETX5DATA data();
        method PIPETX5ELECIDLE elecidle();
        method PIPETX5POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx6;
        method PIPETX6CHARISK charisk();
        method PIPETX6COMPLIANCE compliance();
        method PIPETX6DATA data();
        method PIPETX6ELECIDLE elecidle();
        method PIPETX6POWERDOWN powerdown();
    endinterface
    interface PciePipetx     pipetx7;
        method PIPETX7CHARISK charisk();
        method PIPETX7COMPLIANCE compliance();
        method PIPETX7DATA data();
        method PIPETX7ELECIDLE elecidle();
        method PIPETX7POWERDOWN powerdown();
    endinterface
    method PIPETXDEEMPH pipetxdeemph();
    method PIPETXMARGIN pipetxmargin();
    method PIPETXRATE pipetxrate();
    method PIPETXRCVRDET pipetxrcvrdet();
    method PIPETXRESET pipetxreset();
    interface PciePl2     pl2;
        method directedlstate(PL2DIRECTEDLSTATE) enable((*inhigh*) EN_PL2DIRECTEDLSTATE);
        method PL2L0REQ l0req();
        method PL2LINKUP linkup();
        method PL2RECEIVERERR receivererr();
        method PL2RECOVERY recovery();
        method PL2RXELECIDLE rxelecidle();
        method PL2RXPMSTATE rxpmstate();
        method PL2SUSPENDOK suspendok();
    endinterface
    interface PciePl     pl;
        method dbgmode(PLDBGMODE) enable((*inhigh*) EN_PLDBGMODE);
        method PLDBGVEC dbgvec();
        method PLDIRECTEDCHANGEDONE directedchangedone();
        method directedlinkauton(PLDIRECTEDLINKAUTON) enable((*inhigh*) EN_PLDIRECTEDLINKAUTON);
        method directedlinkchange(PLDIRECTEDLINKCHANGE) enable((*inhigh*) EN_PLDIRECTEDLINKCHANGE);
        method directedlinkspeed(PLDIRECTEDLINKSPEED) enable((*inhigh*) EN_PLDIRECTEDLINKSPEED);
        method directedlinkwidth(PLDIRECTEDLINKWIDTH) enable((*inhigh*) EN_PLDIRECTEDLINKWIDTH);
        method directedltssmnew(PLDIRECTEDLTSSMNEW) enable((*inhigh*) EN_PLDIRECTEDLTSSMNEW);
        method directedltssmnewvld(PLDIRECTEDLTSSMNEWVLD) enable((*inhigh*) EN_PLDIRECTEDLTSSMNEWVLD);
        method directedltssmstall(PLDIRECTEDLTSSMSTALL) enable((*inhigh*) EN_PLDIRECTEDLTSSMSTALL);
        method downstreamdeemphsource(PLDOWNSTREAMDEEMPHSOURCE) enable((*inhigh*) EN_PLDOWNSTREAMDEEMPHSOURCE);
        method PLINITIALLINKWIDTH initiallinkwidth();
        method PLLANEREVERSALMODE lanereversalmode();
        method PLLTSSMSTATE ltssmstate();
        method PLPHYLNKUPN phylnkupn();
        method PLRECEIVEDHOTRST receivedhotrst();
        method rstn(PLRSTN) enable((*inhigh*) EN_PLRSTN);
        method PLRXPMSTATE rxpmstate();
        method PLSELLNKRATE sellnkrate();
        method PLSELLNKWIDTH sellnkwidth();
        method transmithotrst(PLTRANSMITHOTRST) enable((*inhigh*) EN_PLTRANSMITHOTRST);
        method PLTXPMSTATE txpmstate();
        method upstreampreferdeemph(PLUPSTREAMPREFERDEEMPH) enable((*inhigh*) EN_PLUPSTREAMPREFERDEEMPH);
    endinterface
    interface PciePllink     pllink;
        method PLLINKGEN2CAP gen2cap();
        method PLLINKPARTNERGEN2SUPPORTED partnergen2supported();
        method PLLINKUPCFGCAP upcfgcap();
    endinterface
    method RECEIVEDFUNCLVLRSTN receivedfunclvlrstn();
    method sysrstn(SYSRSTN) enable((*inhigh*) EN_SYSRSTN);
    interface PcieTl2     tl2;
        method aspmsuspendcreditcheck(TL2ASPMSUSPENDCREDITCHECK) enable((*inhigh*) EN_TL2ASPMSUSPENDCREDITCHECK);
        method TL2ASPMSUSPENDCREDITCHECKOK aspmsuspendcreditcheckok();
        method TL2ASPMSUSPENDREQ aspmsuspendreq();
        method TL2ERRFCPE errfcpe();
        method TL2ERRHDR errhdr();
        method TL2ERRMALFORMED errmalformed();
        method TL2ERRRXOVERFLOW errrxoverflow();
        method TL2PPMSUSPENDOK ppmsuspendok();
        method ppmsuspendreq(TL2PPMSUSPENDREQ) enable((*inhigh*) EN_TL2PPMSUSPENDREQ);
    endinterface
    method tlrstn(TLRSTN) enable((*inhigh*) EN_TLRSTN);
    interface PcieTrn     trn;
        method TRNFCCPLD fccpld();
        method TRNFCCPLH fccplh();
        method TRNFCNPD fcnpd();
        method TRNFCNPH fcnph();
        method TRNFCPD fcpd();
        method TRNFCPH fcph();
        method fcsel(TRNFCSEL) enable((*inhigh*) EN_TRNFCSEL);
        method TRNLNKUP lnkup();
        method TRNRBARHIT rbarhit();
        method TRNRD rd();
        method TRNRDLLPDATA rdllpdata();
        method TRNRDLLPSRCRDY rdllpsrcrdy();
        method rdstrdy(TRNRDSTRDY) enable((*inhigh*) EN_TRNRDSTRDY);
        method TRNRECRCERR recrcerr();
        method TRNREOF reof();
        method TRNRERRFWD rerrfwd();
        method rfcpret(TRNRFCPRET) enable((*inhigh*) EN_TRNRFCPRET);
        method rnpok(TRNRNPOK) enable((*inhigh*) EN_TRNRNPOK);
        method rnpreq(TRNRNPREQ) enable((*inhigh*) EN_TRNRNPREQ);
        method TRNRREM rrem();
        method TRNRSOF rsof();
        method TRNRSRCDSC rsrcdsc();
        method TRNRSRCRDY rsrcrdy();
        method TRNTBUFAV tbufav();
        method tcfggnt(TRNTCFGGNT) enable((*inhigh*) EN_TRNTCFGGNT);
        method TRNTCFGREQ tcfgreq();
        method td(TRNTD) enable((*inhigh*) EN_TRNTD);
        method tdllpdata(TRNTDLLPDATA) enable((*inhigh*) EN_TRNTDLLPDATA);
        method TRNTDLLPDSTRDY tdllpdstrdy();
        method tdllpsrcrdy(TRNTDLLPSRCRDY) enable((*inhigh*) EN_TRNTDLLPSRCRDY);
        method TRNTDSTRDY tdstrdy();
        method tecrcgen(TRNTECRCGEN) enable((*inhigh*) EN_TRNTECRCGEN);
        method teof(TRNTEOF) enable((*inhigh*) EN_TRNTEOF);
        method TRNTERRDROP terrdrop();
        method terrfwd(TRNTERRFWD) enable((*inhigh*) EN_TRNTERRFWD);
        method trem(TRNTREM) enable((*inhigh*) EN_TRNTREM);
        method tsof(TRNTSOF) enable((*inhigh*) EN_TRNTSOF);
        method tsrcdsc(TRNTSRCDSC) enable((*inhigh*) EN_TRNTSRCDSC);
        method tsrcrdy(TRNTSRCRDY) enable((*inhigh*) EN_TRNTSRCRDY);
        method tstr(TRNTSTR) enable((*inhigh*) EN_TRNTSTR);
    endinterface
    method userclk(USERCLK) enable((*inhigh*) EN_USERCLK);
    method userclk2(USERCLK2) enable((*inhigh*) EN_USERCLK2);
    method USERRSTN userrstn();
    schedule (cfgaer.ecrcchecken, cfgaer.ecrcgenen, cfgaer.interruptmsgnum, cfgaer.rooterrcorrerrreceived, cfgaer.rooterrcorrerrreportingen, cfgaer.rooterrfatalerrreceived, cfgaer.rooterrfatalerrreportingen, cfgaer.rooterrnonfatalerrreceived, cfgaer.rooterrnonfatalerrreportingen, cfgbridgeserren, cfgcommand.busmasterenable, cfgcommand.interruptdisable, cfgcommand.ioenable, cfgcommand.memenable, cfgcommand.serren, cfgdev.control2ariforwarden, cfgdev.control2atomicegressblock, cfgdev.control2atomicrequesteren, cfgdev.control2cpltimeoutdis, cfgdev.control2cpltimeoutval, cfgdev.control2idocplen, cfgdev.control2idoreqen, cfgdev.control2ltren, cfgdev.control2tlpprefixblock, cfgdev.controlauxpoweren, cfgdev.controlcorrerrreportingen, cfgdev.controlenablero, cfgdev.controlexttagen, cfgdev.controlfatalerrreportingen, cfgdev.controlmaxpayload, cfgdev.controlmaxreadreq, cfgdev.controlnonfatalreportingen, cfgdev.controlnosnoopen, cfgdev.controlphantomen, cfgdev.controlurerrreportingen, cfgdev.id, cfgdev.statuscorrerrdetected, cfgdev.statusfatalerrdetected, cfgdev.statusnonfatalerrdetected, cfgdev.statusurdetected, cfgds.busnumber, cfgds.devicenumber, cfgds.functionnumber, cfgds.n, cfgerr.acsn, cfgerr.aerheaderlog, cfgerr.aerheaderlogsetn, cfgerr.atomicegressblockedn, cfgerr.corn, cfgerr.cplabortn, cfgerr.cplrdyn, cfgerr.cpltimeoutn, cfgerr.cplunexpectn, cfgerr.ecrcn, cfgerr.internalcorn, cfgerr.internaluncorn, cfgerr.lockedn, cfgerr.malformedn, cfgerr.mcblockedn, cfgerr.norecoveryn, cfgerr.poisonedn, cfgerr.postedn, cfgerr.tlpcplheader, cfgerr.urn, cfgforce.commonclockoff, cfgforce.extendedsyncon, cfgforce.mps, cfginterrupt.assertn, cfginterrupt.di, cfginterrupt.do, cfginterrupt.mmenable, cfginterrupt.msienable, cfginterrupt.msixenable, cfginterrupt.msixfm, cfginterrupt.n, cfginterrupt.rdyn, cfginterrupt.statn, cfglink.controlaspmcontrol, cfglink.controlautobandwidthinten, cfglink.controlbandwidthinten, cfglink.controlclockpmen, cfglink.controlcommonclock, cfglink.controlextendedsync, cfglink.controlhwautowidthdis, cfglink.controllinkdisable, cfglink.controlrcb, cfglink.controlretrainlink, cfglink.statusautobandwidthstatus, cfglink.statusbandwidthstatus, cfglink.statuscurrentspeed, cfglink.statusdllactive, cfglink.statuslinktraining, cfglink.statusnegotiatedwidth, cfgmgmt.byteenn, cfgmgmt.di, cfgmgmt.do, cfgmgmt.dwaddr, cfgmgmt.rdenn, cfgmgmt.rdwrdonen, cfgmgmt.wrenn, cfgmgmt.wrreadonlyn, cfgmgmt.wrrw1casrwn, cfgmsg.data, cfgmsg.received, cfgmsg.receivedassertinta, cfgmsg.receivedassertintb, cfgmsg.receivedassertintc, cfgmsg.receivedassertintd, cfgmsg.receiveddeassertinta, cfgmsg.receiveddeassertintb, cfgmsg.receiveddeassertintc, cfgmsg.receiveddeassertintd, cfgmsg.receivederrcor, cfgmsg.receivederrfatal, cfgmsg.receivederrnonfatal, cfgmsg.receivedpmasnak, cfgmsg.receivedpmeto, cfgmsg.receivedpmetoack, cfgmsg.receivedpmpme, cfgmsg.receivedsetslotpowerlimit, cfgmsg.receivedunlock, cfgpciecapinterruptmsgnum, cfgpcielinkstate, cfgpm.csrpmeen, cfgpm.csrpmestatus, cfgpm.csrpowerstate, cfgpm.forcestate, cfgpm.forcestateenn, cfgpm.haltaspml0sn, cfgpm.haltaspml1n, cfgpm.sendpmeton, cfgpm.turnoffokn, cfgpm.waken, cfgpmr.cvasreql1n, cfgpmr.cventerl1n, cfgpmr.cventerl23n, cfgpmr.cvreqackn, cfgportnumber, cfgrevid, cfgroot.controlpmeinten, cfgroot.controlsyserrcorrerren, cfgroot.controlsyserrfatalerren, cfgroot.controlsyserrnonfatalerren, cfgslotcontrolelectromechilctlpulse, cfgsubsys.id, cfgsubsys.vendid, cfgtrans.action, cfgtrans.actionaddr, cfgtrans.actiontype, cfgtrnpendingn, cfgvctcvcmap, cfgvendid, cmrstn, cmstickyrstn, dbg.mode, dbg.sclra, dbg.sclrb, dbg.sclrc, dbg.sclrd, dbg.sclre, dbg.sclrf, dbg.sclrg, dbg.sclrh, dbg.sclri, dbg.sclrj, dbg.sclrk, dbg.submode, dbg.veca, dbg.vecb, dbg.vecc, dlrstn, drp.addr, drp.clk, drp.di, drp.do, drp.en, drp.rdy, drp.we, funclvlrstn, ll2.baddllperr, ll2.badtlperr, ll2.linkstatus, ll2.protocolerr, ll2.receivererr, ll2.replayroerr, ll2.replaytoerr, ll2.sendasreql1, ll2.sendenterl1, ll2.sendenterl23, ll2.sendpmack, ll2.suspendnow, ll2.suspendok, ll2.tfcinit1seq, ll2.tfcinit2seq, ll2.tlprcv, ll2.txidle, lnkclken, mim.rxraddr, mim.rxrdata, mim.rxren, mim.rxwaddr, mim.rxwdata, mim.rxwen, mim.txraddr, mim.txrdata, mim.txren, mim.txwaddr, mim.txwdata, mim.txwen, pipeclk, piperx0.chanisaligned, piperx0.charisk, piperx0.data, piperx0.elecidle, piperx0.phystatus, piperx0.polarity, piperx0.status, piperx0.valid, piperx1.chanisaligned, piperx1.charisk, piperx1.data, piperx1.elecidle, piperx1.phystatus, piperx1.polarity, piperx1.status, piperx1.valid, piperx2.chanisaligned, piperx2.charisk, piperx2.data, piperx2.elecidle, piperx2.phystatus, piperx2.polarity, piperx2.status, piperx2.valid, piperx3.chanisaligned, piperx3.charisk, piperx3.data, piperx3.elecidle, piperx3.phystatus, piperx3.polarity, piperx3.status, piperx3.valid, piperx4.chanisaligned, piperx4.charisk, piperx4.data, piperx4.elecidle, piperx4.phystatus, piperx4.polarity, piperx4.status, piperx4.valid, piperx5.chanisaligned, piperx5.charisk, piperx5.data, piperx5.elecidle, piperx5.phystatus, piperx5.polarity, piperx5.status, piperx5.valid, piperx6.chanisaligned, piperx6.charisk, piperx6.data, piperx6.elecidle, piperx6.phystatus, piperx6.polarity, piperx6.status, piperx6.valid, piperx7.chanisaligned, piperx7.charisk, piperx7.data, piperx7.elecidle, piperx7.phystatus, piperx7.polarity, piperx7.status, piperx7.valid, pipetx0.charisk, pipetx0.compliance, pipetx0.data, pipetx0.elecidle, pipetx0.powerdown, pipetx1.charisk, pipetx1.compliance, pipetx1.data, pipetx1.elecidle, pipetx1.powerdown, pipetx2.charisk, pipetx2.compliance, pipetx2.data, pipetx2.elecidle, pipetx2.powerdown, pipetx3.charisk, pipetx3.compliance, pipetx3.data, pipetx3.elecidle, pipetx3.powerdown, pipetx4.charisk, pipetx4.compliance, pipetx4.data, pipetx4.elecidle, pipetx4.powerdown, pipetx5.charisk, pipetx5.compliance, pipetx5.data, pipetx5.elecidle, pipetx5.powerdown, pipetx6.charisk, pipetx6.compliance, pipetx6.data, pipetx6.elecidle, pipetx6.powerdown, pipetx7.charisk, pipetx7.compliance, pipetx7.data, pipetx7.elecidle, pipetx7.powerdown, pipetxdeemph, pipetxmargin, pipetxrate, pipetxrcvrdet, pipetxreset, pl2.directedlstate, pl2.l0req, pl2.linkup, pl2.receivererr, pl2.recovery, pl2.rxelecidle, pl2.rxpmstate, pl2.suspendok, pl.dbgmode, pl.dbgvec, pl.directedchangedone, pl.directedlinkauton, pl.directedlinkchange, pl.directedlinkspeed, pl.directedlinkwidth, pl.directedltssmnew, pl.directedltssmnewvld, pl.directedltssmstall, pl.downstreamdeemphsource, pl.initiallinkwidth, pl.lanereversalmode, pl.ltssmstate, pl.phylnkupn, pl.receivedhotrst, pl.rstn, pl.rxpmstate, pl.sellnkrate, pl.sellnkwidth, pl.transmithotrst, pl.txpmstate, pl.upstreampreferdeemph, pllink.gen2cap, pllink.partnergen2supported, pllink.upcfgcap, receivedfunclvlrstn, sysrstn, tl2.aspmsuspendcreditcheck, tl2.aspmsuspendcreditcheckok, tl2.aspmsuspendreq, tl2.errfcpe, tl2.errhdr, tl2.errmalformed, tl2.errrxoverflow, tl2.ppmsuspendok, tl2.ppmsuspendreq, tlrstn, trn.fccpld, trn.fccplh, trn.fcnpd, trn.fcnph, trn.fcpd, trn.fcph, trn.fcsel, trn.lnkup, trn.rbarhit, trn.rd, trn.rdllpdata, trn.rdllpsrcrdy, trn.rdstrdy, trn.recrcerr, trn.reof, trn.rerrfwd, trn.rfcpret, trn.rnpok, trn.rnpreq, trn.rrem, trn.rsof, trn.rsrcdsc, trn.rsrcrdy, trn.tbufav, trn.tcfggnt, trn.tcfgreq, trn.td, trn.tdllpdata, trn.tdllpdstrdy, trn.tdllpsrcrdy, trn.tdstrdy, trn.tecrcgen, trn.teof, trn.terrdrop, trn.terrfwd, trn.trem, trn.tsof, trn.tsrcdsc, trn.tsrcrdy, trn.tstr, userclk, userclk2, userrstn) CF (cfgaer.ecrcchecken, cfgaer.ecrcgenen, cfgaer.interruptmsgnum, cfgaer.rooterrcorrerrreceived, cfgaer.rooterrcorrerrreportingen, cfgaer.rooterrfatalerrreceived, cfgaer.rooterrfatalerrreportingen, cfgaer.rooterrnonfatalerrreceived, cfgaer.rooterrnonfatalerrreportingen, cfgbridgeserren, cfgcommand.busmasterenable, cfgcommand.interruptdisable, cfgcommand.ioenable, cfgcommand.memenable, cfgcommand.serren, cfgdev.control2ariforwarden, cfgdev.control2atomicegressblock, cfgdev.control2atomicrequesteren, cfgdev.control2cpltimeoutdis, cfgdev.control2cpltimeoutval, cfgdev.control2idocplen, cfgdev.control2idoreqen, cfgdev.control2ltren, cfgdev.control2tlpprefixblock, cfgdev.controlauxpoweren, cfgdev.controlcorrerrreportingen, cfgdev.controlenablero, cfgdev.controlexttagen, cfgdev.controlfatalerrreportingen, cfgdev.controlmaxpayload, cfgdev.controlmaxreadreq, cfgdev.controlnonfatalreportingen, cfgdev.controlnosnoopen, cfgdev.controlphantomen, cfgdev.controlurerrreportingen, cfgdev.id, cfgdev.statuscorrerrdetected, cfgdev.statusfatalerrdetected, cfgdev.statusnonfatalerrdetected, cfgdev.statusurdetected, cfgds.busnumber, cfgds.devicenumber, cfgds.functionnumber, cfgds.n, cfgerr.acsn, cfgerr.aerheaderlog, cfgerr.aerheaderlogsetn, cfgerr.atomicegressblockedn, cfgerr.corn, cfgerr.cplabortn, cfgerr.cplrdyn, cfgerr.cpltimeoutn, cfgerr.cplunexpectn, cfgerr.ecrcn, cfgerr.internalcorn, cfgerr.internaluncorn, cfgerr.lockedn, cfgerr.malformedn, cfgerr.mcblockedn, cfgerr.norecoveryn, cfgerr.poisonedn, cfgerr.postedn, cfgerr.tlpcplheader, cfgerr.urn, cfgforce.commonclockoff, cfgforce.extendedsyncon, cfgforce.mps, cfginterrupt.assertn, cfginterrupt.di, cfginterrupt.do, cfginterrupt.mmenable, cfginterrupt.msienable, cfginterrupt.msixenable, cfginterrupt.msixfm, cfginterrupt.n, cfginterrupt.rdyn, cfginterrupt.statn, cfglink.controlaspmcontrol, cfglink.controlautobandwidthinten, cfglink.controlbandwidthinten, cfglink.controlclockpmen, cfglink.controlcommonclock, cfglink.controlextendedsync, cfglink.controlhwautowidthdis, cfglink.controllinkdisable, cfglink.controlrcb, cfglink.controlretrainlink, cfglink.statusautobandwidthstatus, cfglink.statusbandwidthstatus, cfglink.statuscurrentspeed, cfglink.statusdllactive, cfglink.statuslinktraining, cfglink.statusnegotiatedwidth, cfgmgmt.byteenn, cfgmgmt.di, cfgmgmt.do, cfgmgmt.dwaddr, cfgmgmt.rdenn, cfgmgmt.rdwrdonen, cfgmgmt.wrenn, cfgmgmt.wrreadonlyn, cfgmgmt.wrrw1casrwn, cfgmsg.data, cfgmsg.received, cfgmsg.receivedassertinta, cfgmsg.receivedassertintb, cfgmsg.receivedassertintc, cfgmsg.receivedassertintd, cfgmsg.receiveddeassertinta, cfgmsg.receiveddeassertintb, cfgmsg.receiveddeassertintc, cfgmsg.receiveddeassertintd, cfgmsg.receivederrcor, cfgmsg.receivederrfatal, cfgmsg.receivederrnonfatal, cfgmsg.receivedpmasnak, cfgmsg.receivedpmeto, cfgmsg.receivedpmetoack, cfgmsg.receivedpmpme, cfgmsg.receivedsetslotpowerlimit, cfgmsg.receivedunlock, cfgpciecapinterruptmsgnum, cfgpcielinkstate, cfgpm.csrpmeen, cfgpm.csrpmestatus, cfgpm.csrpowerstate, cfgpm.forcestate, cfgpm.forcestateenn, cfgpm.haltaspml0sn, cfgpm.haltaspml1n, cfgpm.sendpmeton, cfgpm.turnoffokn, cfgpm.waken, cfgpmr.cvasreql1n, cfgpmr.cventerl1n, cfgpmr.cventerl23n, cfgpmr.cvreqackn, cfgportnumber, cfgrevid, cfgroot.controlpmeinten, cfgroot.controlsyserrcorrerren, cfgroot.controlsyserrfatalerren, cfgroot.controlsyserrnonfatalerren, cfgslotcontrolelectromechilctlpulse, cfgsubsys.id, cfgsubsys.vendid, cfgtrans.action, cfgtrans.actionaddr, cfgtrans.actiontype, cfgtrnpendingn, cfgvctcvcmap, cfgvendid, cmrstn, cmstickyrstn, dbg.mode, dbg.sclra, dbg.sclrb, dbg.sclrc, dbg.sclrd, dbg.sclre, dbg.sclrf, dbg.sclrg, dbg.sclrh, dbg.sclri, dbg.sclrj, dbg.sclrk, dbg.submode, dbg.veca, dbg.vecb, dbg.vecc, dlrstn, drp.addr, drp.clk, drp.di, drp.do, drp.en, drp.rdy, drp.we, funclvlrstn, ll2.baddllperr, ll2.badtlperr, ll2.linkstatus, ll2.protocolerr, ll2.receivererr, ll2.replayroerr, ll2.replaytoerr, ll2.sendasreql1, ll2.sendenterl1, ll2.sendenterl23, ll2.sendpmack, ll2.suspendnow, ll2.suspendok, ll2.tfcinit1seq, ll2.tfcinit2seq, ll2.tlprcv, ll2.txidle, lnkclken, mim.rxraddr, mim.rxrdata, mim.rxren, mim.rxwaddr, mim.rxwdata, mim.rxwen, mim.txraddr, mim.txrdata, mim.txren, mim.txwaddr, mim.txwdata, mim.txwen, pipeclk, piperx0.chanisaligned, piperx0.charisk, piperx0.data, piperx0.elecidle, piperx0.phystatus, piperx0.polarity, piperx0.status, piperx0.valid, piperx1.chanisaligned, piperx1.charisk, piperx1.data, piperx1.elecidle, piperx1.phystatus, piperx1.polarity, piperx1.status, piperx1.valid, piperx2.chanisaligned, piperx2.charisk, piperx2.data, piperx2.elecidle, piperx2.phystatus, piperx2.polarity, piperx2.status, piperx2.valid, piperx3.chanisaligned, piperx3.charisk, piperx3.data, piperx3.elecidle, piperx3.phystatus, piperx3.polarity, piperx3.status, piperx3.valid, piperx4.chanisaligned, piperx4.charisk, piperx4.data, piperx4.elecidle, piperx4.phystatus, piperx4.polarity, piperx4.status, piperx4.valid, piperx5.chanisaligned, piperx5.charisk, piperx5.data, piperx5.elecidle, piperx5.phystatus, piperx5.polarity, piperx5.status, piperx5.valid, piperx6.chanisaligned, piperx6.charisk, piperx6.data, piperx6.elecidle, piperx6.phystatus, piperx6.polarity, piperx6.status, piperx6.valid, piperx7.chanisaligned, piperx7.charisk, piperx7.data, piperx7.elecidle, piperx7.phystatus, piperx7.polarity, piperx7.status, piperx7.valid, pipetx0.charisk, pipetx0.compliance, pipetx0.data, pipetx0.elecidle, pipetx0.powerdown, pipetx1.charisk, pipetx1.compliance, pipetx1.data, pipetx1.elecidle, pipetx1.powerdown, pipetx2.charisk, pipetx2.compliance, pipetx2.data, pipetx2.elecidle, pipetx2.powerdown, pipetx3.charisk, pipetx3.compliance, pipetx3.data, pipetx3.elecidle, pipetx3.powerdown, pipetx4.charisk, pipetx4.compliance, pipetx4.data, pipetx4.elecidle, pipetx4.powerdown, pipetx5.charisk, pipetx5.compliance, pipetx5.data, pipetx5.elecidle, pipetx5.powerdown, pipetx6.charisk, pipetx6.compliance, pipetx6.data, pipetx6.elecidle, pipetx6.powerdown, pipetx7.charisk, pipetx7.compliance, pipetx7.data, pipetx7.elecidle, pipetx7.powerdown, pipetxdeemph, pipetxmargin, pipetxrate, pipetxrcvrdet, pipetxreset, pl2.directedlstate, pl2.l0req, pl2.linkup, pl2.receivererr, pl2.recovery, pl2.rxelecidle, pl2.rxpmstate, pl2.suspendok, pl.dbgmode, pl.dbgvec, pl.directedchangedone, pl.directedlinkauton, pl.directedlinkchange, pl.directedlinkspeed, pl.directedlinkwidth, pl.directedltssmnew, pl.directedltssmnewvld, pl.directedltssmstall, pl.downstreamdeemphsource, pl.initiallinkwidth, pl.lanereversalmode, pl.ltssmstate, pl.phylnkupn, pl.receivedhotrst, pl.rstn, pl.rxpmstate, pl.sellnkrate, pl.sellnkwidth, pl.transmithotrst, pl.txpmstate, pl.upstreampreferdeemph, pllink.gen2cap, pllink.partnergen2supported, pllink.upcfgcap, receivedfunclvlrstn, sysrstn, tl2.aspmsuspendcreditcheck, tl2.aspmsuspendcreditcheckok, tl2.aspmsuspendreq, tl2.errfcpe, tl2.errhdr, tl2.errmalformed, tl2.errrxoverflow, tl2.ppmsuspendok, tl2.ppmsuspendreq, tlrstn, trn.fccpld, trn.fccplh, trn.fcnpd, trn.fcnph, trn.fcpd, trn.fcph, trn.fcsel, trn.lnkup, trn.rbarhit, trn.rd, trn.rdllpdata, trn.rdllpsrcrdy, trn.rdstrdy, trn.recrcerr, trn.reof, trn.rerrfwd, trn.rfcpret, trn.rnpok, trn.rnpreq, trn.rrem, trn.rsof, trn.rsrcdsc, trn.rsrcrdy, trn.tbufav, trn.tcfggnt, trn.tcfgreq, trn.td, trn.tdllpdata, trn.tdllpdstrdy, trn.tdllpsrcrdy, trn.tdstrdy, trn.tecrcgen, trn.teof, trn.terrdrop, trn.terrfwd, trn.trem, trn.tsof, trn.tsrcdsc, trn.tsrcrdy, trn.tstr, userclk, userclk2, userrstn);
endmodule
