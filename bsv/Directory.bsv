
interface DirectoryRequest;
   method Action offsetRequest(Bit#(32) id);
   method Action lengthRequeset(Bit#(32) id);
endinterface

interface DirectoryResponse;
   method Action offsetResponse(Bit#(32) off);
   method Action lengthResponse(Bit#(32) len);
endinterface

interface DirectoryRequestI#(numeric type n);
   interface DirectoryRequest req;
endinterface

module mkDirectoryRequestI#(DirectoryResponse resp, Vector#(n,Bit#(32)) ids) (DirectoryRequestP#(n));

   Vector#(n, Reg#(Bit#(32))) ids <- mapM(mkReg,ids);
   FIFO#(Bit#(32)) req <- mkFIF0;
   Reg#(Bit#(32)) ptr <- mkReg(0);
   
   rule search;
      if (req.first == ids[ptr]) begin
	 req.deq;
	 resp.offsetResponse(zeroExtend(ptr));
      end
      else if(ptr+1 == valueOf(n)) begin
	 resp.offsetResponse(maxValue);
	 ptr <= 0;
	 req.deq;
      end
      else begin
	 ptr <= ptr+1;
      end
   endrule
   
   interface DirectoryRequest req;
      method Action offsetRequest(Bit#(32) id);
	 req.enq(id);
      endmethod
      method Action lengthRequest(Bit#(32) id);
	 resp.lengthResponse(0);
      endmethod
   endinterface

endmodule


