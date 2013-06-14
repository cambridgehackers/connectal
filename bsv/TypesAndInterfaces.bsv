
// Copyright (c) 2012 Nokia, Inc.

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

package TypesAndInterfaces;

import AxiMasterSlave::*;
import HDMI::*;
import FifoToAxi::*;
import GetPut::*;

interface HdmiDisplay;
    method Action setPatternReg(Bit#(32) yuv422);
    method Action startFrameBuffer0(Bit#(32) base);
    method Action startFrameBuffer1(Bit#(32) base);

    method Action waitForVsync(Bit#(32) unused);

    method Action hdmiLinesPixels(Bit#(32) value);
    method Action hdmiBlankLinesPixels(Bit#(32) value);
    method Action hdmiStrideBytes(Bit#(32) strideBytes);
    method Action hdmiLineCountMinMax(Bit#(32) value);
    method Action hdmiPixelCountMinMax(Bit#(32) value);
    method Action hdmiSyncWidths(Bit#(32) value);

    method Action beginTranslationTable(Bit#(8) index);
    method Action addTranslationEntry(Bit#(20) address, Bit#(12) length); // shift address and length left 12 bits

    interface Axi3Master#(32,4) m_axi;
    interface HDMI hdmi;
endinterface

interface HdmiDisplayIndications;
    method Action vsync(Bit#(64) v);
endinterface

endpackage
