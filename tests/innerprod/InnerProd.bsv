
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

typedef 256 NumTiles;

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

interface ReqPipes;
   interface PipeIn#(Tuple2#(Bit#(TLog#(NumTiles)),TileRequest)) inPipe;
   interface Vector#(NumTiles, PipeOut#(TileRequest))            outPipes;
endinterface

(* synthesize *)
module mkRequestPipes#(Clock derivedClock, Reset derivedReset)(ReqPipes);
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;
   FIFOF#(Tuple2#(Bit#(TLog#(NumTiles)),TileRequest)) syncIn <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);

   PipeOut#(Tuple2#(Bit#(TLog#(NumTiles)),TileRequest))              reqPipe = toPipeOut(syncIn);
   Vector#(1, PipeOut#(Tuple2#(Bit#(TLog#(NumTiles)),TileRequest))) reqPipe1 = vec(reqPipe);
   UnFunnelPipe#(1,NumTiles,TileRequest,2)                  unfunnelReqPipes <- mkUnFunnelPipesPipelined(reqPipe1, clocked_by derivedClock, reset_by derivedReset);

   interface PipeIn inPipe = toPipeIn(syncIn);
   interface Vector outPipes = unfunnelReqPipes;
endmodule

interface ResponsePipes;
   interface Vector#(NumTiles,PipeIn#(TileResponse)) inPipes;
   interface PipeOut#(TileResponse)                  outPipe;
endinterface

(* synthesize *)
module mkResponsePipes(ResponsePipes);

   Vector#(NumTiles, FIFOF#(TileResponse))                fifos <- replicateM(mkFIFOF);
   Vector#(NumTiles, PipeOut#(TileResponse))      responsePipes = map(toPipeOut, fifos);
   FunnelPipe#(1,NumTiles,TileResponse,2)    funnelResponsePipe <- mkFunnelPipesPipelined(responsePipes);

   interface Vector  inPipes = map(toPipeIn, fifos);
   interface PipeOut outPipe = funnelResponsePipe[0];
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

   FIFOF#(Int#(16)) bramFifo <- mkDualClockBramFIFOF(derivedClock, derivedReset, defaultClock, defaultReset);
   let started <- mkFIFOF();

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   Vector#(NumTiles, InnerProdTile) tiles <- replicateM(mkInnerProdTile(clocked_by derivedClock, reset_by optionalReset));
   Vector#(NumTiles, PipeOut#(TileResponse)) tileOutPipes = map(getTileResponsePipe, tiles);
   let rp <- mkRequestPipes(derivedClock, derivedReset);
   let op <- mkResponsePipes(clocked_by derivedClock, reset_by derivedReset);

   for (Integer tile = 0; tile < valueOf(NumTiles); tile = tile + 1) begin
      rule syncRequestRule if (started.notEmpty());
	 let req <- toGet(rp.outPipes[tile]).get();
	 $display("syncRequestRule a=%h b=%h", tpl_1(req), tpl_2(req));
	 tiles[tile].request.enq(req);
      endrule
      mkConnection(tileOutPipes[tile], op.inPipes[tile], clocked_by derivedClock, reset_by derivedReset);
   end
   mkConnection(op.outPipe, toPipeIn(bramFifo), clocked_by derivedClock, reset_by derivedReset);

   rule indRule;
      let r <- toGet(bramFifo).get();
      $display("%d: indRule v=%x %d", cycles, r, r);
      ind.innerProd(pack(r));
   endrule

   interface InnerProdRequest request;
      method Action innerProd(Bit#(16) tile, Bit#(16) a, Bit#(16) b, Bool first, Bool last);
	 $display("request.innerProd a=%h b=%h first=%d last=%d", a, b, first, last);
	 Bit#(TLog#(NumTiles)) t = truncate(tile);
	 rp.inPipe.enq(tuple2(t, tuple4(unpack(a),unpack(b),first,last)));
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
