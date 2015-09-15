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
module mkBramSpec (BRAM2Port#(addr, data))
   provisos(Bits#(addr, asz), Bits#(data, dsz), Bounded#(addr));

   RegFile#(addr, data) regFile <- mkRegFileFull();
   Vector#(2,FIFO#(BRAMRequest#(addr,data))) reqFifo <- replicateM(mkFIFO());
   Vector#(2, FIFO#(data))              responseFifo <- replicateM(mkFIFO());

   for (Integer i = 0; i < 2; i = i + 1)
       rule process;
	  let req <- toGet(reqFifo[i]).get();
	  if (req.write) begin
	     //$display("mkBramSpec: write address=%h data=%h", req.address, req.datain);
	     regFile.upd(req.address, req.datain);
	     if (req.responseOnWrite)
		responseFifo[i].enq(req.datain);
	  end
	  else begin
	     let d = regFile.sub(req.address);
	     //$display("mkBramSpec: read address=%h data=%h", req.address, d);
	     responseFifo[i].enq(d);
	     end
       endrule
   interface Server portA;
      interface Put request = toPut(reqFifo[0]);
      interface Get response = toGet(responseFifo[0]);
   endinterface
   interface Server portB;
      interface Put request = toPut(reqFifo[1]);
      interface Get response = toGet(responseFifo[1]);
   endinterface

endmodule

////////////////////
// Implementation //
////////////////////

module mkBramStd(BRAM2Port#(addr,data))
   provisos(Bits#(addr, asz), Bits#(data, dsz));
   let cfg = defaultValue;
   cfg.latency = 2;
   let bram <- mkBRAM2Server(cfg);
   return bram;
endmodule

module mkBramImpl(BRAM2Port#(addr,data))
   provisos(Bits#(addr, asz), Bits#(data, dsz));
   let cfg = defaultValue;
   cfg.latency = 2;
   let bram <- ConnectalBram::mkBRAM2Server(cfg);
   return bram;
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
  BRAM2Port#(Bit#(2),Bit#(8)) spec <- mkBramStd();

  /* Implmentation instance */
  BRAM2Port#(Bit#(2),Bit#(8)) imp <- mkBramImpl();

   Ensure ensure <- getEnsure;

   equivf(4, "reqA"    , spec.portA.request.put    , imp.portA.request.put);
   equivf(2, "respA"   , spec.portA.response.get   , imp.portA.response.get);
   equivf(4, "reqB"    , spec.portB.request.put    , imp.portB.request.put);
   equivf(2, "respB"   , spec.portB.response.get   , imp.portB.response.get);
   // prop("prop1"  , prop1); // deadlocks
   parallel(list("reqA", "reqB"));
endmodule

module [Module] testBram ();
  blueCheck(checkBram);
endmodule
module [Module] testBramID ();
  Clock clk <- exposeCurrentClock;
  MakeResetIfc r <- mkReset(0, True, clk);
  blueCheckID(checkBram(reset_by r.new_rst), r);
endmodule
