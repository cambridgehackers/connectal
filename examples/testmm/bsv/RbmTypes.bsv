// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

typedef 20 MMSize;

`ifdef DataBusWidth
typedef TDiv#(`DataBusWidth,32) N;
`else
`ifndef N_VALUE
typedef 2 N;
`else
typedef `N_VALUE N;
`endif
`endif

`ifndef J_VALUE
typedef 2 J;
`else
typedef `J_VALUE J;
`endif
`ifndef K_VALUE
typedef 2 K;
`else
typedef `K_VALUE K;
`endif

typedef TMin#(4,J) RowsPerTile;
typedef TDiv#(J,RowsPerTile) T;

typedef 16 BurstLen;
typedef TMul#(32,N) DmaSz;

typedef enum {
   DmaConfigPortal,
   DmaIndicationPortal,
   MmIndicationPortal,
   MmRequestPortal,
   RbmIndicationPortal,
   RbmRequestPortal,
   SigmoidIndicationPortal,
   SigmoidRequestPortal,
   TimerIndicationPortal,
   TimerRequestPortal,
   FpMacRequestPortal,
   FpMacIndicationPortal,
   MmDebugRequestPortal,
   MmDebugIndicationPortal
} IfcNames deriving (Eq,Bits);

interface MmIndication;
   method Action mmfDone(Bit#(64) cycles);
endinterface

interface MmRequest;
   method Action mmf(Bit#(32) inPointer1, Bit#(32) r1, Bit#(32) c1,
		     Bit#(32) inPointer2, Bit#(32) r2, Bit#(32) c2,
		     Bit#(32) outPointer);
endinterface   

interface SigmoidIndication;
   method Action sigmoidDone();
   method Action sigmoidTableSize(Bit#(32) size);
   method Action sigmoidTableUpdated(Bit#(32) addr);
endinterface

interface SigmoidRequest;
    method Action sigmoid(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
    method Action setSigmoidLimits(Bit#(32) rscale, Bit#(32) llimit, Bit#(32) ulimit);
    method Action sigmoidTableSize();
    method Action updateSigmoidTable(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) numElts);
endinterface

interface RbmIndication;
   method Action statesDone();
   method Action statesDone2();
   method Action updateWeightsDone();
   method Action sumOfErrorSquared(Bit#(32) error);
   method Action dbg(Bit#(32) a, Bit#(32) b, Bit#(32) c, Bit#(32) d);
endinterface

interface RbmRequest;
   method Action sglist(Bit#(32) off, Bit#(40) addr, Bit#(32) len);
   method Action paref(Bit#(32) addr, Bit#(32) len);

   method Action bramMmf(Bit#(32) inPointer1, Bit#(32) r1, Bit#(32) c1,
			 Bit#(32) inPointer2, Bit#(32) r2, Bit#(32) c2,
			 Bit#(32) outPointer);
   method Action toBram(Bit#(32) off, Bit#(32) pointer, Bit#(32) offset, Bit#(32) numElts);
   method Action fromBram(Bit#(32) off, Bit#(32) pointer, Bit#(32) offset, Bit#(32) numElts);

    method Action computeStates(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);
    method Action computeStates2(Bit#(32) readPointer, Bit#(32) readOffset, Bit#(32) readPointer2, Bit#(32) readOffset2,
				 Bit#(32) writePointer, Bit#(32) writeOffset, Bit#(32) numElts);

    method Action updateWeights(Bit#(32) posAssociationsPointer, Bit#(32) negAssociationsPointer, Bit#(32) weightsPointer, Bit#(32) numElts, Bit#(32) learningRateOverNumExamples);

    method Action sumOfErrorSquared(Bit#(32) dataPointer, Bit#(32) predPointer, Bit#(32) numElts);

    method Action dbg(); 
    method Action finish(); // for bsim only
endinterface

interface MmDebugRequest;
   method Action debug();
endinterface

interface MmDebugIndication;
   method Action started();
   method Action startSourceAndSink(UInt#(32) startA, UInt#(32) startC, Int#(32) jint);
   method Action debug(Bit#(32) aNotEmpty, Bit#(32) bNotEmpty, Bit#(32) macCount, Bit#(32) mmtilesANotEmpty, Bit#(32) mmtilesBNotEmpty, Bit#(64) chans);
endinterface
