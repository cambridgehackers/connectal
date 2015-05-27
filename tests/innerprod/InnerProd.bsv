// Copyright (c) 2015 Connectal Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import GetPut::*;
import Clocks::*;
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import Gearbox::*;
import GetPut::*;
import Connectable::*;
import BRAM::*;
import BRAMFIFO::*;
import DefaultValue::*;

import MemTypes::*;
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
typedef TAdd#(1,TLog#(NumTiles)) TileNumSize;
typedef struct {
   Bit#(TileNumSize) tile;
   Int#(16) v;
   Bool first;
   Bool last;
   Bool update;
   } InnerProdParam deriving (Bits);
typedef Tuple2#(Int#(16),Int#(16))           InnerProdResponse;
typedef TDiv#(NumTiles,NumTilesPerMacro) NumMacroTiles;

interface InnerProdSynth;
   interface InnerProdRequest request;
   interface Vector#(1, MemReadClient#(DataBusWidth)) readClients;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) writeClients;
endinterface

interface InnerProd;
   interface InnerProdRequest request;
   interface Vector#(1, MemReadClient#(DataBusWidth)) readClients;
   interface Vector#(1, MemWriteClient#(DataBusWidth)) writeClients;
endinterface

interface InnerProdTile;
   interface PipeIn#(InnerProdParam) request;
   interface PipeOut#(InnerProdResponse) response;
   interface PipeOut#(InnerProdParam) requestNext;
   interface PipeIn#(InnerProdResponse) responseNext;
   interface Reset                  resetOut;
endinterface

function PipeOut#(InnerProdResponse) getInnerProdResponsePipe(InnerProdTile tile); return tile.response; endfunction


(* synthesize *)
module mkTileRequestFifo#(Clock derivedClock, Reset derivedReset, Clock defaultClock, Reset defaultReset)(FIFOF#(InnerProdParam));
   let dualClockFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);
   return dualClockFifo;
endmodule

(* synthesize *)
module mkTileResponseFifo#(Clock srcClock, Reset srcReset, Clock dstClock, Reset dstReset)(FIFOF#(InnerProdResponse));
   let dualClockFifo <- mkDualClockBramFIFOF(srcClock, srcReset, dstClock, dstReset, clocked_by srcClock, reset_by srcReset);
   return dualClockFifo;
endmodule

(* synthesize *)
module mkInnerProdTile#(Bit#(TileNumSize) tile, Bool hasNext)(InnerProdTile);

   let clock <- exposeCurrentClock;
   let reset <- exposeCurrentReset;
   let ipReset <- mkAsyncReset(10, reset, clock);
   let dsp <- mkDsp48E1(reset_by ipReset);

   //FIFOF#(InnerProdParam) reqFifo <- mkDualClockBramFIFOF(clock, ipReset, clock, ipReset);
   FIFOF#(InnerProdParam) reqFifo <- mkFIFOF();
   FIFOF#(InnerProdParam) req1Fifo <- mkFIFOF();
   BRAM1Port#(Bit#(10),Int#(16)) kernelBram <- mkBRAM1Server(defaultValue);
   Reg#(Bit#(10)) addrReg <- mkReg(0);
   FIFOF#(InnerProdResponse) responseFifo <- mkFIFOF(); //mkDualClockBramFIFOF(clock, ipReset, clock, ipReset);

   Reg#(InnerProdParam)     nextReqReg <- mkReg(unpack(0), reset_by ipReset);
   FIFOF#(InnerProdResponse) nextRespFifo <- mkFIFOF1(reset_by ipReset);

   Reg#(InnerProdParam) requestPipeReg <- mkReg(unpack(0), reset_by ipReset);
   Reg#(Bool)        isMyRequestReg <- mkReg(False, reset_by ipReset);
   Reg#(Bool)        validReg       <- mkReg(False, reset_by ipReset);

   rule request_rule;
      if (reqFifo.notEmpty()) begin
	 let req <- toGet(reqFifo).get();

	 //$display("tile %d req.tile=%d update=%d", tile, req.tile, req.update);
	 let addr = addrReg + 1;
	 if (req.update && req.tile == tile) begin
	    $display("tile %d: writing kernel addr=%d value=%d", tile, addrReg, req.v);
	    kernelBram.portA.request.put(BRAMRequest {write:True, responseOnWrite:False, address: addrReg, datain: req.v});
	 end
	 else if (req.tile == tile || req.tile == fromInteger(valueOf(NumTiles))) begin
	    kernelBram.portA.request.put(BRAMRequest {write:False, responseOnWrite:False, address: addrReg, datain: 0});
	    req1Fifo.enq(req);
	 end

	 if (req.tile != tile || req.tile == fromInteger(valueOf(NumTiles))) begin
	    nextReqReg <= req;
	    validReg <= True;
	 end

	 if (req.last)
	    addr = 0;
	 addrReg <= addr;
      end
      else begin
	 validReg <= False;
      end
   endrule

   rule process_rule;
      let req <- toGet(req1Fifo).get();
      let b <- kernelBram.portA.response.get();
      $display("tile %d: inner prod a=%h b=%h last=%d", tile, req.v, b, req.last);

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
      InnerProdResponse v = unpack(0);
      let valid = False;
      if (dsp.notEmpty() && !responseFifo.notFull()) begin
	 $display("tile %d dropping dsp.p due to full responseFifo", tile);
      end
      if (dsp.notEmpty()) begin
	 $display("InnerProdTile tile=%d dsp.p %h", tile, dsp.p());
	 Int#(16) uintTile = extend(unpack(tile));
	 v = tuple2(uintTile, unpack(dsp.p()[23:8]));
	 valid = True;
      end
      else if (nextRespFifo.notEmpty()) begin
	 v <- toGet(nextRespFifo).get();
	 $display("tile %d: nextResp tile=%d v=%h", tile, tpl_1(v), tpl_2(v));
	 valid = True;
      end
      if (valid)
	 responseFifo.enq(v);
   endrule

   interface PipeIn request = toPipeIn(reqFifo);
   interface PipeOut response = toPipeOut(responseFifo);
   interface PipeOut requestNext;
      method InnerProdParam first() if (validReg);
	 return nextReqReg;
      endmethod
      method Bool notEmpty();
	 return validReg;
      endmethod
   endinterface
   interface PipeIn responseNext = toPipeIn(nextRespFifo);
   interface ResetOut resetOut = ipReset;
endmodule

interface ReqPipes#(numeric type numPipes, numeric type typeNumSize, type reqType);
   interface PipeIn#(reqType)                     inPipe;
   interface Vector#(numPipes, PipeOut#(reqType)) outPipes;
endinterface

module mkRequestPipes(ReqPipes#(numPipes,TileNumSize,reqType))
   provisos (Bits#(reqType, a__));
   FIFOF#(reqType) syncIn <- mkFIFOF();

   PipeOut#(reqType)                   reqPipe = toPipeOut(syncIn);
   Vector#(numPipes,PipeOut#(reqType)) opipes <- mkForkVector(reqPipe);

   interface PipeIn inPipe = toPipeIn(syncIn);
   interface Vector outPipes = opipes;
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
   interface PipeIn#(InnerProdParam) inPipe;
   interface PipeOut#(InnerProdResponse) outPipe;
   interface Reset                  resetOut;
endinterface

(* synthesize *)
module mkMacroTile#(Bit#(TileNumSize) mt)(MacroTile);
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();
   let trpReset <- mkAsyncReset(10, reset, clock);
   let topReset <- mkAsyncReset(10, reset, clock);

   Reset tileReset <- mkAsyncReset(10, reset, clock);

   PipeIn#(InnerProdParam) tileRequestPipe;
   PipeOut#(InnerProdResponse) tileResponsePipe;
   PipeOut#(InnerProdParam) tileRequestNextPipe;
   PipeIn#(InnerProdResponse) tileResponseNextPipe;

   for (Integer t = 0; t < valueOf(NumTilesPerMacro); t = t + 1) begin
      let hasNext = t != (valueOf(NumTilesPerMacro) - 1);
      let tile <- mkInnerProdTile(mt * fromInteger(valueOf(NumTilesPerMacro)) + fromInteger(t), hasNext, reset_by tileReset);
      if (t == 0) begin
	 tileRequestPipe = tile.request;
	 tileResponsePipe = tile.response;
      end
      else begin
	 mkConnection(tileRequestNextPipe, tile.request, reset_by trpReset);
	 mkConnection(tile.response, tileResponseNextPipe, reset_by trpReset);
      end
      tileReset = tile.resetOut;
      tileRequestNextPipe = tile.requestNext;
      tileResponseNextPipe = tile.responseNext;
   end

   interface PipeIn inPipe = tileRequestPipe;
   interface PipeOut outPipe = tileResponsePipe;
   interface Reset resetOut = tileReset;
endmodule

// TLog#(kernelheight * rowlenbytes)
typedef 11 LineBufferAddrSize;

interface InnerProdDriver;
   interface Reg#(SGLId)                 readPointer;
   interface Reg#(SGLId)                 writePointer;
   interface Put#(IteratorConfig#(Bit#(16))) rowRequest;
   interface Put#(XYIteratorConfig#(Bit#(LineBufferAddrSize))) convRequest; // for testing
   interface BRAMClient#(Bit#(LineBufferAddrSize),Int#(16)) lineBufferReadClient;
   interface BRAMClient#(Bit#(LineBufferAddrSize),Int#(16)) lineBufferWriteClient;
   interface BRAMClient#(Bit#(LineBufferAddrSize),Int#(16)) topBufferReadClient;
   interface BRAMClient#(Bit#(LineBufferAddrSize),Int#(16)) topBufferWriteClient;
   interface PipeOut#(InnerProdParam) innerProdRequest;
   interface PipeIn#(InnerProdResponse) innerProdResponse;
   interface MemReadClient#(DataBusWidth) readClient;
   interface MemWriteClient#(DataBusWidth) writeClient;
endinterface

(* synthesize *)
module mkIPDriver(InnerProdDriver);
   let clock <- exposeCurrentClock();
   let reset <- exposeCurrentReset();
   FIFOF#(BRAMRequest#(Bit#(LineBufferAddrSize),Int#(16))) lineBufferRequestFifo <- mkFIFOF();
   FIFOF#(Int#(16))                                        lineBufferResponseFifo <- mkFIFOF();
   FIFOF#(BRAMRequest#(Bit#(LineBufferAddrSize),Int#(16))) lineBufferWriteFifo <- mkFIFOF();
   FIFOF#(BRAMRequest#(Bit#(LineBufferAddrSize),Int#(16))) topBufferRequestFifo <- mkFIFOF();
   FIFOF#(Int#(16))                                        topBufferResponseFifo <- mkFIFOF();
   FIFOF#(BRAMRequest#(Bit#(LineBufferAddrSize),Int#(16))) topBufferWriteFifo <- mkFIFOF();

   FIFOF#(InnerProdParam) innerProdRequestFifo <- mkFIFOF();
   FIFOF#(InnerProdResponse) innerProdResponseFifo <- mkFIFOF();
   FIFOF#(Tuple4#(Bool,Bool,Bit#(LineBufferAddrSize),Bit#(LineBufferAddrSize))) lastFifo <- mkFIFOF();

   FIFOF#(IteratorConfig#(Bit#(16))) rowRequestFifo <- mkFIFOF();
   FIFOF#(XYIteratorConfig#(Bit#(LineBufferAddrSize))) convRequestFifo <- mkFIFOF();
   XYIteratorIfc#(Bit#(LineBufferAddrSize)) convIterator <- mkXYIterator();
   XYIteratorIfc#(Bit#(LineBufferAddrSize)) ipIterator <- mkXYIterator();

   IteratorIfc#(Bit#(16)) imageIterator <- mkIterator();
   IteratorIfc#(Bit#(16)) rowIterator <- mkIterator();
   IteratorIfc#(Bit#(16)) colIterator <- mkIterator();
   IteratorWithContext#(Bit#(16),Bit#(16)) bramWriteIterator <- mkIteratorWithContext();

   IteratorIfc#(Bit#(16)) rowWriteBackIterator <- mkIterator();
   IteratorIfc#(Bit#(LineBufferAddrSize)) topBufferReadIterator <- mkIterator();


   Reg#(SGLId)           readPointerReg <- mkReg(0);
   Reg#(SGLId)          writePointerReg <- mkReg(0);
   Reg#(Bit#(3))                   tag <- mkReg(0);

   FIFO#(MemRequest) readReqFifo <- mkFIFO();
   FIFO#(MemData#(DataBusWidth)) readDataFifo <- mkSizedFIFO(8);
   Gearbox#(TDiv#(DataBusWidth,16), 1, Bit#(16))  readDataGearbox <- mkNto1Gearbox(clock, reset, clock, reset);

   Gearbox#(1, TDiv#(DataBusWidth,16), Bit#(16))  writeDataGearbox <- mk1toNGearbox(clock, reset, clock, reset);
   FIFO#(MemRequest)              writeReqFifo <- mkFIFO();
   FIFOF#(MemData#(DataBusWidth)) writeDataFifo <- mkSizedFIFOF(8);
   FIFO#(Bit#(MemTagSize))       writeDoneFifo <- mkFIFO();

   // fixme
   let kernelHeight = 4;
   let kernelWidth = 4;
   let kernelColAddrBits = 2;
   Bit#(16)                 imageSizeShift = 8;
   Bit#(16)                   rowLenBytes = 16;
   Bit#(BurstLenSize)       burstLenBytes = 16;
   Reg#(Bool)         enoughRowsCachedReg <- mkReg(False);

   rule startImagesRule;
      let req <- toGet(rowRequestFifo).get();
      $display("startImagesRule: xbase=%d xlimit=%d xstep=%d", req.xbase, req.xlimit, req.xstep);
      imageIterator.start(req);
   endrule
   rule startRowsRule;
      let imageNumber <- toGet(imageIterator.pipe).get();
      let req = IteratorConfig { xbase: imageNumber << imageSizeShift, xlimit: (imageNumber+1) << imageSizeShift, xstep: rowLenBytes };
      $display("startRowsRule: xbase=%d xlimit=%d xstep=%d", req.xbase, req.xlimit, req.xstep);
      rowIterator.start(req);
   endrule
   rule startReadRowRule;
      let rowStartBytes <- toGet(rowIterator.pipe).get();
      let rowNumber = rowIterator.count();
      $display("startReadRowRule: rowStartBytes=%d rowLenBytes=%d burstLenBytes=%d", rowStartBytes, rowLenBytes, burstLenBytes);
      // start iterator of DRAM read addresses
      colIterator.start(IteratorConfig {xbase: rowStartBytes, xlimit: rowStartBytes+rowLenBytes, xstep: extend(burstLenBytes) });
      // start iterator of BRAM write addresses
      bramWriteIterator.start(IteratorConfig {xbase: rowStartBytes>>1, xlimit: (rowStartBytes+rowLenBytes)>>1, xstep: 1 },
			      rowNumber);
   endrule

   rule startReadReqRule;
      let colOffsetBytes <- toGet(colIterator.pipe).get();
      $display("startReadReqRule: colOffsetBytes=%d", colOffsetBytes);
      readReqFifo.enq(MemRequest { sglId: readPointerReg, offset: extend(colOffsetBytes), burstLen: burstLenBytes, tag: extend(tag) });

      tag <= tag + 1;
   endrule
   rule dataGearboxRule;
      let d <- toGet(readDataFifo).get();
      readDataGearbox.enq(unpack(d.data));
   endrule
   rule bramWriteRule;
      let bramAddr <- toGet(bramWriteIterator.pipe).get();
      let rowNumber = bramWriteIterator.ctxt();
      Vector#(1,Bit#(16)) v = readDataGearbox.first(); readDataGearbox.deq();
      $display("bramWriteRule bramAddr=%d row=%d col=%d v=%h", bramAddr, bramAddr>>4, bramAddr & 'hf, v);
      lineBufferWriteFifo.enq(BRAMRequest{write: True, responseOnWrite: False, address: truncate(bramAddr), datain: unpack(v[0])});
      if (bramWriteIterator.isLast()) begin
	 // now OK to start convolutions for rows up to here
	 let enoughRowsCached = enoughRowsCachedReg;
	 if (!enoughRowsCached) begin
	    enoughRowsCached = rowNumber >= (kernelHeight-2);
	    if (!enoughRowsCachedReg && enoughRowsCached)
	       $display("bramWriteRule rowNumber=%d enoughRowsCached=%d enoughRowsCachedReg=%d", rowNumber, enoughRowsCached, enoughRowsCachedReg);
	    enoughRowsCachedReg <= enoughRowsCached;
	 end
	 $display("bramWriteRule: islast rowNumber=%d bramAddr=%d kernelHeight=%d enoughRowsCachedReg=%d", rowNumber, bramAddr, kernelHeight, enoughRowsCachedReg);
	 if (enoughRowsCachedReg) begin
	    convIterator.start(XYIteratorConfig {
					       xbase: truncate(rowNumber-kernelHeight+1), xlimit: truncate(rowNumber-kernelHeight+2), xstep: 1,
					       ybase: 0, ylimit: (truncate(rowLenBytes>>1)-kernelWidth), ystep: 1
					       });
	 end
      end
   endrule

   rule convRowRule;
      match { .rowNumber, .colNumber } <- toGet(convIterator.pipe).get();
      let req = XYIteratorConfig {
			       xbase: truncate(rowNumber), xlimit: truncate(rowNumber+1), xstep: 1,
			       ybase: colNumber, ylimit: colNumber+kernelHeight, ystep: 1
			       };
      ipIterator.start(req);
      $display("range startRule row=%d col=%d", rowNumber, colNumber);
   endrule

   rule issueBramReadRequest;
      match { .x, .y } <- toGet(ipIterator.pipe).get();
      // fixme: placeholder address computation
      let addr = (x << kernelColAddrBits) | y;
      lineBufferRequestFifo.enq(BRAMRequest{write: False, responseOnWrite: False, address: addr, datain: 0});
      lastFifo.enq(tuple4(ipIterator.isFirst(), ipIterator.isLast(), x, y));
      $display("issueBramReadRequest x=%d y=%d first=%d last=%d", x, y, ipIterator.isFirst(), ipIterator.isLast());
   endrule
   rule issueInnerProdRequest;
      let v <- toGet(lineBufferResponseFifo).get();
      match { .first, .last, .x, .y } <- toGet(lastFifo).get();
      let allTiles = fromInteger(valueOf(NumTiles));
      $display("issueInnerProdRequest v=%d x=%d y=%d first=%d last=%d", v, x, y, first, last);
      if (innerProdRequestFifo.notFull())
      innerProdRequestFifo.enq(InnerProdParam { tile: allTiles, v: v, first: first, last: last, update: False });
      else
	 $display("innerProdRequestFifo full");
   endrule

   Reg#(Bit#(TileNumSize)) responseCountReg <- mkReg(0);
   FIFO#(Bool) fooFifo <- mkFIFO();
   FIFO#(Bool) barFifo <- mkFIFO();
   rule innerProdResponseRule;
      let responseCount = responseCountReg;
      if (responseCount == 0)
	 responseCount = fromInteger(valueOf(NumTiles));
      match { .tile, .data } <- toGet(innerProdResponseFifo).get();
      $display("innerProdResponseRule count=%d tile=%d data=%h", responseCount, tile, data);
      topBufferWriteFifo.enq(BRAMRequest{write: True, responseOnWrite: False, address: truncate(pack(tile)), datain: data});

      if (responseCount == 1) begin
	 rowWriteBackIterator.start(IteratorConfig {xbase: 0, xlimit: fromInteger(valueOf(NumTiles)*2), xstep: fromInteger(valueOf(DataBusWidth)/8)});
	 topBufferReadIterator.start(IteratorConfig {xbase: 0, xlimit: fromInteger(valueOf(NumTiles)), xstep: 1});
      end
      responseCountReg <= responseCount - 1;
   endrule

   rule topBufferReadRule;
      let addr <- toGet(topBufferReadIterator.pipe).get();
      $display("topBufferReadRule: addr=%h", addr);
      topBufferRequestFifo.enq(BRAMRequest{write: False, responseOnWrite: False, address: addr, datain: 0});
   endrule

   mkConnection(mapPipe(pack, toPipeOut(topBufferResponseFifo)), toPipeIn(writeDataGearbox));
   rule writeReqRule;
      let offset <- toGet(rowWriteBackIterator.pipe).get();
      let tag = 22;
      $display("writeReqRule: offset=%h", offset);
      writeReqFifo.enq(MemRequest { sglId: writePointerReg, offset: extend(offset), burstLen: fromInteger(valueOf(DataBusWidth)/8), tag: tag });
   endrule
   rule writeDataRule;
      let tag = 22;
      let v = pack(writeDataGearbox.first()); writeDataGearbox.deq();
      $display("writeDataRule: data=%h", v);
      writeDataFifo.enq(MemData { data: v, tag: tag });
   endrule
   rule writeDone;
      let tag <- toGet(writeDoneFifo).get();
   endrule

   interface Reg readPointer = readPointerReg;
   interface Reg writePointer = writePointerReg;
   interface rowRequest = toPut(rowRequestFifo);
   interface convRequest = toPut(convRequestFifo);
   interface innerProdRequest = toPipeOut(innerProdRequestFifo);
   interface innerProdResponse = toPipeIn(innerProdResponseFifo);
   interface BRAMClient lineBufferReadClient;
      interface request = toGet(lineBufferRequestFifo);
      interface response = toPut(lineBufferResponseFifo);
   endinterface
   interface BRAMClient lineBufferWriteClient;
      interface request = toGet(lineBufferWriteFifo);
      interface Put response;
	 method Action put(Int#(16) v);
	    $display("lineBufferWriteClient.response.put should never be called. v=%h", v);
	 endmethod
      endinterface
   endinterface
   interface BRAMClient topBufferReadClient;
      interface request = toGet(topBufferRequestFifo);
      interface response = toPut(topBufferResponseFifo);
   endinterface
   interface BRAMClient topBufferWriteClient;
      interface request = toGet(topBufferWriteFifo);
      interface Put response;
	 method Action put(Int#(16) v);
	    $display("topBufferWriteClient.response.put should never be called. v=%h", v);
	 endmethod
      endinterface
   endinterface
   interface MemReadClient readClient;
      interface Get readReq = toGet(readReqFifo);
      interface Put readData = toPut(readDataFifo);
   endinterface
   interface MemWriteClient writeClient;
      interface Get writeReq = toGet(writeReqFifo);
      interface Get writeData = toGet(writeDataFifo);
      interface Put writeDone = toPut(writeDoneFifo);
   endinterface
endmodule

(* synthesize *)
module mkRequestPipesSynth(ReqPipes#(NumMacroTiles,TileNumSize,InnerProdParam));
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

   let derivedReset <- mkAsyncReset(10, defaultReset, derivedClock);

   let optionalReset = derivedReset; // noReset

   BRAM2Port#(Bit#(LineBufferAddrSize),Int#(16)) lineBuffer <- mkBRAM2Server(defaultValue);
   BRAM2Port#(Bit#(LineBufferAddrSize),Int#(16)) topBuffer <- mkBRAM2Server(defaultValue);

   FIFOF#(InnerProdParam) inputFifo <- mkDualClockBramFIFOF(defaultClock, defaultReset, derivedClock, derivedReset);
   FIFOF#(InnerProdResponse) bramFifo <- mkTileResponseFifo(derivedClock, derivedReset, defaultClock, defaultReset);

   Reg#(Bit#(32)) cycles <- mkReg(0, clocked_by derivedClock, reset_by derivedReset);
   rule cyclesRule;
      cycles <= cycles+1;
   endrule

   let rpReset <- mkAsyncReset(10, defaultReset, derivedClock);
   let opReset <- mkAsyncReset(10, defaultReset, derivedClock);
   ReqPipes#(NumMacroTiles,TileNumSize,InnerProdParam) rp <- mkRequestPipesSynth(clocked_by derivedClock, reset_by rpReset);
   ResponsePipes#(NumMacroTiles) op <- mkResponsePipesSynth(clocked_by derivedClock, reset_by opReset);

   Reset mtReset <- mkAsyncReset(10, derivedReset, derivedClock);
   for (Integer mt = 0; mt < valueOf(NumMacroTiles); mt = mt + 1) begin
      let macroTile <- mkMacroTile(fromInteger(mt), clocked_by derivedClock, reset_by mtReset);
      mtReset = macroTile.resetOut;
      mkConnection(rp.outPipes[mt], macroTile.inPipe, clocked_by derivedClock, reset_by mtReset);
      mkConnection(macroTile.outPipe, op.inPipes[mt], clocked_by derivedClock, reset_by mtReset);
   end

   mkConnection(toPipeOut(inputFifo), rp.inPipe, clocked_by derivedClock, reset_by derivedReset);
   mkConnection(op.outPipe, toPipeIn(bramFifo), clocked_by derivedClock, reset_by derivedReset);

   Reg#(Bit#(TileNumSize)) tReg <- mkReg(0);
   Reg#(Bit#(TileNumSize)) mReg <- mkReg(0);
   Wire#(Bool) bWire <- mkDWire(False);
   rule foo if (bWire);
      $display("m=%d t=%d", mReg, tReg);
   endrule

   let ipDriver <- mkIPDriver();
   mkConnection(ipDriver.lineBufferReadClient, lineBuffer.portB);
   mkConnection(ipDriver.lineBufferWriteClient, lineBuffer.portA);
   mkConnection(ipDriver.topBufferReadClient, topBuffer.portB);
   mkConnection(ipDriver.topBufferWriteClient, topBuffer.portA);
   mkConnection(ipDriver.innerProdRequest, toPipeIn(inputFifo));
   mkConnection(toPipeOut(bramFifo), ipDriver.innerProdResponse);

   interface InnerProdRequest request;
      method Action write(Bit#(16) addr, Bit#(16) val);
	 lineBuffer.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: truncate(addr), datain: unpack(val)});
      endmethod
      method Action innerProd(Bit#(16) tile, Bit#(16) a, Bool first, Bool last, Bool update);
	 Bit#(TileNumSize) t = truncate(tile);
	 Bit#(TileNumSize) m = truncate(tile >> valueOf(TLog#(NumTilesPerMacro)));
	 tReg <= t;
	 mReg <= m;
	 bWire <= True;
	 $display("request.innerProd m=%d t=%d a=%h first=%d last=%d", m, t, a, first, last);
         // broadcast to all tiles
	 inputFifo.enq(InnerProdParam { tile: t, v: unpack(a), first: first, last: last, update: update});
      endmethod
      method Action startIndividualConv(Bit#(16) xbase, Bit#(16) xlimit, Bit#(16) ybase, Bit#(16) ylimit);
	 ipDriver.convRequest.put(XYIteratorConfig { xbase: truncate(xbase), xlimit: truncate(xlimit), xstep: 1,
						 ybase: truncate(ybase), ylimit: truncate(ylimit), ystep: 1 });
      endmethod
      method Action startConv(Bit#(32) rdptr, Bit#(32) wrptr, Bit#(16) xbase, Bit#(16) xlimit, Bit#(16) ybase, Bit#(16) ylimit);
	 ipDriver.readPointer <= truncate(rdptr);
	 ipDriver.writePointer <= truncate(wrptr);
      // fixme column bytes
	 ipDriver.rowRequest.put(IteratorConfig { xbase: truncate(xbase), xlimit: truncate(xlimit), xstep: 1 });
      endmethod
      method Action finish();
	 $dumpflush();
	 $finish();
      endmethod
   endinterface
   //interface Get response = toGet(bramFifo);
   interface Vector readClients = vec(ipDriver.readClient);
   interface Vector writeClients = vec(ipDriver.writeClient);
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

   interface InnerProdRequest request = ip.request;
   interface Vector       readClients = ip.readClients;
   interface Vector      writeClients = ip.writeClients;
endmodule
