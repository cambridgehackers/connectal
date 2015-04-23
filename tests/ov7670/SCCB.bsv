////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011  Bluespec, Inc.   ALL RIGHTS RESERVED.
//  $Revision     : $
//  $Date         : $
////////////////////////////////////////////////////////////////////////////////
//  Filename      : SCCB.bsv
//  Description   : SCCB master read/write controller 
////////////////////////////////////////////////////////////////////////////////
package SCCB;

// Notes :

////////////////////////////////////////////////////////////////////////////////
/// Imports
////////////////////////////////////////////////////////////////////////////////
import Vector            ::*;
import FIFO              ::*;
import FIFOF             ::*;
import Counter           ::*;
import TriState          ::*;
import BUtils            ::*;
import Arbitrate         ::*;
import Connectable       ::*;
import GetPut            ::*;
import ClientServer      ::*;

import ConnectalXilinxCells::*;

////////////////////////////////////////////////////////////////////////////////
/// Exports
////////////////////////////////////////////////////////////////////////////////
export SCCB_Pins(..);
export SCCB(..);
export SCCBController(..);
export SCCBRequest(..);
export SCCBResponse(..);

export mkSCCB;
export mkSCCBController;

////////////////////////////////////////////////////////////////////////////////
/// Types
////////////////////////////////////////////////////////////////////////////////
typedef struct {
   Bool     write;
   Bit#(7)  slaveaddr;
   Bit#(8)  address;
   Bit#(8)  data;
} SCCBRequest deriving (Bits, Eq);

typedef struct {
   Bit#(8)  data;
} SCCBResponse deriving (Bits, Eq);

instance ArbRequestTC#(SCCBRequest);
   function Bool isReadRequest(SCCBRequest a) = !a.write;
   function Bool isWriteRequest(SCCBRequest a) = a.write;
endinstance

typedef enum {
   Idle,
   Running
} State deriving (Bits, Eq);

////////////////////////////////////////////////////////////////////////////////
/// Interfaces
////////////////////////////////////////////////////////////////////////////////
(* always_enabled, always_ready *)
interface SCCB_Pins;
   (* prefix = "SDA" *)
   interface Inout#(Bit#(1)) sda;
   (* prefix = "SCL" *)
   interface Inout#(Bit#(1)) scl;
endinterface

interface SCCB;
   (* prefix = "" *)
   interface SCCB_Pins i2c;
   interface Server#(SCCBRequest, SCCBResponse) user;
endinterface

interface SCCBController#(numeric type n);
   (* prefix = "" *)
   interface SCCB_Pins i2c;
   interface Vector#(n, Server#(SCCBRequest, SCCBResponse)) users;
endinterface      

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// 
/// Implementation
/// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkSCCB#(Integer prescale)(SCCB);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   FIFOF#(SCCBRequest)              fRequest            <- mkSizedFIFOF(16);
   FIFO#(SCCBResponse)              fResponse           <- mkSizedFIFO(16);
   
   Reg#(Bit#(1))                   rSCL                <- mkReg(1);
   Reg#(Bit#(1))                   rSDA                <- mkReg(1);
   Reg#(Bool)                      rOutEn              <- mkReg(True);
   TriState#(Bit#(1))              tSCL                <- mkTriState(True, rSCL);
   //TriState#(Bit#(1))              tSDA                <- mkTriState(rOutEn, rSDA);
   //IOBUF                           ioSCL               <- mkIOBUF(pack(True), rSCL);
   IOBUF                           ioSDA               <- mkIOBUF(rOutEn ? 0 : 1, rSDA);

   Counter#(32)                    rPrescaler          <- mkCounter(fromInteger(prescale));
   PulseWire                       pwTick              <- mkPulseWire;
   Counter#(10)                    rPlayIndex          <- mkCounter(0);
   
   Reg#(State)                     rState              <- mkReg(Idle);
   Reg#(Bool)                      rWrite              <- mkRegU;
   Reg#(Bit#(7))                   rSlaveAddr          <- mkRegU;
   Reg#(Bit#(8))                   rAddress            <- mkRegU;
   Reg#(Bit#(8))                   rWriteData          <- mkRegU;
   Vector#(8, Reg#(Bit#(1)))       vrReadData          <- replicateM(mkRegU);
   
   Bit#(7)                         slv                  = rSlaveAddr;
   Bit#(3)                         s6                   = duplicate(slv[6]);
   Bit#(3)                         s5                   = duplicate(slv[5]);
   Bit#(3)                         s4                   = duplicate(slv[4]);
   Bit#(3)                         s3                   = duplicate(slv[3]);
   Bit#(3)                         s2                   = duplicate(slv[2]);
   Bit#(3)                         s1                   = duplicate(slv[1]);
   Bit#(3)                         s0                   = duplicate(slv[0]);
   
   Bit#(8)                         adr                  = rAddress;
   Bit#(3)                         a7                   = duplicate(adr[7]);
   Bit#(3)                         a6                   = duplicate(adr[6]);
   Bit#(3)                         a5                   = duplicate(adr[5]);
   Bit#(3)                         a4                   = duplicate(adr[4]);
   Bit#(3)                         a3                   = duplicate(adr[3]);
   Bit#(3)                         a2                   = duplicate(adr[2]);
   Bit#(3)                         a1                   = duplicate(adr[1]);
   Bit#(3)                         a0                   = duplicate(adr[0]);
   
   Bit#(8)                         dat                  = rWriteData;
   Bit#(3)                         d7                   = duplicate(dat[7]);
   Bit#(3)                         d6                   = duplicate(dat[6]);
   Bit#(3)                         d5                   = duplicate(dat[5]);
   Bit#(3)                         d4                   = duplicate(dat[4]);
   Bit#(3)                         d3                   = duplicate(dat[3]);
   Bit#(3)                         d2                   = duplicate(dat[2]);
   Bit#(3)                         d1                   = duplicate(dat[1]);
   Bit#(3)                         d0                   = duplicate(dat[0]);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Reads
   ////////////////////////////////////////////////////////////////////////////////
   Integer                         readLength           = 120;
   //                start   slv[6]  slv[5]  slv[4]  slv[3]  slv[2]  slv[1]  slv[0]  write    ack    adr[7]  adr[6]  adr[5]  adr[4]  adr[3]  adr[2]  adr[1]  adr[0]   ack    stop    start   slv[6]  slv[5]  slv[4]  slv[3]  slv[2]  slv[1]  slv[0]   read    ack    dat[7]  dat[6]  dat[5]  dat[4]  dat[3]  dat[2]  dat[1]  dat[0]   ack     stop
   let wRdClock  = { 3'b110, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b011, 3'b111, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b011 };
   let wRdData   = { 3'b100, s6,     s5,     s4,     s3,     s2,     s1,     s0,     3'b000, 3'b000, a7,     a6,     a5,     a4,     a3,     a2,     a1,     a0,     3'b000, 3'b001, 3'b110, s6,     s5,     s4,     s3,     s2,     s1,     s0,     3'b111, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b001 };
   let wRdOutEn  = { 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b111 };
   let wRdSample = { 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b000, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b000, 3'b000 };
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Writes
   ////////////////////////////////////////////////////////////////////////////////
   Integer                         writeLength          = 87;
   //                start   slv[6]  slv[5]  slv[4]  slv[3]  slv[2]  slv[1]  slv[0]  write    ack    adr[7]  adr[6]  adr[5]  adr[4]  adr[3]  adr[2]  adr[1]  adr[0]   ack    dat[7]  dat[6]  dat[5]  dat[4]  dat[3]  dat[2]  dat[1]  dat[0]   ack     stop
   let wWrClock  = { 3'b110, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b010, 3'b011 };
   let wWrData   = { 3'b100, s6,     s5,     s4,     s3,     s2,     s1,     s0,     3'b000, 3'b000, a7,     a6,     a5,     a4,     a3,     a2,     a1,     a0,     3'b000, d7,     d6,     d5,     d4,     d3,     d2,     d1,     d0,     3'b000, 3'b001 };
   let wWrOutEn  = { 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b111, 3'b000, 3'b111 };

   ////////////////////////////////////////////////////////////////////////////////
   /// Rules
   ////////////////////////////////////////////////////////////////////////////////
   (* fire_when_enabled, no_implicit_conditions *)
   rule update_prescaler(rPrescaler.value > 0);
      rPrescaler.down;
   endrule

   (* fire_when_enabled, no_implicit_conditions *)
   rule reset_prescaler(rPrescaler.value == 0);
      rPrescaler.setF(fromInteger(prescale));
      pwTick.send;
   endrule
   
   rule start(rState == Idle);
      let request = fRequest.first; fRequest.deq;
      rSlaveAddr <= request.slaveaddr;
      rAddress   <= request.address;
      rWriteData <= request.data;
      rWrite     <= request.write;
      rState     <= Running;
      if (request.write)
	 rPlayIndex.setF(fromInteger(writeLength-1));
      else
	 rPlayIndex.setF(fromInteger(readLength-1));
   endrule
   
   rule running_write(rState == Running && rWrite && pwTick && rPlayIndex.value > 0);
      rPlayIndex.down;
      rOutEn     <= wWrOutEn[rPlayIndex.value] == 1;
      rSDA       <= wWrData[rPlayIndex.value];
      rSCL       <= wWrClock[rPlayIndex.value];
   endrule

   rule running_read(rState == Running && !rWrite && pwTick && rPlayIndex.value > 0);
      rPlayIndex.down;
      rOutEn     <= wRdOutEn[rPlayIndex.value] == 1;
      rSDA       <= wRdData[rPlayIndex.value];
      rSCL       <= wRdClock[rPlayIndex.value];
      if (wRdSample[rPlayIndex.value] == 1) writeVReg(vrReadData, shiftInAt0(readVReg(vrReadData), ioSDA.o()));
   endrule
            
   rule done_write(rState == Running && rWrite && pwTick && rPlayIndex.value == 0);
      rPlayIndex.down;
      rOutEn     <= wWrOutEn[rPlayIndex.value] == 1;
      rSDA       <= wWrData[rPlayIndex.value];
      rSCL       <= wWrClock[rPlayIndex.value];
      rState     <= Idle;
   endrule

   rule done_read(rState == Running && !rWrite && pwTick && rPlayIndex.value == 0);
      rOutEn     <= wRdOutEn[rPlayIndex.value] == 1;
      rSDA       <= wRdData[rPlayIndex.value];
      rSCL       <= wRdClock[rPlayIndex.value];
      rState     <= Idle;
      fResponse.enq(unpack(pack(readVReg(vrReadData))));
   endrule
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface SCCB_Pins i2c;
      interface sda    = ioSDA.io;
      interface scl    = tSCL.io;
   endinterface
  
   interface Server user;
      interface request  = toPut(fRequest);
      interface response = toGet(fResponse);
   endinterface
 
endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
///
/// Implementation of SCCB Controller
///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module mkSCCBController(SCCBController#(n))
   provisos(
	    Add#(1, _1, n)
	    );
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Design Elements
   ////////////////////////////////////////////////////////////////////////////////
   Arbitrate#(n)                             mRoundRobin         <- mkRoundRobin;
   Arbiter#(n, SCCBRequest, SCCBResponse)      mArbiter            <- mkArbiter(mRoundRobin, 16);
   SCCB                                       mSCCB                <- mkSCCB(1024);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Submodule Connections
   ////////////////////////////////////////////////////////////////////////////////
   mkConnection(mArbiter.master, mSCCB.user);
   
   ////////////////////////////////////////////////////////////////////////////////
   /// Interface Connections / Methods
   ////////////////////////////////////////////////////////////////////////////////
   interface i2c   = mSCCB.i2c;
   interface users = mArbiter.users;   
endmodule

endpackage: SCCB

