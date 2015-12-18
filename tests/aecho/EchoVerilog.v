// Copyright (c) 2015 The Connectal Project

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

module EchoVerilog( input  CLK, input  RST_N, 
  input  [31 : 0] request_say_v,
  input  EN_request_say,
  output RDY_request_say,

  input  [15 : 0] lEchoIndicationOutput_messageSize_size_methodNumber,
  output [15 : 0] lEchoIndicationOutput_messageSize_size,
  output RDY_lEchoIndicationOutput_messageSize_size,

  output [31 : 0] lEchoIndicationOutput_indications_0_first,
  output RDY_lEchoIndicationOutput_indications_0_first,

  input  EN_lEchoIndicationOutput_indications_0_deq,
  output RDY_lEchoIndicationOutput_indications_0_deq,

  output lEchoIndicationOutput_indications_0_notEmpty,
  output RDY_lEchoIndicationOutput_indications_0_notEmpty,

  output lEchoIndicationOutput_intr_status,
  output RDY_lEchoIndicationOutput_intr_status,

  output [31 : 0] lEchoIndicationOutput_intr_channel,
  output RDY_lEchoIndicationOutput_intr_channel);

  wire delay_first;
  wire delay_deq__RDY, delay_first__RDY;
  wire myEchoIndicationOutput_RDY_ifc_heard;
  assign RDY_lEchoIndicationOutput_messageSize_size = 1'd1 ;
  assign RDY_lEchoIndicationOutput_indications_0_notEmpty = 1'd1 ;
  assign RDY_lEchoIndicationOutput_intr_status = 1'd1 ;
  assign RDY_lEchoIndicationOutput_intr_channel = 1'd1 ;

  l_class_OC_Fifo1 delay(.nRST(RST_N), .CLK(CLK),
          .enq_v(request_say_v),
          .deq__ENA(delay_deq__RDY && delay_first__RDY && myEchoIndicationOutput_RDY_ifc_heard),
          .enq__ENA(EN_request_say),
          .deq__RDY(delay_deq__RDY),
          .enq__RDY(RDY_request_say),
          .first(delay_first),
          .first__RDY(delay_first__RDY));

  mkEchoIndicationOutput myEchoIndicationOutput(.CLK(CLK), .RST_N(RST_N),
    .ifc_heard_v(delay_first),
    .portalIfc_messageSize_size_methodNumber(lEchoIndicationOutput_messageSize_size_methodNumber),
    .EN_portalIfc_indications_0_deq(EN_lEchoIndicationOutput_indications_0_deq),
    .EN_ifc_heard(delay_deq__RDY && delay_first__RDY && myEchoIndicationOutput_RDY_ifc_heard),
    .portalIfc_messageSize_size(lEchoIndicationOutput_messageSize_size),
    .RDY_portalIfc_messageSize_size(),
    .portalIfc_indications_0_first(lEchoIndicationOutput_indications_0_first),
    .RDY_portalIfc_indications_0_first(RDY_lEchoIndicationOutput_indications_0_first),
    .RDY_portalIfc_indications_0_deq(RDY_lEchoIndicationOutput_indications_0_deq),
    .portalIfc_indications_0_notEmpty(lEchoIndicationOutput_indications_0_notEmpty),
    .RDY_portalIfc_indications_0_notEmpty(),
    .portalIfc_intr_status(lEchoIndicationOutput_intr_status),
    .RDY_portalIfc_intr_status(),
    .portalIfc_intr_channel(lEchoIndicationOutput_intr_channel),
    .RDY_portalIfc_intr_channel(),
    .RDY_ifc_heard(myEchoIndicationOutput_RDY_ifc_heard));
endmodule  // mkEcho
