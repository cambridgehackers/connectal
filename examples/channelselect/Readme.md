## ChannelSelectTest

L. Stewart <stewart@qrclab.com>
August 21, 2014

This example is part of the front end of a software defined radio.

Digital samples at the RF sample rate come in, are filtered by a
finite impulse response digital filter, and multiplied by a digital
local oscillator signal.  The output is at the IF sample rate.
Due to the high expected RF sample rate, the input is two samples
per cycle at half the RF rate. Output is one sample per cycle at the
IF rate.

This example is a test harness for the signal processing logic
located in examples/fmcomms1

The test software loads filter coefficients one by one, then
feeds RF samples one at a time to the hardware.

Occasionally, the hardware sends IF sample back, using the
indications interface.

The hardware is supposed to map onto MAC units in the Xilinx.

What it does

The hardware under test accepts two-at-a-time complex valued RF
samples.  Real and imaginary parts of the signal are 16 bits, 
with 2 integer bits and 14 fraction bits.

An FIR filter is applied to the RF filter, and the result is
multiplied by a local oscillator.  The result is decimated
and delivered as Complex valued IF samples.

The trick of Vanu and Welborn is used, so that the FIR filter only
computes results at the IF sampling rate, and the local oscillator
also runs at the IF sample rate

     
