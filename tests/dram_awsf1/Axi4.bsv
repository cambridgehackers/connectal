import AxiBits::*;
import Axi4MasterSlave::*;
import FIFOF::*;
import ConnectalFIFO::*;
import GetPut::*;

typedef 64 DdrAddrWidth;
typedef 16 DdrIdWidth;
typedef 512 DdrBusWidth;
typedef Axi4MasterBits#(DdrAddrWidth,DdrBusWidth,DdrIdWidth,Empty) Axi4;

interface Ddr3TestRequest;
   method Action startWriteDram(Bit#(16) id, Bit#(64) addr,
   	  	 	  Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4,
   	  	          Bit#(32) v5, Bit#(32) v6,Bit#(32) v7, Bit#(32) v8,
			  Bit#(32) v9, Bit#(32) v10, Bit#(32) v11, Bit#(32) v12,
   	  	          Bit#(32) v13, Bit#(32) v14, Bit#(32) v15, Bit#(32) v16);
   method Action startReadDram(Bit#(16) id, Bit#(64) addr);
endinterface

interface Ddr3TestIndication;
   method Action writeDone(Bit#(32) v);
   method Action readDone(Bit#(16) id, Bit#(32) v1, Bit#(32) v2, Bit#(32) v3, Bit#(32) v4,
   	  	          Bit#(32) v5, Bit#(32) v6,Bit#(32) v7, Bit#(32) v8,
			  Bit#(32) v9, Bit#(32) v10, Bit#(32) v11, Bit#(32) v12,
   	  	          Bit#(32) v13, Bit#(32) v14, Bit#(32) v15, Bit#(32) v16);
   method Action error(Bit#(32) code, Bit#(32) data);
endinterface

interface DdrAws;
   interface Ddr3TestRequest request;
   interface Axi4 ddr3;
endinterface


module mkAxi4MasterBitsEmpty#(Axi4Master#(addrWidth,dataWidth,tagWidth) m)(Axi4MasterBits#(addrWidth,busDataWidth,busTagWidth,Empty))
    provisos (Add#(dataWidth,d__,busDataWidth),
              Div#(dataWidth,32,dataWidthWords),
    	      Add#(tagWidth,t__,busTagWidth),
    	      Add#(a__, TDiv#(dataWidth, 8), TDiv#(busDataWidth, 8)));
	
	    let arfifo <- mkCFFIFOF();
	    let araddrWire <- mkDWire(0);
	    let arburstWire <- mkDWire(0);
	    let arcacheWire <- mkDWire(0);
	    let aridWire <- mkDWire(0);
	    let arreadyWire <- mkDWire(False);
	    let arprotWire <- mkDWire(0);
	    let arlenWire <- mkDWire(0);
	    let arsizeWire <- mkDWire(0);

	    let awfifo <- mkCFFIFOF();
	    let awaddrWire <- mkDWire(0);
	    let awburstWire <- mkDWire(0);
	    let awcacheWire <- mkDWire(0);
	    let awidWire <- mkDWire(0);
	    let awreadyWire <- mkDWire(False);
	    let awprotWire <- mkDWire(0);
	    let awlenWire <- mkDWire(0);
	    let awsizeWire <- mkDWire(0);

	    let rfifo <- mkCFFIFOF();
	    let rdataWire <- mkDWire(0);
	    let rrespWire <- mkDWire(0);
	    let rlastWire <- mkDWire(0);
	    let ridWire <- mkDWire(0);	    
	    let rvalidWire <- mkDWire(False);

	    let wfifo <- mkCFFIFOF();
	    let wdataWire <- mkDWire(0);
	    let widWire <- mkDWire(0);
	    let wstrbWire <- mkDWire(0);
	    let wlastWire <- mkDWire(0);
	    let wreadyWire <- mkDWire(False);

	    let bfifo <- mkCFFIFOF();
	    let bidWire <- mkDWire(0);
	    let brespWire <- mkDWire(0);
	    let bvalidWire <- mkDWire(False);

	    rule arfifo_enq;
	       let req <- m.req_ar.get();
	       arfifo.enq(req);
	    endrule

	    rule arwire_rule;
	       araddrWire <= arfifo.first.address;
	       arlenWire <= arfifo.first.len;
	       Bit#(11) dwlen = extend(arfifo.first.len) / fromInteger(valueOf(dataWidthWords));
	       Bit#(8) mustbeone = 8'hf;
	       arsizeWire <= arfifo.first.size;
	       arburstWire <= 2'b01; //arfifo.first.burst;
	       arprotWire <= 3'b000; //arfifo.first.prot;
	       arcacheWire <= 4'b0011; // arfifo.first.cache;
	       aridWire <= arfifo.first.id;
	    endrule

	    rule ar_handshake if (arreadyWire);
	      arfifo.deq();
	    endrule

	    rule awfifo_enq;
	       let req <- m.req_aw.get();
	       awfifo.enq(req);
	    endrule

	    rule awwire_rule;
	       awaddrWire <= awfifo.first.address;
	       let lenbytes = awfifo.first.len;
	       awlenWire <= lenbytes;
	       Bit#(11) dwlen = extend(lenbytes) / fromInteger(valueOf(dataWidthWords));
	       Bit#(4) firstBE = 4'hf;
	       Bit#(4) lastBE = (lenbytes > 4) ? 4'hf : 0;
	       awsizeWire <= awfifo.first.size;
	       awburstWire <= 2'b01; //awfifo.first.burst;
	       awprotWire <= 3'b000; //awfifo.first.prot;
	       awcacheWire <= 4'b0011; // awfifo.first.cache;
	       awidWire <= awfifo.first.id;
	    endrule

	    rule aw_handshake if (awreadyWire);
	      awfifo.deq();
	    endrule

	    rule rdata_put;
	       let data <- toGet(rfifo).get();
	       m.resp_read.put(data); 
	    endrule

	    rule r_handshake if (rvalidWire);
	      rfifo.enq(Axi4ReadResponse {data: truncate(rdataWire),
	      				  resp: rrespWire,
					  last: rlastWire,
					  id: ridWire });
	    endrule

	    rule wdata_get;
	       let data <- m.resp_write.get();
	       wfifo.enq(data);
	    endrule

	    rule w_handshake if (wreadyWire);
	      let data <- toGet(wfifo).get();
	      wdataWire <= extend(data.data);
	      wlastWire <= pack(data.last);
	      wstrbWire <= data.byteEnable;
	      widWire <= data.id;
	    endrule

	    rule bresp_put;
	       let resp <- toGet(bfifo).get();
	       m.resp_b.put(resp); 
	    endrule

	    rule b_handshake if (bvalidWire);
	      bfifo.enq(Axi4WriteResponse {resp: brespWire,
					  id: bidWire });
	    endrule

	    interface Empty extra;
	    endinterface

	    method araddr = araddrWire;
	    method arburst = arburstWire;
	    method arcache = arcacheWire;
	    method aresetn = 1;
	    method arid = extend(aridWire);
	    method arlen = arlenWire;
	    // method Bit#(2)     arlock();
	    method arprot = arprotWire;
	    // method Bit#(4)     arqos();
	    method Action      arready(Bit#(1) v); arreadyWire <= unpack(v); endmethod
	    method arsize = arsizeWire;
	    method arvalid = pack(arfifo.notEmpty);

	    method awaddr = awaddrWire;
	    method awburst = awburstWire;
	    method awcache = awcacheWire;
	    method awid = extend(awidWire);
	    method awlen = awlenWire;
	    //method awlock = awlockWire;
	    method awprot = awprotWire;
	    // method Bit#(4)     awqos();
	    method Action      awready(Bit#(1) v); awreadyWire <= unpack(v); endmethod
	    method awsize = awsizeWire;
	    method awvalid = pack(awfifo.notEmpty);

	    method Action      bid(Bit#(busTagWidth) v); bidWire <= truncate(v); endmethod
	    method bready = pack(bfifo.notFull());
	    method Action      bresp(Bit#(2) v); brespWire <= v; endmethod
	    method Action      bvalid(Bit#(1) v); bvalidWire <= unpack(v); endmethod

	    method Action      rdata(Bit#(busDataWidth) v); rdataWire <= v; endmethod
	    method Action      rid(Bit#(busTagWidth) v); ridWire <= truncate(v); endmethod
	    method Action      rlast(Bit#(1) v); rlastWire <= unpack(v); endmethod
	    method rready = pack(rfifo.notFull());
	    method Action      rresp(Bit#(2) v); rrespWire <= v; endmethod
	    method Action      rvalid(Bit#(1) v); rvalidWire <= unpack(v); endmethod

	    method wdata = wdataWire;
	    method wid = extend(widWire);
	    method wlast = wlastWire;
	    method Action      wready(Bit#(1) v); wreadyWire <= unpack(v); endmethod
	    method wstrb = extend(wstrbWire);
	    method wvalid = pack(wfifo.notEmpty);

endmodule


