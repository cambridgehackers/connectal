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
import GetPut            :: *;

import Portal            :: *;
import Leds              :: *;
import Top               :: *;
import AxiSlaveEngine    :: *;
import PcieSplitter      :: *;

// from SceMiDefines
typedef 4 BPB;

module mkBsimTop(Empty);

   RegFile#(Bit#(11), Bit#(192)) tlp_trace <- mkRegFileFullLoad("testdata.dat");
   
   PortalTop#(40,64,Empty)  portalTop <- mkPortalTop;
   AxiSlaveEngine#(64) axiSlaveEngine <- mkAxiSlaveEngine(unpack(0));

   let contentId = 0;
   let my_id = unpack(0);
   Reg#(UInt#(13)) max_read_req_bytes <- mkReg(128);
   Reg#(UInt#(13)) max_payload_bytes  <- mkReg(128);
   Reg#(Bit#(7))   rcb_mask           <- mkReg(7'h3f);
   Reg#(Bool)      msix_enable        <- mkReg(False);
   Reg#(Bool)      msix_masked        <- mkReg(True);

   PcieSplitter#(BPB)  bridge <- mkPcieSplitter( contentId
						, my_id
						, max_read_req_bytes
						, max_payload_bytes
						, rcb_mask
						, msix_enable
						, msix_masked
						, False // no MSI, only MSI-X
						);
   
   mkConnection(tpl_1(bridge.slave), tpl_2(axiSlaveEngine.tlps));
   mkConnection(tpl_1(axiSlaveEngine.tlps), tpl_2(bridge.slave));
   mkConnection(portalTop.m_axi, axiSlaveEngine.slave);
   mkConnection(bridge.master, portalTop.ctrl);

   Reg#(Bit#(11)) ptr <- mkReg(1);
      
   rule read_trace if (ptr+1 != 0);
      ptr <= ptr+1;
      TimestampedTlpData lineitem = unpack(tlp_trace.sub(ptr));
      if (lineitem.source == 7'h04) //frombus
	 tpl_2(bridge.tlps).put(lineitem.tlp);
      else if (lineitem.source == 7'h08) //tobus
	 let _x0 <- tpl_1(bridge.tlps).get;
   endrule
   
   rule quit if (ptr+1 == 0);
      $finish;
   endrule
   
endmodule


/*
      Bool dump = True;   

      ptr <= ptr+1;
      
      let lineitem = tlp_trace.sub(ptr);
      Bit#(160) dataline = truncate(lineitem);
      
      Bit#(8) portnum = dataline[159:152] >> 1;
      Bit#(4) tlpsof  = dataline[155:152] & 4'b1;
      Bit#(8) pkttype = dataline[127:120] & 8'h1f;
      
      Bit#(32) seqno  = lineitem[191:160];  
      
      
      // TX == to host
      // RX == from host
      // qq == request
      // pp == response

      Bool rx = False;
      Bool tx = False;
      Bool cc = False;
      Bool pp = False;
      Bool qq = False;
      
      if (portnum == 4) begin
	 rx = True;
	 if (dump) 
            $write("RX");
      end
      else if (portnum == 8) begin
	 tx = True;
	 if (dump) 
            $write("TX");
      end
      else begin
	 if (dump) 
	    $write("__");
      end
	 
      if (tlpsof == 0) begin
	 cc = True;
	 if (dump) 
            $write("cc: ");
      end
      else if (pkttype == 10) begin
	 pp = True;
	 if (dump) 
            $write("pp: ");
      end
      else begin
	 qq = True;
	 if (dump) 
	    $write("qq: ");
      end      
      
      if (dump) begin
	 $write("JJ ");
	 $write("%h ", seqno);
	 $display("%h", dataline);
      end
   
      
      // NOTE: as long as the ctrl interface doesn't support bursts, this decoding is sufficient
      
      // RXqq: portal request
      // TXpp: portal indication
      // TXqq: DMA request
      // RXpp: DMA response
      // RXcc: DMA read data
      // TXcc: DMA write data

      // function Bit#(153) rtrunc(Bit#(160) x);
      // 	 return x[159:7];
      // endfunction
      
      if (rx && qq) 
	 portalEngine.tlp_in.put(unpack(truncate(dataline)));
      else if (tx && pp)
	 let _x0 <- portalEngine.tlp_out.get;
      else if (tx && qq)
	 let _x1 <- tpl_1(axiSlaveEngine.tlps).get;
      else if (rx && pp)
	 tpl_2(axiSlaveEngine.tlps).put(unpack(truncate(dataline)));
      else if (rx && cc)
	 tpl_2(axiSlaveEngine.tlps).put(unpack(truncate(dataline)));
      else if (tx && cc)
	 let _x2 <- tpl_1(axiSlaveEngine.tlps).get;
*/