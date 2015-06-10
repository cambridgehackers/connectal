
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

`ifdef NUMBER_OF_LEDS
typedef `NUMBER_OF_LEDS LedsWidth;
`else
`ifdef XILINX
`ifdef Artix7
typedef 4 LedsWidth;
`else
`ifdef BOARD_zybo
typedef 4 LedsWidth;
`else
`ifdef BOARD_zc706
typedef 4 LedsWidth;
`else
`ifdef BOARD_nfsume
typedef 2 LedsWidth;
`else
typedef 8 LedsWidth;
`endif
`endif
`endif
`endif
`elsif ALTERA
typedef 4 LedsWidth;
`elsif VSIM
typedef 4 LedsWidth;
`else
typedef 8 LedsWidth;
`endif
`endif

interface LEDS;
    method Bit#(LedsWidth) leds;
endinterface
