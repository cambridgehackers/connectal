package AuroraCommon;


`include "ConnectalProjectConfig.bsv"
import FIFO::*;
import Clocks :: *;
import DefaultValue :: *;
import Xilinx :: *;
import XilinxCells :: *;
import ConnectalXilinxCells::*;

typedef 8 AuroraExtCount;

(* always_enabled, always_ready *)
interface Aurora_Clock_Pins;
	//(* prefix = "", result = "" *)
	method Action gtx_clk_p(Bit#(1) v);
	//(* prefix = "", result = "" *)
	method Action gtx_clk_n(Bit#(1) v);
	
	interface Clock gtx_clk_p_deleteme_unused_clock;
	interface Clock gtx_clk_n_deleteme_unused_clock;
endinterface

interface AuroraExtImportIfc#(numeric type lanes);
	interface Clock aurora_clk0;
	interface Clock aurora_clk1;
	interface Clock aurora_clk2;
	interface Clock aurora_clk3;
	interface Reset aurora_rst0;
	interface Reset aurora_rst1;
	interface Reset aurora_rst2;
	interface Reset aurora_rst3;

	(* prefix = "" *)
	interface Aurora_Pins#(1) aurora0;
	(* prefix = "" *)
	interface Aurora_Pins#(1) aurora1;
	(* prefix = "" *)
	interface Aurora_Pins#(1) aurora2;
	(* prefix = "" *)
	interface Aurora_Pins#(1) aurora3;
	(* prefix = "" *)
	interface AuroraControllerIfc#(64) user0;
	(* prefix = "" *)
	interface AuroraControllerIfc#(64) user1;
	(* prefix = "" *)
	interface AuroraControllerIfc#(64) user2;
	(* prefix = "" *)
	interface AuroraControllerIfc#(64) user3;
endinterface

interface AuroraImportIfc#(numeric type lanes);
	interface Clock aurora_clk;
	interface Reset aurora_rst;
	(* prefix = "" *)
	interface Aurora_Pins#(lanes) aurora;
	(* prefix = "" *)
	interface AuroraControllerIfc#(TMul#(lanes,32)) user;
endinterface

interface AuroraControllerIfc#(numeric type width);
	interface Reset aurora_rst_n;
		
	method Bit#(1) channel_up;
	method Bit#(1) lane_up;
	method Bit#(1) hard_err;
	method Bit#(1) soft_err;
	method Bit#(8) data_err_count;

	method Action send(Bit#(width) tx);
	method ActionValue#(Bit#(width)) receive();
endinterface

(* always_enabled, always_ready *)
interface Aurora_Pins#(numeric type lanes);
	(* prefix = "", result = "RXN" *)
	method Action rxn_in(Bit#(lanes) rxn_i);
	(* prefix = "", result = "RXP" *)
	method Action rxp_in(Bit#(lanes) rxp_i);

	(* prefix = "", result = "TXN" *)
	method Bit#(lanes) txn_out();
	(* prefix = "", result = "TXP" *)
	method Bit#(lanes) txp_out();
endinterface

interface GtxClockImportIfc;
	interface Aurora_Clock_Pins aurora_clk;
	interface Clock gtx_clk_p_ifc;
	interface Clock gtx_clk_n_ifc;
endinterface

(* synthesize *)
module mkGtxClockImport (GtxClockImportIfc);
`ifndef SIMULATION
	B2C i_gtx_clk_p <- mkB2C();
	B2C i_gtx_clk_n <- mkB2C();

	interface Aurora_Clock_Pins aurora_clk;
	method Action gtx_clk_p(Bit#(1) v);
		i_gtx_clk_p.inputclock(v);
	endmethod
	method Action gtx_clk_n(Bit#(1) v);
		i_gtx_clk_n.inputclock(v);
	endmethod
	interface Clock gtx_clk_p_deleteme_unused_clock = i_gtx_clk_p.c; // These clocks are deleted from the netlist by the synth.tcl script
	interface Clock gtx_clk_n_deleteme_unused_clock = i_gtx_clk_n.c;
	endinterface
	//interface Clock gtx_clk = gtx_clk_i;
	interface Clock gtx_clk_p_ifc = i_gtx_clk_p.c;
	interface Clock gtx_clk_n_ifc = i_gtx_clk_n.c;
`else
	Clock clk <- exposeCurrentClock;
	
	interface Aurora_Clock_Pins aurora_clk;
	interface Clock gtx_clk_p_deleteme_unused_clock = clk; // These clocks are deleted from the netlist by the synth.tcl script
	interface Clock gtx_clk_n_deleteme_unused_clock = clk;
	endinterface
	//interface Clock gtx_clk = gtx_clk_i;
	interface Clock gtx_clk_p_ifc = clk;
	interface Clock gtx_clk_n_ifc = clk;
`endif
endmodule


endpackage: AuroraCommon
