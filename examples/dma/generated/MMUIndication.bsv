package MMUIndication;

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
    Bit#(32) sglId;
} IdResponse_Message deriving (Bits);

typedef struct {
    Bit#(32) sglId;
} ConfigResp_Message deriving (Bits);

typedef struct {
    Bit#(32) code;
    Bit#(32) sglId;
    Bit#(64) offset;
    Bit#(64) extra;
} Error_Message deriving (Bits);

// exposed wrapper portal interface
interface MMUIndicationInputPipes;
    interface PipeOut#(IdResponse_Message) idResponse_PipeOut;
    interface PipeOut#(ConfigResp_Message) configResp_PipeOut;
    interface PipeOut#(Error_Message) error_PipeOut;

endinterface
interface MMUIndicationInput;
    interface PipePortal#(3, 0, SlaveDataBusWidth) portalIfc;
    interface MMUIndicationInputPipes pipes;
endinterface
interface MMUIndicationWrapperPortal;
    interface PipePortal#(3, 0, SlaveDataBusWidth) portalIfc;
endinterface
// exposed wrapper MemPortal interface
interface MMUIndicationWrapper;
    interface StdPortal portalIfc;
endinterface

instance Connectable#(MMUIndicationInputPipes,MMUIndication);
   module mkConnection#(MMUIndicationInputPipes pipes, MMUIndication ifc)(Empty);

    rule handle_idResponse_request;
        let request <- toGet(pipes.idResponse_PipeOut).get();
        ifc.idResponse(request.sglId);
    endrule

    rule handle_configResp_request;
        let request <- toGet(pipes.configResp_PipeOut).get();
        ifc.configResp(request.sglId);
    endrule

    rule handle_error_request;
        let request <- toGet(pipes.error_PipeOut).get();
        ifc.error(request.code, request.sglId, request.offset, request.extra);
    endrule

   endmodule
endinstance

// exposed wrapper Portal implementation
(* synthesize *)
module mkMMUIndicationInput(MMUIndicationInput);
    Vector#(3, PipeIn#(Bit#(SlaveDataBusWidth))) requestPipeIn;

    AdapterFromBus#(SlaveDataBusWidth,IdResponse_Message) idResponse_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[0] = idResponse_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,ConfigResp_Message) configResp_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[1] = configResp_requestAdapter.in;

    AdapterFromBus#(SlaveDataBusWidth,Error_Message) error_requestAdapter <- mkAdapterFromBus();
    requestPipeIn[2] = error_requestAdapter.in;

    interface PipePortal portalIfc;
        interface PortalSize messageSize;
        method Bit#(16) size(Bit#(16) methodNumber);
            case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(IdResponse_Message)));
            1: return fromInteger(valueOf(SizeOf#(ConfigResp_Message)));
            2: return fromInteger(valueOf(SizeOf#(Error_Message)));
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
    interface MMUIndicationInputPipes pipes;
        interface idResponse_PipeOut = idResponse_requestAdapter.out;
        interface configResp_PipeOut = configResp_requestAdapter.out;
        interface error_PipeOut = error_requestAdapter.out;
    endinterface
endmodule

module mkMMUIndicationWrapperPortal#(MMUIndication ifc)(MMUIndicationWrapperPortal);
    let dut <- mkMMUIndicationInput;
    mkConnection(dut.pipes, ifc);
    interface PipePortal portalIfc = dut.portalIfc;
endmodule

interface MMUIndicationWrapperMemPortalPipes;
    interface MMUIndicationInputPipes pipes;
    interface MemPortal#(12,32) portalIfc;
endinterface

(* synthesize *)
module mkMMUIndicationWrapperMemPortalPipes#(Bit#(SlaveDataBusWidth) id)(MMUIndicationWrapperMemPortalPipes);

  let dut <- mkMMUIndicationInput;
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxIn(ctrlPort.memSlave,dut.portalIfc.requests);
  interface MMUIndicationInputPipes pipes = dut.pipes;
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
endmodule

// exposed wrapper MemPortal implementation
module mkMMUIndicationWrapper#(idType id, MMUIndication ifc)(MMUIndicationWrapper)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
  let dut <- mkMMUIndicationWrapperMemPortalPipes(zeroExtend(pack(id)));
  mkConnection(dut.pipes, ifc);
  interface MemPortal portalIfc = dut.portalIfc;
endmodule

// exposed proxy interface
interface MMUIndicationOutput;
    interface PipePortal#(0, 3, SlaveDataBusWidth) portalIfc;
    interface ConnectalMemory::MMUIndication ifc;
endinterface
interface MMUIndicationProxy;
    interface StdPortal portalIfc;
    interface ConnectalMemory::MMUIndication ifc;
endinterface

interface MMUIndicationOutputPipeMethods;
    interface PipeIn#(IdResponse_Message) idResponse;
    interface PipeIn#(ConfigResp_Message) configResp;
    interface PipeIn#(Error_Message) error;

endinterface

interface MMUIndicationOutputPipes;
    interface MMUIndicationOutputPipeMethods methods;
    interface PipePortal#(0, 3, SlaveDataBusWidth) portalIfc;
endinterface

function Bit#(16) getMMUIndicationMessageSize(Bit#(16) methodNumber);
    case (methodNumber)
            0: return fromInteger(valueOf(SizeOf#(IdResponse_Message)));
            1: return fromInteger(valueOf(SizeOf#(ConfigResp_Message)));
            2: return fromInteger(valueOf(SizeOf#(Error_Message)));
    endcase
endfunction

(* synthesize *)
module mkMMUIndicationOutputPipes(MMUIndicationOutputPipes);
    Vector#(3, PipeOut#(Bit#(SlaveDataBusWidth))) indicationPipes;

    AdapterToBus#(SlaveDataBusWidth,IdResponse_Message) idResponse_responseAdapter <- mkAdapterToBus();
    indicationPipes[0] = idResponse_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,ConfigResp_Message) configResp_responseAdapter <- mkAdapterToBus();
    indicationPipes[1] = configResp_responseAdapter.out;

    AdapterToBus#(SlaveDataBusWidth,Error_Message) error_responseAdapter <- mkAdapterToBus();
    indicationPipes[2] = error_responseAdapter.out;

    PortalInterrupt#(SlaveDataBusWidth) intrInst <- mkPortalInterrupt(indicationPipes);
    interface MMUIndicationOutputPipeMethods methods;
    interface idResponse = idResponse_responseAdapter.in;
    interface configResp = configResp_responseAdapter.in;
    interface error = error_responseAdapter.in;

    endinterface
    interface PipePortal portalIfc;
        interface PortalSize messageSize;
            method size = getMMUIndicationMessageSize;
        endinterface
        interface Vector requests = nil;
        interface Vector indications = indicationPipes;
        interface PortalInterrupt intr = intrInst;
    endinterface
endmodule

(* synthesize *)
module mkMMUIndicationOutput(MMUIndicationOutput);
    let indicationPipes <- mkMMUIndicationOutputPipes;
    interface ConnectalMemory::MMUIndication ifc;

    method Action idResponse(Bit#(32) sglId);
        indicationPipes.methods.idResponse.enq(IdResponse_Message {sglId: sglId});
        //$display("indicationMethod 'idResponse' invoked");
    endmethod
    method Action configResp(Bit#(32) sglId);
        indicationPipes.methods.configResp.enq(ConfigResp_Message {sglId: sglId});
        //$display("indicationMethod 'configResp' invoked");
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        indicationPipes.methods.error.enq(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
        //$display("indicationMethod 'error' invoked");
    endmethod
    endinterface
    interface PipePortal portalIfc = indicationPipes.portalIfc;
endmodule
instance PortalMessageSize#(MMUIndicationOutput);
   function Bit#(16) portalMessageSize(MMUIndicationOutput p, Bit#(16) methodNumber);
      return getMMUIndicationMessageSize(methodNumber);
   endfunction
endinstance


interface MMUIndicationInverse;
    method ActionValue#(IdResponse_Message) idResponse;
    method ActionValue#(ConfigResp_Message) configResp;
    method ActionValue#(Error_Message) error;

endinterface

interface MMUIndicationInverter;
    interface ConnectalMemory::MMUIndication ifc;
    interface MMUIndicationInverse inverseIfc;
endinterface

instance Connectable#(MMUIndicationInverse, MMUIndicationOutputPipeMethods);
   module mkConnection#(MMUIndicationInverse in, MMUIndicationOutputPipeMethods out)(Empty);
    mkConnection(in.idResponse, out.idResponse);
    mkConnection(in.configResp, out.configResp);
    mkConnection(in.error, out.error);

   endmodule
endinstance

(* synthesize *)
module mkMMUIndicationInverter(MMUIndicationInverter);
    FIFOF#(IdResponse_Message) fifo_idResponse <- mkFIFOF();
    FIFOF#(ConfigResp_Message) fifo_configResp <- mkFIFOF();
    FIFOF#(Error_Message) fifo_error <- mkFIFOF();

    interface ConnectalMemory::MMUIndication ifc;

    method Action idResponse(Bit#(32) sglId);
        fifo_idResponse.enq(IdResponse_Message {sglId: sglId});
    endmethod
    method Action configResp(Bit#(32) sglId);
        fifo_configResp.enq(ConfigResp_Message {sglId: sglId});
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        fifo_error.enq(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
    endmethod
    endinterface
    interface MMUIndicationInverse inverseIfc;

    method ActionValue#(IdResponse_Message) idResponse;
        fifo_idResponse.deq;
        return fifo_idResponse.first;
    endmethod
    method ActionValue#(ConfigResp_Message) configResp;
        fifo_configResp.deq;
        return fifo_configResp.first;
    endmethod
    method ActionValue#(Error_Message) error;
        fifo_error.deq;
        return fifo_error.first;
    endmethod
    endinterface
endmodule

(* synthesize *)
module mkMMUIndicationInverterV(MMUIndicationInverter);
    PutInverter#(IdResponse_Message) inv_idResponse <- mkPutInverter();
    PutInverter#(ConfigResp_Message) inv_configResp <- mkPutInverter();
    PutInverter#(Error_Message) inv_error <- mkPutInverter();

    interface ConnectalMemory::MMUIndication ifc;

    method Action idResponse(Bit#(32) sglId);
        inv_idResponse.mod.put(IdResponse_Message {sglId: sglId});
    endmethod
    method Action configResp(Bit#(32) sglId);
        inv_configResp.mod.put(ConfigResp_Message {sglId: sglId});
    endmethod
    method Action error(Bit#(32) code, Bit#(32) sglId, Bit#(64) offset, Bit#(64) extra);
        inv_error.mod.put(Error_Message {code: code, sglId: sglId, offset: offset, extra: extra});
    endmethod
    endinterface
    interface MMUIndicationInverse inverseIfc;

    method ActionValue#(IdResponse_Message) idResponse;
        let v <- inv_idResponse.inverse.get;
        return v;
    endmethod
    method ActionValue#(ConfigResp_Message) configResp;
        let v <- inv_configResp.inverse.get;
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
module mkMMUIndicationProxySynth#(Bit#(SlaveDataBusWidth) id)(MMUIndicationProxy);
  let dut <- mkMMUIndicationOutput();
  PortalCtrlMemSlave#(SlaveControlAddrWidth,SlaveDataBusWidth) ctrlPort <- mkPortalCtrlMemSlave(id, dut.portalIfc.intr);
  let memslave  <- mkMemMethodMuxOut(ctrlPort.memSlave,dut.portalIfc.indications);
  interface MemPortal portalIfc = (interface MemPortal;
      interface PhysMemSlave slave = memslave;
      interface ReadOnly interrupt = ctrlPort.interrupt;
      interface WriteOnly num_portals = ctrlPort.num_portals;
    endinterface);
  interface ConnectalMemory::MMUIndication ifc = dut.ifc;
endmodule

// exposed proxy MemPortal
module mkMMUIndicationProxy#(idType id)(MMUIndicationProxy)
   provisos (Bits#(idType, a__),
	     Add#(b__, a__, SlaveDataBusWidth));
   let rv <- mkMMUIndicationProxySynth(extend(pack(id)));
   return rv;
endmodule
endpackage: MMUIndication
