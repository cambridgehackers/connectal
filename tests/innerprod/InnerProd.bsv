
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

typedef 64 NumTiles;
typedef 64 NumTilesPerMacro;
typedef TDiv#(NumTiles,NumTilesPerMacro) NumMacroTiles;
typedef Tuple2#(Bit#(TLog#(NumTilesPerMacro)),TileRequest) MacroTileRequest;


typedef Tuple4#(Int#(16),Int#(16),Bool,Bool) TileRequest;
typedef Tuple2#(Int#(16),Int#(16))           TileResponse;

interface InnerProdSynth;
   interface InnerProdRequest request;
   interface Get#(TileResponse)   response;
endinterface

interface InnerProd;
   interface InnerProdRequest request;
endinterface

interface InnerProdTile;
   interface PipeIn#(TileRequest) request;
   interface PipeOut#(TileResponse) response;
endinterface

function PipeOut#(TileResponse) getTileResponsePipe(InnerProdTile tile); return tile.response; endfunction

(* synthesize *)
module mkInnerProdTile#(Int#(16) tile)(InnerProdTile);

   let dsp <- mkDsp48E1();
   let defaultClock <- exposeCurrentClock();
   let defaultReset <- exposeCurrentReset();

   FIFOF#(Tuple4#(Int#(16),Int#(16),Bool,Bool)) reqFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, defaultClock, defaultReset);
   FIFOF#(Int#(16)) responseFifo <- mkFIFOF(); //mkDualClockBramFIFOF(defaultClock, defaultReset, defaultClock, defaultReset);

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
      $display("InnerProdTile %d response.get %h", tile, dsp.p());
      responseFifo.enq(unpack(dsp.p()[23:8]));
   endrule

   function TileResponse addTileNumber(Int#(16) v); return tuple2(tile, v); endfunction

   interface PipeIn request = toPipeIn(reqFifo);
   interface PipeOut response = mapPipe(addTileNumber, toPipeOut(responseFifo));
endmodule

interface ReqPipes#(numeric type numPipes, type reqType);
   interface PipeIn#(Tuple2#(Bit#(TLog#(numPipes)),reqType)) inPipe;
   interface Vector#(numPipes, PipeOut#(reqType))            outPipes;
endinterface

module mkRequestPipes(ReqPipes#(numPipes,reqType))
   provisos (FunnelPipesPipelined#(1, numPipes, reqType, 2),
	     Bits#(Tuple2#(Bit#(TLog#(numPipes)), reqType), a__),
	     Add#(1, c__, a__)
	     );
   FIFOF#(Tuple2#(Bit#(TLog#(numPipes)),reqType)) syncIn <- mkFIFOF();

   PipeOut#(Tuple2#(Bit#(TLog#(numPipes)),reqType))              reqPipe = toPipeOut(syncIn);
   Vector#(1, PipeOut#(Tuple2#(Bit#(TLog#(numPipes)),reqType))) reqPipe1 = vec(reqPipe);
   UnFunnelPipe#(1,numPipes,reqType,2)                  unfunnelReqPipes <- mkUnFunnelPipesPipelined(reqPipe1);

   interface PipeIn inPipe = toPipeIn(syncIn);
   interface Vector outPipes = unfunnelReqPipes;
endmodule

interface ResponsePipes#(numeric type numPipes);
   interface Vector#(numPipes,PipeIn#(TileResponse)) inPipes;
   interface PipeOut#(TileResponse)                  outPipe;
endinterface

module mkResponsePipes(ResponsePipes#(numPipes))
   provisos (FunnelPipesPipelined#(1, numPipes, TileResponse, 2));

   Vector#(numPipes, FIFOF#(TileResponse))                fifos <- replicateM(mkFIFOF);
   Vector#(numPipes, PipeOut#(TileResponse))      responsePipes = map(toPipeOut, fifos);
   //FunnelPipe#(1,numPipes,TileResponse,2)    funnelResponsePipe <- mkFunnelPipesPipelined(responsePipes);
   FIFOF#(TileResponse) responseFifo <- mkFIFOF();
   for (Integer i = 0; i < valueOf(numPipes); i = i + 1)
      mkConnection(responsePipes[i], toPipeIn(responseFifo));

   interface Vector  inPipes = map(toPipeIn, fifos);
   interface PipeOut outPipe = toPipeOut(responseFifo); //funnelResponsePipe[0];
endmodule

interface MacroTile;
   interface PipeIn#(MacroTileRequest) inPipe;
   interface PipeOut#(TileResponse) outPipe;
endinterface

(* synthesize *)
module mkRequestPipesMTSynth(ReqPipes#(NumTilesPerMacro,TileRequest));
   let rp <- mkRequestPipes();
   return rp;
endmodule

(* synthesize *)
module mkResponsePipesMTSynth(ResponsePipes#(NumTilesPerMacro));
   let op <- mkResponsePipes();
   return op;
endmodule

(* synthesize *)
module mkMacroTile#(Int#(16) mt)(MacroTile);
   ReqPipes#(NumTilesPerMacro,TileRequest) rp <- mkRequestPipesMTSynth();
   ResponsePipes#(NumTilesPerMacro) op <- mkResponsePipesMTSynth();

   for (Integer t = 0; t < valueOf(NumTilesPerMacro); t = t + 1) begin
      let tile <- mkInnerProdTile(mt * fromInteger(valueOf(NumTilesPerMacro)) + fromInteger(t));
      mkConnection(rp.outPipes[t], tile.request);
      mkConnection(tile.response, op.inPipes[t]);
   end

   FIFOF#(TileResponse) responseFifo <- mkSizedFIFOF(valueOf(NumTilesPerMacro));
   rule responseRule;
      let tr <- toGet(op.outPipe).get();
      $display("responseFifo: mt=%d t=%d v=%h", mt, tpl_1(tr), tpl_2(tr));
      responseFifo.enq(tr);
   endrule

   interface PipeIn inPipe = rp.inPipe;
   interface PipeOut outPipe = toPipeOut(responseFifo); //op.outPipe;
endmodule

(* synthesize *)
module mkRequestPipesSynth(ReqPipes#(NumMacroTiles,MacroTileRequest));
   let rp <- mkRequestPipes();
   return rp;
endmodule

(* synthesize *)
module mkResponsePipesSynth(ResponsePipes#(NumMacroTiles));
   let op <- mkResponsePipes();
   return op;
endmodule

(* synthesize *)
module mkInnerProdSynth#(Clock derivedClock)(InnerProdSynth);
   let defaultClock <- exposeCurrentClock;
   let defaultReset <- exposeCurrentReset;

   let derivedReset <- mkAsyncReset(2, defaultReset, derivedClock);

   let optionalReset = derivedReset; // noReset

   FIFOF#(Tuple2#(Bit#(TLog#(NumMacroTiles)),MacroTileRequest)) inputFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);
   FIFOF#(TileResponse) bramFifo <- mkDualClockBramFIFOF(derivedClock, derivedReset, defaultClock, defaultReset, clocked_by derivedClock, reset_by derivedReset);

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   ReqPipes#(NumMacroTiles,MacroTileRequest) rp <- mkRequestPipesSynth(clocked_by derivedClock, reset_by derivedReset);
   ResponsePipes#(NumMacroTiles) op <- mkResponsePipesSynth(clocked_by derivedClock, reset_by derivedReset);

   for (Integer mt = 0; mt < valueOf(NumMacroTiles); mt = mt + 1) begin
      let mtReset <- mkSyncReset(2, derivedReset, derivedClock);
      let macroTile <- mkMacroTile(fromInteger(mt), clocked_by derivedClock, reset_by mtReset);
      mkConnection(rp.outPipes[mt], macroTile.inPipe, clocked_by derivedClock, reset_by mtReset);
      mkConnection(macroTile.outPipe, op.inPipes[mt], clocked_by derivedClock, reset_by mtReset);
   end

   mkConnection(toPipeOut(inputFifo), rp.inPipe, clocked_by derivedClock, reset_by derivedReset);
   mkConnection(op.outPipe, toPipeIn(bramFifo), clocked_by derivedClock, reset_by derivedReset);

   Reg#(Bit#(TLog#(NumTilesPerMacro))) tReg <- mkReg(0);
   Reg#(Bit#(TLog#(NumMacroTiles))) mReg <- mkReg(0);
   Wire#(Bool) bWire <- mkDWire(False);
   rule foo if (bWire);
      $display("m=%d t=%d", mReg, tReg);
   endrule

   interface InnerProdRequest request;
      method Action innerProd(Bit#(16) tile, Bit#(16) a, Bit#(16) b, Bool first, Bool last);
	 Bit#(TLog#(NumTilesPerMacro)) t = truncate(tile);
	 Bit#(TLog#(NumMacroTiles)) m = truncate(tile >> valueOf(TLog#(NumTilesPerMacro)));
	 tReg <= t;
	 mReg <= m;
	 bWire <= True;
	 $display("request.innerProd m=%d t=%d a=%h b=%h first=%d last=%d", m, t, a, b, first, last);
	 inputFifo.enq(tuple2(m, tuple2(t, tuple4(unpack(a),unpack(b),first,last))));
      endmethod
      method Action start();
      endmethod
      method Action finish();
	 $dumpflush();
	 $finish();
      endmethod
   endinterface
   interface Get response = toGet(bramFifo);
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

   let ip <- mkInnerProdSynth(derivedClock);
   rule indRule;
      match { .t, .v } <- ip.response.get();
      $display("indRule v=%x %d", t, v);
      ind.innerProd(pack(t), pack(v));
   endrule

   interface InnerProdRequest request = ip.request;
endmodule
