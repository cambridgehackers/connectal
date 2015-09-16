package MemServerIndication;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Clocks::*;
import FloatingPoint::*;
import Adapter::*;
import Leds::*;
import Vector::*;
import SpecialFIFOs::*;
import ConnectalMemory::*;
import Portal::*;
import CtrlMux::*;
import MemTypes::*;
import Pipe::*;
import HostInterface::*;
import LinkerLib::*;
import ConnectalMemory::*;
import Vector::*;
import BuildVector::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;
import Pipe::*;
import MemTypes::*;
import MemReadEngine::*;
import MemWriteEngine::*;
import HostInterface::*;




typedef struct {
    Bit#(64) physAddr;
} AddrResponse_Message deriving (Bits);

typedef struct {
    DmaDbgRec rec;
} ReportStateDbg_Message deriving (Bits);

typedef struct {
    Bit#(64) words;
} ReportMemoryTraffic_Message deriving (Bits);

typedef struct {
    Bit#(32) code;
    Bit#(32) sglId;
    Bit#(64) offset;
    Bit#(64) extra;
} Error_Message deriving (Bits);

// exposed wrapper portal interface
interface MemServerIndicationInputPipes;
    interface PipeOut#(AddrResponse_Message) addrResponse_PipeOut;
    interface PipeOut#(ReportStateDbg_Message) reportStateDbg_PipeOut;
    interface PipeOut#(ReportMemoryTraffic_Message) reportMemoryTraffic_PipeOut;
    interface PipeOut#(Error_Message) error_PipeOut;

endinterface
interface MemServerIndicationInput;
    interface PipePortal#(4, 0, SlaveDataBusWidth) portalIfc;
    interface MemServerIndicationInputPipes pipes;
endinterface
interface MemServerIndicationWrapperPortal;
    interface PipePortal#(4, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface MemServerIndicationWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(MemServerIndicationInputPipes,MemServerIndication);
   module mkConnection#(MemServerIndicationInputPipes pipes, MemServerIndication ifc)(Empty);

    rule handle_addrResponse_request;
        let request <- toGet(pipes.addrResponse_PipeOut).get();
        ifc.addrResponse(request.physAddr);
    endrule

    rule handle_reportStateDbg_request;
        let request <- toGet(pipes.reportStateDbg_PipeOut).get();
        ifc.reportStateDbg(request.rec);
    endrule

    rule handle_reportMemoryTraffic_request;
        let request <- toGet(pipes.reportMemoryTraffic_PipeOut).get();
        ifc.reportMemoryTraffic(request.words);
    endrule

    rule handle_error_request;
        let request <- toGet(pipes.error_PipeOut).get();
        ifc.error(request.code, request.sglId, request.offset, request.extra);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkMemServerIndicationInput(MemServerIndicationInput);
    Vector#(4, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,AddrResponse_Message) addrResponse_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = addrResponse_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,ReportStateDbg_Message) reportStateDbg_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = reportStateDbg_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,ReportMemoryTraffic_Message) reportMemoryTraffic_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[2] = reportMemoryTraffic_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,Error_Message) error_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[3] = error_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(AddrResponse_Message)));
            1: return fromInteger(valueOf(SizeOf#(ReportStateDbg_Message)));
            2: return fromInteger(valueOf(SizeOf#(ReportMemoryTraffic_Message)));
            3: return fromInteger(valueOf(SizeOf#(Error_Message)));
            endcase
        endmethod
        endinterface
        interface Vector requests = requestPipeIn;
        interface Vector indications = nil;
        interface PortalInterrupt intr;
           method Bool status();
              return False;
           endmethod
           method Bit#(dataWidth) channel();
              return -1;
           endmethod
        endinterface
    endinterface
    interface MemServerIndicationInputPipes pipes;
        interface addrResponse_PipeOut = addrResponse_requestAdapter.out;
        interface reportStateDbg_PipeOut = reportStateDbg_requestAdapter.out;
        interface reportMemoryTraffic_PipeOut = reportMemoryTraffic_requestAdapter.out;
        interface error_PipeOut = error_requestAdapter.out;
    endinterface
endmodule

module mkMemServerIndicationWrapperPortal#(MemServerIndication ifc)(MemServerIndicationWrapperPortal);
    let dut <- mkMemServerIndicationInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface MemServerIndicationWrapperMemPortalPipes;
    interface MemServerIndicationInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkMemServerIndicationWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(MemServerIndicationWrapperMemPortalPipes);

  let dut <- mkMemServerIndicationInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface MemServerIndicationInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkMemServerIndicationWrapper#(idType id, MemServerIndication ifc)(MemServerIndicationWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkMemServerIndicationWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface MemServerIndicationOutput;
    interface PipePortal#(0, 4, SlaveDataBusWidth) portalIfc;
    interface ConnectalMemory::MemServerIndication ifc;
endinterface
interface MemServerIndicationProxy;
    interface StdPortal portalIfc;
    interface ConnectalMemory::MemServerIndication ifc;
endinterface

interface MemServerIndicationOutputPipeMethods;
    interface PipeIn#(AddrResponse_Message) addrResponse;
    interface PipeIn#(ReportStateDbg_Message) reportStateDbg;
    interface PipeIn#(ReportMemoryTraffic_Message) reportMemoryTraffic;
    interface PipeIn#(Error_Message) error;

endinterface

interface MemServerIndicationOutputPipes;
    interface MemServerIndicationOutputPipeMethods methods;
    interface PipePortal#(0, 4, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getMemServerIndicationMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(AddrResponse_Message)));
            1: return fromInteger(valueOf(SizeOf#(ReportStateDbg_Message)));
            2: return fromInteger(valueOf(SizeOf#(ReportMemoryTraffic_Message)));
            3: return fromInteger(valueOf(SizeOf#(Error_Message)));
    endcase
endfunction

(* synthesize *)
module mkMemServerIndicationOutputPipes(MemServerIndicationOutputPipes);
    Vector#(4, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,AddrResponse_Message) addrResponse_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = addrResponse_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,ReportStateDbg_Message) reportStateDbg_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = reportStateDbg_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,ReportMemoryTraffic_Message) reportMemoryTraffic_responseAdapter <- mkAdapterToBus();
    indicationPipes[2] = reportMemoryTraffic_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,Error_Message) error_responseAdapter <- mkAdapterToBus();
    indicationPipes[3] = error_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface MemServerIndicationOutputPipeMethods methods;
    interface addrResponse = addrResponse_responseAdapter.in;
    interface reportStateDbg = reportStateDbg_responseAdapter.in;
    interface reportMemoryTraffic = reportMemoryTraffic_responseAdapter.in;
    interface error = error_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getMemServerIndicationMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkMemServerIndicationOutput(MemServerIndicationOutput);
    let indicationPipes <- mkMemServerIndicationOutputPipes;
    interface ConnectalMemory::MemServerIndication ifc;

    method Action addrResponse(Bit#(64) physAddr);
        indicationPipes.methods.addrResponse.enq(AddrResponse_Message {physAddr: physAddr});
        //$display("indicationMethod 'addrResponse' invoked");
    endmethod
    method Action reportStateDbg(DmaDbgRec rec);
        indicationPipes.methods.reportStateDbg.enq(ReportStateDbg_Message {rec: rec});
        //$display("indicationMethod 'reportStateDbg' invoked");
    endmethod
    method Action reportMemoryTraffic(Bit#(64) words);
        indicationPipes.methods.reportMemoryTraffic.enq(ReportMemoryTraffic_Message {words: words});
        //$display("indicationMethod 'reportMemoryTraffic' invoked");
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        indicationPipes.methods.error.enq(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
        //$display("indicationMethod 'error' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(MemServerIndicationOutput);
   function Bit#(16) portalMessageSize(MemServerIndicationOutput p, Bit#(16) methodNumber);
      return getMemServerIndicationMessageSize(methodNumber);
   endfunction
endinstance


interface MemServerIndicationInverse;
    method ActionValue#(AddrResponse_Message) addrResponse;
    method ActionValue#(ReportStateDbg_Message) reportStateDbg;
    method ActionValue#(ReportMemoryTraffic_Message) reportMemoryTraffic;
    method ActionValue#(Error_Message) error;

endinterface

interface MemServerIndicationInverter;
    interface ConnectalMemory::MemServerIndication ifc;
    interface MemServerIndicationInverse inverseIfc;
endinterface

instance Connectable#(MemServerIndicationInverse, MemServerIndicationOutputPipeMethods);
   module mkConnection#(MemServerIndicationInverse in, MemServerIndicationOutputPipeMethods out)(Empty);
    mkConnection(in.addrResponse, out.addrResponse);
    mkConnection(in.reportStateDbg, out.reportStateDbg);
    mkConnection(in.reportMemoryTraffic, out.reportMemoryTraffic);
    mkConnection(in.error, out.error);

   endmodule
endinstance

(* synthesize *)
module mkMemServerIndicationInverter(MemServerIndicationInverter);
    FIFOF#(AddrResponse_Message) fifo_addrResponse <- mkFIFOF();
    FIFOF#(ReportStateDbg_Message) fifo_reportStateDbg <- mkFIFOF();
    FIFOF#(ReportMemoryTraffic_Message) fifo_reportMemoryTraffic <- mkFIFOF();
    FIFOF#(Error_Message) fifo_error <- mkFIFOF();

    interface ConnectalMemory::MemServerIndication ifc;

    method Action addrResponse(Bit#(64) physAddr);
        fifo_addrResponse.enq(AddrResponse_Message {physAddr: physAddr});
    endmethod
    method Action reportStateDbg(DmaDbgRec rec);
        fifo_reportStateDbg.enq(ReportStateDbg_Message {rec: rec});
    endmethod
    method Action reportMemoryTraffic(Bit#(64) words);
        fifo_reportMemoryTraffic.enq(ReportMemoryTraffic_Message {words: words});
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        fifo_error.enq(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
    endmethod
    endinterface
    interface MemServerIndicationInverse inverseIfc;

    method ActionValue#(AddrResponse_Message) addrResponse;
        fifo_addrResponse.deq;
        return fifo_addrResponse.first;
    endmethod
    method ActionValue#(ReportStateDbg_Message) reportStateDbg;
        fifo_reportStateDbg.deq;
        return fifo_reportStateDbg.first;
    endmethod
    method ActionValue#(ReportMemoryTraffic_Message) reportMemoryTraffic;
        fifo_reportMemoryTraffic.deq;
        return fifo_reportMemoryTraffic.first;
    endmethod
    method ActionValue#(Error_Message) error;
        fifo_error.deq;
        return fifo_error.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkMemServerIndicationInverterV(MemServerIndicationInverter);
    PutInverter#(AddrResponse_Message) inv_addrResponse <- mkPutInverter();
    PutInverter#(ReportStateDbg_Message) inv_reportStateDbg <- mkPutInverter();
    PutInverter#(ReportMemoryTraffic_Message) inv_reportMemoryTraffic <- mkPutInverter();
    PutInverter#(Error_Message) inv_error <- mkPutInverter();

    interface ConnectalMemory::MemServerIndication ifc;

    method Action addrResponse(Bit#(64) physAddr);
        inv_addrResponse.mod.put(AddrResponse_Message {physAddr: physAddr});
    endmethod
    method Action reportStateDbg(DmaDbgRec rec);
        inv_reportStateDbg.mod.put(ReportStateDbg_Message {rec: rec});
    endmethod
    method Action reportMemoryTraffic(Bit#(64) words);
        inv_reportMemoryTraffic.mod.put(ReportMemoryTraffic_Message {words: words});
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        inv_error.mod.put(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
    endmethod
    endinterface
    interface MemServerIndicationInverse inverseIfc;

    method ActionValue#(AddrResponse_Message) addrResponse;
        let v <- inv_addrResponse.inverse.get;
        return v;
    endmethod
    method ActionValue#(ReportStateDbg_Message) reportStateDbg;
        let v <- inv_reportStateDbg.inverse.get;
        return v;
    endmethod
    method ActionValue#(ReportMemoryTraffic_Message) reportMemoryTraffic;
        let v <- inv_reportMemoryTraffic.inverse.get;
        return v;
    endmethod
    method ActionValue#(Error_Message) error;
        let v <- inv_error.inverse.get;
        return v;
    endmethod
    endinterface
endmodule

// synthesizeable proxy MemPortal
(* synthesize *)
module mkMemServerIndicationProxySynth#(Bit#(SlaveDataBusWidth) id)(MemServerIndicationProxy);
  let dut <- mkMemServerIndicationOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface ConnectalMemory::MemServerIndication ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkMemServerIndicationProxy#(idType id)(MemServerIndicationProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkMemServerIndicationProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: MemServerIndication
