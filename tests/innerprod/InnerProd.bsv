
import GetPut::*;
import Clocks::*;
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import BRAM::*;
import BRAMFIFO::*;
import DefaultValue::*;

import Pipe::*;
import HostInterface::*;
import Dsp48E1::*;
import InnerProdInterface::*;
import ConnectalBramFifo::*;

`ifdef NUMBER_OF_TILES 
typedef `NUMBER_OF_TILES NumTiles;
`else
typedef 256 NumTiles;
`endif
`ifdef TILES_PER_MACRO
typedef `TILES_PER_MACRO NumTilesPerMacro;
`else
typedef 16 NumTilesPerMacro;
`endif
typedef struct {
   Int#(16) v;
   Bool first;
   Bool last;
   Bool update;
   } InnerProdParam deriving (Bits);
typedef Tuple2#(Int#(16),Int#(16))           InnerProdResponse;
typedef TDiv#(NumTiles,NumTilesPerMacro) NumMacroTiles;
typedef Tuple2#(Bit#(TLog#(NumTilesPerMacro)),InnerProdParam) MacroTileRequest;

interface InnerProdSynth;
   interface InnerProdRequest request;
   interface Get#(InnerProdResponse)   response;
endinterface

interface InnerProd;
   interface InnerProdRequest request;
endinterface

interface InnerProdTile;
   interface PipeIn#(InnerProdParam) request;
   interface PipeOut#(InnerProdResponse) response;
   interface Reset                  resetOut;
endinterface

function PipeOut#(InnerProdResponse) getInnerProdResponsePipe(InnerProdTile tile); return tile.response; endfunction

(* synthesize *)
module mkInnerProdTile#(Int#(16) tile)(InnerProdTile);

   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let ipReset <- mkAsyncReset(1, reset, clock);
   let dsp <- mkDsp48E1(reset_by ipReset);

   //FIFOF#(InnerProdParam) reqFifo <- mkDualClockBramFIFOF(clock, ipReset, clock, ipReset);
   FIFOF#(InnerProdParam) reqFifo <- mkFIFOF();
   FIFOF#(InnerProdParam) req1Fifo <- mkFIFOF();
   BRAM1Port#(Bit#(10),Int#(16)) kernelBram <- mkBRAM1Server(defaultValue);
   Reg#(Bit#(10)) addrReg <- mkReg(0);
   FIFOF#(Int#(16)) responseFifo <- mkFIFOF(); //mkDualClockBramFIFOF(clock, ipReset, clock, ipReset);

   rule request_rule;
      let req <- toGet(reqFifo).get();

      let addr = addrReg + 1;
      if (req.update) begin
	 $display("tile %d: writing kernel addr=%d value=%d", tile, addrReg, req.v);
	 kernelBram.portA.request.put(BRAMRequest {write:True, responseOnWrite:False, address: addrReg, datain: req.v});
      end
      else begin
	 kernelBram.portA.request.put(BRAMRequest {write:False, responseOnWrite:False, address: addrReg, datain: 0});
	 req1Fifo.enq(req);
      end
      if (req.last)
	 addr = 0;
      addrReg <= addr;
   endrule

   rule process_rule;
      let req <- toGet(req1Fifo).get();
      let b <- kernelBram.portA.response.get();
      $display("tile %d: inner prod a=%h b=%h", tile, req.v, b);

      dsp.a(extend(pack(req.v)));
      dsp.b(extend(pack(b)));
      dsp.c(0);
      dsp.d(0);
      let opmode = 7'h25;
      if (req.first) opmode = 7'h05;
      dsp.opmode(opmode);
      dsp.inmode(0);
      dsp.alumode(0);
      dsp.last(pack(req.last));
   endrule

   rule responseRule;
      $display("InnerProdTile %d response.get %h", tile, dsp.p());
      responseFifo.enq(unpack(dsp.p()[23:8]));
   endrule

   function InnerProdResponse addTileNumber(Int#(16) v); return tuple2(tile, v); endfunction

   interface PipeIn request = toPipeIn(reqFifo);
   interface PipeOut response = mapPipe(addTileNumber, toPipeOut(responseFifo));
   interface ResetOut resetOut = ipReset;
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
   interface Vector#(numPipes,PipeIn#(InnerProdResponse)) inPipes;
   interface PipeOut#(InnerProdResponse)                  outPipe;
endinterface

module mkResponsePipes(ResponsePipes#(numPipes))
   provisos (FunnelPipesPipelined#(1, numPipes, InnerProdResponse, 2));

   Vector#(numPipes, FIFOF#(InnerProdResponse))                fifos <- replicateM(mkFIFOF);
   Vector#(numPipes, PipeOut#(InnerProdResponse))      responsePipes = map(toPipeOut, fifos);
   FunnelPipe#(1,numPipes,InnerProdResponse,2) funnelResponsePipe <- mkFunnelPipesPipelined(responsePipes);

   interface Vector  inPipes = map(toPipeIn, fifos);
   interface PipeOut outPipe = funnelResponsePipe[0];
endmodule

interface MacroTile;
   interface PipeIn#(MacroTileRequest) inPipe;
   interface PipeOut#(InnerProdResponse) outPipe;
   interface Reset                  resetOut;
endinterface

(* synthesize *)
module mkRequestPipesMTSynth(ReqPipes#(NumTilesPerMacro,InnerProdParam));
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
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();
   let trpReset <- mkAsyncReset(2, reset, clock);
   let topReset <- mkAsyncReset(2, reset, clock);
   ReqPipes#(NumTilesPerMacro,InnerProdParam) rp <- mkRequestPipesMTSynth(reset_by trpReset);
   ResponsePipes#(NumTilesPerMacro) op <- mkResponsePipesMTSynth(reset_by topReset);

   Reset tileReset <- mkAsyncReset(2, reset, clock);

   for (Integer t = 0; t < valueOf(NumTilesPerMacro); t = t + 1) begin
      let tile <- mkInnerProdTile(mt * fromInteger(valueOf(NumTilesPerMacro)) + fromInteger(t), reset_by tileReset);
      tileReset = tile.resetOut;
      mkConnection(rp.outPipes[t], tile.request, reset_by tileReset);
      mkConnection(tile.response, op.inPipes[t], reset_by tileReset);
   end

   FIFOF#(InnerProdResponse) responseFifo <- mkSizedFIFOF(valueOf(NumTilesPerMacro));
   rule responseRule;
      let tr <- toGet(op.outPipe).get();
      $display("responseFifo: mt=%d t=%d v=%h", mt, tpl_1(tr), tpl_2(tr));
      responseFifo.enq(tr);
   endrule

   interface PipeIn inPipe = rp.inPipe;
   interface PipeOut outPipe = toPipeOut(responseFifo); //op.outPipe;
   interface Reset resetOut = tileReset;
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
   FIFOF#(InnerProdResponse) bramFifo <- mkDualClockBramFIFOF(derivedClock, derivedReset, defaultClock, defaultReset, clocked_by derivedClock, reset_by derivedReset);

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   let rpReset <- mkAsyncReset(2, derivedReset, derivedClock);
   let opReset <- mkAsyncReset(2, derivedReset, derivedClock);
   ReqPipes#(NumMacroTiles,MacroTileRequest) rp <- mkRequestPipesSynth(clocked_by derivedClock, reset_by rpReset);
   ResponsePipes#(NumMacroTiles) op <- mkResponsePipesSynth(clocked_by derivedClock, reset_by opReset);

   Reset mtReset <- mkAsyncReset(2, derivedReset, derivedClock);
   for (Integer mt = 0; mt < valueOf(NumMacroTiles); mt = mt + 1) begin
      let macroTile <- mkMacroTile(fromInteger(mt), clocked_by derivedClock, reset_by mtReset);
      mtReset = macroTile.resetOut;
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
      method Action innerProd(Bit#(16) tile, Bit#(16) a, Bool first, Bool last, Bool update);
	 Bit#(TLog#(NumTilesPerMacro)) t = truncate(tile);
	 Bit#(TLog#(NumMacroTiles)) m = truncate(tile >> valueOf(TLog#(NumTilesPerMacro)));
	 tReg <= t;
	 mReg <= m;
	 bWire <= True;
	 $display("request.innerProd m=%d t=%d a=%h first=%d last=%d", m, t, a, first, last);
	 inputFifo.enq(tuple2(m, tuple2(t, InnerProdParam { v: unpack(a), first: first, last: last, update: update})));
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
      $display("indRule v=%x %h", t, v);
      ind.innerProd(pack(t), pack(v));
   endrule

   interface InnerProdRequest request = ip.request;
endmodule
