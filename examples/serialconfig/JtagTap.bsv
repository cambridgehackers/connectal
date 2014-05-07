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

// The Jtag state machine is copied from the Bluespec Small Examples Tap.bsv

import FIFO::*;
import JtagReg::*;

typedef enum {TapTestLogicReset, 
              TapRunTestIdle,
	      TapSelectDR, 
              TapCaptureDR,
	      TapShiftDR, 
              TapExit1DR,
              TapPauseDR,
              TapExit2DR,
              TapUpdateDR,
	      TapSelectIR, 
              TapCaptureIR,
	      TapShiftIR, 
              TapExit1IR,
              TapPauseIR,
              TapExit2IR,
	      TapUpdateIR} TapState deriving (Bits, Eq);

interface Tap;
   (* always_ready, always_enabled *) method Action tms(bit i);
   (* always_ready, always_enabled *) method Action tdi(bit i);
   (* always_ready, always_enabled *) method bit tdo();
				      method TapState getstate();
endinterface


Bit#(6) jtagIDCODE = 'b100000;
Bit#(6) jtagBYPASS = 'b111111;
Bit#(6) jtagEXTEST = 'b000000;
Bit#(6) jtagSAMPLE = 'b000001;

function String getStateString( TapState st );
    case (st)
       TapTestLogicReset: return "TestLogicReset";
       TapRunTestIdle: return "RunTestIdle";
       TapSelectDR: return "SelectDR"; 
       TapCaptureDR: return "CaptureDR";
       TapShiftDR: return "ShiftDR"; 
       TapExit1DR: return "Exit1DR";
       TapPauseDR: return "PauseDR";
       TapExit2DR: return "Exit2DR";
       TapUpdateDR: return "UpdateDR";
       TapSelectIR: return "SelectIR"; 
       TapCaptureIR: return "CaptureIR";
       TapShiftIR: return "ShiftIR"; 
       TapExit1IR: return "Exit1IR";
       TapPauseIR: return "PauseIR";
       TapExit2IR: return "Exit2IR";
       TapUpdateIR: return "UpdateIR";
       default: return "*unknown state*";
    endcase
endfunction

   
module mkTap#(Bit#(32) id)(Tap);
   Wire#(bit) wtdi <- mkWire();
   Wire#(bit) wtdo <- mkWire();
   Wire#(bit) wtms <- mkWire();
   
   Reg#(bit) tdoreg <- mkReg(?);
   Reg#(TapState) state <- mkReg(TapTestLogicReset);

   JtagReg#(bit) bypass <- mkJtagReg();
   JtagReg#(Bit#(32)) idreg <- mkReadOnlyJtagReg(id);
   JtagReg#(Bit#(6)) irreg <- mkJtagReg();

   
   function Rules genRule( TapState stHere, TapState st0, TapState st1 );
   // create a list of rules (even though we only have on rule here)
   return rules
		rule stateChange( state == stHere );
                   // for this state, goto st0 when tms=0, and st1 when tms=1
                   // wtms is global, so no need to pass it as an argument
                   if (wtms == 0) state <= st0;
                   else           state <= st1;
		endrule
	     endrules; // again the semicolon for "return <foo> ;"
   endfunction
   
   addRules( genRule( TapTestLogicReset, TapRunTestIdle, TapTestLogicReset));
   addRules( genRule( TapRunTestIdle, TapRunTestIdle, TapSelectDR));
   addRules( genRule( TapSelectDR, TapCaptureDR, TapSelectIR));
   addRules( genRule( TapCaptureDR, TapShiftDR, TapExit1DR));
   addRules( genRule( TapShiftDR, TapShiftDR, TapExit1DR));
   addRules( genRule( TapExit1DR, TapPauseDR, TapUpdateDR));
   addRules( genRule( TapPauseDR, TapPauseDR, TapExit2DR));
   addRules( genRule( TapExit2DR, TapShiftDR, TapUpdateDR));
   addRules( genRule( TapUpdateDR, TapRunTestIdle, TapSelectDR));
   addRules( genRule( TapSelectIR, TapCaptureIR, TapTestLogicReset));
   addRules( genRule( TapCaptureIR, TapShiftIR, TapExit1IR));
   addRules( genRule( TapShiftIR, TapShiftIR, TapExit1IR));
   addRules( genRule( TapExit1IR, TapPauseIR, TapUpdateIR));
   addRules( genRule( TapPauseIR, TapPauseIR, TapExit2IR));
   addRules( genRule( TapExit2IR, TapShiftIR, TapUpdateIR));
   addRules( genRule( TapUpdateIR, TapRunTestIdle, TapSelectDR));

   
   // noisy debug
   rule showState;
      $display("Current state is ", getStateString( state ) );
   endrule
   
   rule shiftin (state == TapShiftDR);
      case (irreg.r)
	 jtagIDCODE: idreg.shift(wtdi);
	 jtagBYPASS: bypass.shift(wtdi);
      endcase
      case (irreg.r)
	 jtagIDCODE: wtdo <= idreg.tdo;
	 jtagBYPASS: wtdo <= bypass.tdo;
      endcase
   endrule
	 
	 
   ////////////////////////////////////////////////////////
   method Action tdi( bit i );
      // write input directly to the tdi wire
      wtdi._write( i );
   endmethod

   method bit    tdo();
      // the output of the scan chain
      return wtdo;
   endmethod

   method Action tms( bit i );
      // write the state in
      wtms._write(i);
   endmethod

   method TapState getstate();
      return state;
   endmethod

endmodule
