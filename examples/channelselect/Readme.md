## ChannelSelectTest

L. Stewart <stewart@qrclab.com>
August 21, 2014

This example is a test harness for the signal processing logic
located in examples/fmcomms1

The test software loads filter coefficients one by one, then
feeds RF samples one at a time to the hardware.

Occasionally, the hardware sends IF sample back, using the
indications interface.

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

     