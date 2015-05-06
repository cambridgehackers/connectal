
import GetPut::*;
import Clocks::*;
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;

import Pipe::*;
import HostInterface::*;
import Dsp48E1::*;
import InnerProdInterface::*;
import ConnectalBramFifo::*;

interface InnerProd;
   interface InnerProdRequest request;
endinterface

typedef Tuple4#(Int#(16),Int#(16),Bool,Bool) TileRequest;
typedef Int#(16)                             TileResponse;

interface InnerProdTile;
   interface PipeIn#(TileRequest) request;
   interface PipeOut#(TileResponse) response;
endinterface

function PipeOut#(TileResponse) getTileResponsePipe(InnerProdTile tile); return tile.response; endfunction

(* synthesize *)
module mkInnerProdTile(InnerProdTile);

   let dsp <- mkDsp48E1();
   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   FIFOF#(Tuple4#(Int#(16),Int#(16),Bool,Bool)) reqFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, defaultClock, defaultReset);
   FIFOF#(Int#(16)) responseFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, defaultClock, defaultReset);

   rule request_rule;
      let req <- toGet(reqFifo).get();
      match { .a, .b, .first, .last } = req;
      dsp.a(extend(pack(a)));
      dsp.b(extend(pack(b)));
      dsp.c(0);
      dsp.d(0);
      let opmode = 7'h25;
      if (first) opmode = 7'h05;
      dsp.opmode(opmode);
      dsp.inmode(0);
      dsp.alumode(0);
      dsp.last(pack(last));
   endrule

   rule responseRule;
      $display("InnerProdTile response.get %h", dsp.p());
      responseFifo.enq(unpack(dsp.p()[23:8]));
   endrule

   interface Put request = toPipeIn(reqFifo);
   interface Get response = toPipeOut(responseFifo);
endmodule

module mkInnerProd#(
`ifdef IMPORT_HOSTIF
		    HostInterface host,
`endif
		    InnerProdIndication ind)(InnerProd);

   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
`ifdef IMPORT_HOSTIF
   let derivedClock = host.derivedClock;
`else
   let derivedClock = defaultClock;
`endif
   let derivedReset <- mkAsyncReset(2, defaultReset, derivedClock);
   let optionalReset = derivedReset; // noReset

   FIFOF#(Tuple2#(Bit#(4),TileRequest)) syncIn <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);
   FIFOF#(Int#(16)) bramFifo <- mkDualClockBramFIFOF(derivedClock, derivedReset, defaultClock, defaultReset);
   let started <- mkFIFOF();

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   Vector#(16, InnerProdTile) tiles <- replicateM(mkInnerProdTile(clocked_by derivedClock, reset_by optionalReset));

   PipeOut#(Tuple2#(Bit#(4),TileRequest))              reqPipe = toPipeOut(syncIn);
   Vector#(1, PipeOut#(Tuple2#(Bit#(4),TileRequest))) reqPipe1 = vec(reqPipe);
   UnFunnelPipe#(1,16,TileRequest,2)                  reqPipes <- mkUnFunnelPipesPipelined(reqPipe1);
   
   Vector#(16, PipeOut#(TileResponse))           responsePipes = map(getTileResponsePipe, tiles);
   FunnelPipe#(1,16,TileResponse,2)               responsePipe <- mkFunnelPipesPipelined(responsePipes);

   for (Integer tile = 0; tile < 16; tile = tile + 1) begin
      rule syncRequestRule if (started.notEmpty());
	 let req <- toGet(reqPipes[tile]).get();
	 $display("syncRequestRule a=%h b=%h", tpl_1(req), tpl_2(req));
	 tiles[tile].request.enq(req);
      endrule
   end
   mkConnection(responsePipe[0], toPipeIn(bramFifo), clocked_by derivedClock, reset_by derivedReset);

   rule indRule;
      let r <- toGet(bramFifo).get();
      $display("%d: indRule v=%x %d", cycles, r, r);
      ind.innerProd(pack(r));
   endrule

   interface InnerProdRequest request;
      method Action innerProd(Bit#(16) tile, Bit#(16) a, Bit#(16) b, Bool first, Bool last);
	 $display("request.innerProd a=%h b=%h first=%d last=%d", a, b, first, last);
	 Bit#(4) t = truncate(tile);
	 syncIn.enq(tuple2(t, tuple4(unpack(a),unpack(b),first,last)));
	 if (last)
	    started.enq(True);
	 $display("start");
      endmethod
      method Action start();
      endmethod
      method Action finish();
	 $dumpflush();
	 $finish();
      endmethod
   endinterface
endmodule
