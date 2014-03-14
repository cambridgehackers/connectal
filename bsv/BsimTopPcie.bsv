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

import Vector            :: *;
import Connectable       :: *;
import Xilinx            :: *;
import RegFile           :: *;

import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiSlaveEngine    :: *;
import PortalEngine      :: *;


module mkBsimTop(Empty);
   

   RegFile#(Bit#(11), Bit#(192)) tlp_trace <- mkRegFileFullLoad("testdata.dat");
   
   PortalTop#(40,64,Empty)  portalTop <- mkPortalTop;
   AxiSlaveEngine#(64) axiSlaveEngine <- mkAxiSlaveEngine(unpack(0));
   PortalEngine          portalEngine <- mkPortalEngine(unpack(0));
   
   mkConnection(portalTop.m_axi, axiSlaveEngine.slave3);
   mkConnection(portalEngine.portal, portalTop.ctrl);
   
   Reg#(Bit#(11)) ptr <- mkReg(1);
   
   rule dump if (ptr+1 != 0);
      ptr <= ptr+1;
      
      let lineitem = tlp_trace.sub(ptr);
      Bit#(160) dataline = truncate(lineitem);
      
      Bit#(8) portnum = dataline[159:152] >> 1;
      Bit#(4) tlpsof  = dataline[155:152] & 4'b1;
      Bit#(8) pkttype = dataline[127:120] & 8'h1f;
      
      Bit#(32) seqno  = lineitem[191:160];  
      
      if (portnum == 4)
         $write("RX");
      else if (portnum == 8)
         $write("TX");
      else
	 $write("__");
      
      if (tlpsof == 0)
         $write("cc: ");
      else if (pkttype == 10)
         $write("pp: ");
      else
	 $write("qq: ");

      $write("JJ ");
      $write("%h ", seqno);
      $display("%h", dataline);
   endrule
   
   rule quit if (ptr+1 == 0);
      $finish;
   endrule
   
endmodule
