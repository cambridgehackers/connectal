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
  output      RDY_request_say,
  input  [31 : 0] request_say_v,
  input        EN_request_say,
  output      RDY_messageSize_size,
  input  [15 : 0] messageSize_size_methodNumber,
  output [15 : 0] messageSize_size,
  output      RDY_ind_first,
  output [31 : 0] ind_first,
  output      RDY_ind_deq,
  input        EN_ind_deq,
  output      RDY_ind_notEmpty,
  output          ind_notEmpty,
  output      RDY_intr_status,
  output          intr_status,
  output      RDY_intr_channel,
  output [31 : 0] intr_channel);

  wire echo_rule_wire, echo_ind_ena, echo_ind_rdy;
  wire [31:0]echo_ind_v;

  l_class_OC_Echo echo(.nRST(RST_N), .CLK(CLK),
    .echoReq__RDY(RDY_request_say),
    .echoReq_v(request_say_v),
    .echoReq__ENA(EN_request_say),
    .respond_rule__RDY(echo_rule_wire),
    .respond_rule__ENA(echo_rule_wire),
    .ind$echo__RDY(echo_ind_rdy),
    .ind$echo$v(echo_ind_v),
    .ind$echo__ENA(echo_ind_ena));

  mkEchoIndicationOutput myEchoIndicationOutput(.CLK(CLK), .RST_N(RST_N),
    .RDY_ifc_heard(echo_ind_rdy),
        .ifc_heard_v(echo_ind_v),
     .EN_ifc_heard(echo_ind_ena),
    .RDY_portalIfc_messageSize_size(RDY_messageSize_size),
        .portalIfc_messageSize_size_methodNumber(messageSize_size_methodNumber),
        .portalIfc_messageSize_size(messageSize_size),
    .RDY_portalIfc_indications_0_first(RDY_ind_first),
        .portalIfc_indications_0_first(ind_first),
    .RDY_portalIfc_indications_0_deq(RDY_ind_deq),
     .EN_portalIfc_indications_0_deq(EN_ind_deq),
    .RDY_portalIfc_indications_0_notEmpty(RDY_ind_notEmpty),
        .portalIfc_indications_0_notEmpty(ind_notEmpty),
    .RDY_portalIfc_intr_status(RDY_intr_status),
        .portalIfc_intr_status(intr_status),
    .RDY_portalIfc_intr_channel(RDY_intr_channel),
        .portalIfc_intr_channel(intr_channel));
endmodule  // mkEcho
