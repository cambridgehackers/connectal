# Vector Add HLS Example

This is a very simple example showing how to integrate Verilog modules
generated Vivado HLS into BSV.

## TL;DR:

Having installed connectal, verilator and bluespec, to build and run this example:

    make -j22 build.verilator ; make run.verilator

## Description of the code structure

The HLS source code is:

    void vectoradd(const int in0[64], const int in1[64], int out[64])
    {
    #pragma HLS interface ap_hs port=in0
    #pragma HLS interface ap_hs port=in1
    #pragma HLS interface ap_hs port=out
	    for (int i = 0; i < 64; i++)
    #pragma unroll 4
		    out[i] = in0[i] + in1[i];
    }

The Makefile does not currently run vivado_hls, but the generated
verilog is in the repo.

The `HLS interface ap_hs` pragma directs Vivado HLS to generate a port
with valid/ack handshaking. It's similar to AXI stream, but I chose
this option because it's easier to remember that `ack` is the response
than `ready`.

The generated Verilog module has the following interface:

    module vectoradd (
	input   ap_clk,
	input   ap_rst,
	input   ap_start,
	output   ap_done,
	output   ap_idle,
	output   ap_ready,
	input  [31:0] in0,
	input   in0_ap_vld,
	output   in0_ap_ack,
	input  [31:0] in1,
	input   in1_ap_vld,
	output   in1_ap_ack,
	output  [31:0] out_r,
	output   out_r_ap_vld,
	input   out_r_ap_ack);

Connectal's importbvi.py script produces a basic `import "BVI"`
definition for the module so we can invoke it from BSV. Matching the
port declarations against the Vivado HLS conventions, importbvi.py
could generate the following BSV interface for the module:

    interface Vaddhls;
       interface Put#(Bit#(32)) in0;
       interface Put#(Bit#(32)) in1;
       interface Get#(Bit#(32)) out;
       method Action start();
       method ActionValue#(Bit#(1)) done();
    endinterface

I write my test benches in software, which is quite easy to do with
Connectal. So even though this is about the slowest way possible to
run this "accelerator", I wrapped it up in the following top level BSV
module:

    // requests from software to hardware
    interface VaddRequest;
       method Action data(Bit#(32) in0, Bit#(32) in1);
       method Action start();
    endinterface

    // responses from hardware to software
    interface VaddResponse;
       method Action data(Bit#(32) out);
       method Action done();
    endinterface

    interface Vadd;
       interface VaddRequest request;
    endinterface

    module mkVadd#(VaddResponse response)(Vadd);
       Vaddhls vaddhls <- mkVaddhls(64);

       rule rl_response;
	  let v <- vaddhls.out.get();
	  response.data(v);
       endrule

       rule rl_done;
	  let v <- vaddhls.done();
	  response.done();
       endrule

       interface VaddRequest request;
	  method Action data(Bit#(32) in0, Bit#(32) in1);
	     vaddhls.in0.put(in0);
	     vaddhls.in1.put(in1);
	  endmethod
	  method Action start();
	     vaddhls.start();
	  endmethod
       endinterface
    endmodule

And finally the test driver:

    #include <stdio.h>
    #include <VaddRequest.h>
    #include <VaddResponse.h>

    volatile int finished = 0;
    class VaddResponse : public VaddResponseWrapper
    {
    private:
      int i;
      int received_done;
    public:
      virtual void data ( const uint32_t out ) {
	fprintf(stderr, "data[%d] = %d\n", i, out);
	i = i + 1;
	if (i >= 64 && received_done)
	  finished = 1;
      }
      virtual void done() {
	fprintf(stderr, "done\n");
	received_done = 1;
	if (i >= 64 && received_done)
	  finished = 1;
      }
      void clear() {
	i = 0;
	received_done = 0;
	finished = 0;
      }
      VaddResponse(unsigned int id, PortalTransportFunctions *transport = 0, void *param = 0, PortalPoller *poller = 0)
	: VaddResponseWrapper(id, transport, param, poller) {
	i = 0;
	received_done = 0;
      }
    };

    int main(int argc, const char **argv)
    {
      // Instantiate response handler, which will run in a second thread
      VaddResponse response(IfcNames_VaddResponseH2S);
      // Instantiate the request proxy
      VaddRequestProxy *request = new VaddRequestProxy(IfcNames_VaddRequestS2H);

      // [1] Batch processing mode

      // send the data to the logic
      for (int i = 0; i < 64; i++) {
	request->data(i, i*2);
      }
      // start the computation
      request->start();

      // wait for responses
      while (!finished)
	sleep(1);

      // clear the response handler so we can use it again
      response.clear();

      // [2] Pipelined processing mode

      // start the computation
      request->start();

      // send the data
      for (int i = 0; i < 64; i++) {
	request->data(i, i*2);
      }

      // wait for responses
      while (!finished)
	sleep(1);

      return 0;
    }

