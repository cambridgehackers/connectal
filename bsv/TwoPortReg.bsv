//-------------------------------------------------------------------------
//
// TwoPortReg.bsv
//
// A register which can be read and updated twice, in sequence
//
// Original Author:  Jacob Schwartz
// Original Date:  June 18, 2010
//
// Copyright (c) 2010-2011, Bluespec, Inc.
//
//-------------------------------------------------------------------------

package TwoPortReg;

export TwoPortReg(..), get_portA, get_portB;
export mkTwoPortReg;
export mkBypassReg;


// ----------------------------------------------------------------
// interface TwoPortReg
//
interface TwoPortReg#(type data_type);
   interface   Reg#(data_type)   portA;
   interface   Reg#(data_type)   portB;
endinterface: TwoPortReg


// get_portA
//
// Convenience function, for getting portA
// (to be used as an argument to a function like "map")
//
function Reg#(ty) get_portA(TwoPortReg#(ty) ifc) = ifc.portA;


// get_portB
//
// Convenience function, for getting portB
// (to be used as an argument to a function like "map")
//
function Reg#(ty) get_portB(TwoPortReg#(ty) ifc) = ifc.portB;


// ----------------------------------------------------------------
// module mkTwoPortReg
//
module mkTwoPortReg #(data_type init_val) (TwoPortReg#(data_type))
 provisos (Bits#(data_type, data_type_size));

   // This is the actual hardware register which will record the state
   // at clock boundaries
   //
   Reg #(data_type)     r_register0     <- mkReg(init_val);

   // This is virtual register that portA writes to and portB reads from.
   // If portA doesn't write a value, it defaults to the value of register0.
   //
   Reg #(data_type)     w_register1     <- mkDWireSBR(r_register0);

   // This is the virtual register that portB writes to.
   // If portB doesn't write a value, it defaults to the value of register1.
   //
   Reg #(data_type)     w_register2     <- mkDWireSBR(w_register1);

   // A rule to read the final value of "w_register2" and write it into the
   // state ("r_register0") for the next clock clock.  For correctness, this
   // rule must always execute; thus the attributes.
   //
`ifdef GATE_CLOCKS
`define ATTRS fire_when_enabled
`else
`define ATTRS fire_when_enabled, no_implicit_conditions
`endif
   (* `ATTRS *)
   rule write_register_value;
      r_register0 <= w_register2;
   endrule   

   interface  Reg  portA;
      method   _read   = r_register0._read;
      method   _write  = w_register1._write;
   endinterface

   interface  Reg  portB;
      method   _read   = w_register1._read;
      method   _write  = w_register2._write;
   endinterface

endmodule: mkTwoPortReg


// ----------------------------------------------------------------
// mkBypassReg
//
// A simpler interface when you just want Port A write and Port B read.
//
module mkBypassReg#(data_t init_val) (Reg#(data_t))
   provisos (Bits#(data_t, data_size_t));

   (* hide *)
   TwoPortReg#(data_t) rr <- mkTwoPortReg(init_val);

   method _write = rr.portA._write;
   method _read  = rr.portB._read;

endmodule


// ----------------------------------------------------------------

// mkDWireSBR
//
// A version of mkDWire that can be written by multiple rules
// (by using mkRWireSBR rather than mkRWire)
//
module mkDWireSBR#(data_t dflt) (Wire#(data_t))
   provisos (Bits#(data_t, data_t_size));

   (* hide *)
   RWire#(data_t) _wire <- mkRWireSBR();

   method data_t _read();
      if (_wire.wget() matches (tagged Valid .value))
         return value;
      else
         return dflt;
   endmethod
   method Action _write(data_t new_value);
      _wire.wset(new_value);
   endmethod

endmodule

// ----------------------------------------------------------------

endpackage: TwoPortReg
