/* 
 * Copyright 2015 Matthew Naylor
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
 * ("CTSRD"), as part of the DARPA CRASH research programme.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249
 * ("MRC2"), as part of the DARPA MRC research programme.
 *
 * This software was developed by the University of Cambridge Computer
 * Laboratory as part of the Rigorous Engineering of Mainstream
 * Systems (REMS) project, funded by EPSRC grant EP/K008528/1.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 */

import Vector    :: *;
import BRAMCore  :: *;
import BlueCheck :: *;
import FShow     :: *;
import StmtFSM   :: *;
import Clocks    :: *;
import RegFile   :: *;
import GetPut    :: *;
import BRAM      :: *;
import FIFO      :: *;
import DefaultValue::*;

import ConnectalBram::*;

///////////////
// Interface //
///////////////

//////////////////
// Specfication //
//////////////////

/* Make a stack with space for 2^n elements of type a */
module mkBramSpec (BRAMServer#(addr, data))
   provisos(Bits#(addr, asz), Bits#(data, dsz), Bounded#(addr));

   RegFile#(addr, data) regFile <- mkRegFileFull();
   FIFO#(BRAMRequest#(addr,data)) reqFifo <- mkFIFO();
   FIFO#(data)     responseFifo <- mkFIFO();

   rule process;
      let req <- toGet(reqFifo).get();
      if (req.write) begin
	 //$display("mkBramSpec: write address=%h data=%h", req.address, req.datain);
	 regFile.upd(req.address, req.datain);
	 if (req.responseOnWrite)
	    responseFifo.enq(req.datain);
      end
      else begin
	 let d = regFile.sub(req.address);
	 //$display("mkBramSpec: read address=%h data=%h", req.address, d);
	 responseFifo.enq(d);
	 end
   endrule
   interface Put request = toPut(reqFifo);
   interface Get response = toGet(responseFifo);

endmodule

////////////////////
// Implementation //
////////////////////

module mkBramImpl(BRAMServer#(addr,data))
   provisos(Bits#(addr, asz), Bits#(data, dsz));
   let cfg = defaultValue;
   cfg.latency = 2;
   let bram <- ConnectalBram::mkBRAM2Server(cfg);
   interface request = bram.portA.request;
   interface response = bram.portA.response;
endmodule

/////////////////////////
// Equivalence testing //
/////////////////////////

instance FShow#(BRAMRequest#(a, d)) provisos (FShow#(a), FShow#(d), Bits#(a, asz), Bits#(d, dsz));
   function Fmt fshow(BRAMRequest#(a, d) req);
      return $format("<BRAMRequest ", req.write ? "write " : "read ", 
		     req.responseOnWrite ? "response " : "",
		     fshow(req.address),
		     req.write ? (fshow(" data=")+fshow(req.datain)) : fshow(""), ">");
   endfunction
endinstance


module [BlueCheck] checkBram ();
  /* Specification instance */
  BRAMServer#(Bit#(2),Bit#(8)) spec <- mkBramSpec();

  /* Implmentation instance */
  BRAMServer#(Bit#(2),Bit#(8)) imp <- mkBramImpl();

   Ensure ensure <- getEnsure;

   function Stmt prop1(BRAMRequest#(Bit#(2),Bit#(8)) req);
      return
      seq
	 spec.request.put(req);
	 imp.request.put(req);
	 if (!req.write || req.responseOnWrite)
	 action
	    let vspec <- spec.response.get();
	    let vimp  <- imp.response.get();
	    ensure(vspec == vimp);
	 endaction
      endseq;
   endfunction

  equiv("req"    , spec.request.put    , imp.request.put);
  equiv("resp"   , spec.response.get   , imp.response.get);
   // prop("prop1"  , prop1); // deadlocks
   parallel(list("req", "resp"));
endmodule

module [Module] testBram ();
  blueCheck(checkBram);
endmodule
module [Module] testBramID ();
  Clock clk <- exposeCurrentClock;
  MakeResetIfc r <- mkReset(0, True, clk);
  blueCheckID(checkBram(reset_by r.new_rst), r);
endmodule
