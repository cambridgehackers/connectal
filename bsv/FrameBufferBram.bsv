
// Copyright (c) 2013 Nokia, Inc.

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

import NrccSyncBRAM::*;
import BRAMFIFO::*;
import GetPut::*;
import FIFOF::*;
import Vector::*;
import SpecialFIFOs::*;
import AxiMasterSlave::*;
import AxiClientServer::*;

typedef struct {
    Bit#(32) base;
    Bit#(11) lines;
    Bit#(12) pixels;
    Bit#(14) stridebytes;
} FrameBufferConfig deriving (Bits);

Integer bytesperpixel = 4;

interface FrameBufferBram;
    method Bool running();
    method Bit#(32) base();
    method Action configure(FrameBufferConfig fbc);
    method Action startFrame();
    method Action startLine();
    method Action setSgEntry(Bit#(8) index, Bit#(24) startingOffset, Bit#(20) address, Bit#(20) length);
    interface Axi3Client#(32,4,6) axi;
    interface BRAM#(Bit#(12), Bit#(32)) buffer;
endinterface

typedef struct {
    Bit#(24) startingOffset;
    Bit#(24) limitOffset;
    Bit#(20) address; // these are page aligned, so 12 bits of zeros
    Bit#(20) length;
}  ScatterGather deriving (Bits);

module mkFrameBufferBram#(Clock displayClk, Reset displayRst)(FrameBufferBram);
    Reg#(FrameBufferConfig) nextFbc <- mkReg(FrameBufferConfig {base: 0, lines: 0, pixels: 0, stridebytes: 0});
    Reg#(FrameBufferConfig) fbc <- mkReg(FrameBufferConfig {base: 0, lines: 0, pixels: 0, stridebytes: 0});
    Reg#(Bool) runningReg <- mkReg(False);

    //let burstCount = 16;
    let burstCount = 4;
    let bytesPerWord = 4;
    let busWidth = bytesPerWord * 8;
    let bytesPerPixel = 4;
    let pixelsPerWord = bytesPerWord / bytesPerPixel;

    Reg#(Bit#(8))  sglistIndexReg <- mkReg(0); // which segment we're reading from
    Reg#(Bit#(24)) lineAddrReg <- mkReg(0); // address of start of line
    Reg#(Bit#(24)) readAddrReg <- mkReg(0); // next address to read
    Reg#(Bit#(24)) readLimitReg <- mkReg(0); // address of end of line

    Reg#(Bit#(24)) segmentLimitReg <- mkReg(0);
    Reg#(Bit#(32)) segmentOffsetReg <- mkReg(0);

    Reg#(Bit#(12)) pixelCountReg <- mkReg(0);
    Reg#(Bit#(11)) lineCountReg <- mkReg(0);
    
    Clock clk <- exposeCurrentClock ;
    Reset rst <- exposeCurrentReset ;

    //Vector#(16, Reg#(ScatterGather)) sglist <- replicateM(mkReg(unpack(0)));
    SyncBRAM#(Bit#(8), ScatterGather) sglist <- mkSyncBRAM( 256, clk, rst, clk, rst);

    //Axi3Master#(32,4,6) nullAxiMaster <- mkNullAxi3Master();

    SyncBRAM#(Bit#(12), Bit#(32)) syncBRAM <- mkSyncBRAM( 4096, displayClk, displayRst, clk, rst );
    //SyncBRAM#(Bit#(12), Bit#(32)) syncBRAM <- mkSimSyncBRAM( 4096, displayClk, displayRst, clk, rst );
    Reg#(Bit#(12)) pixelCountReg2 <- mkReg(0);

    Reg#(Bool) nextent2Enabled <- mkReg(False);
    Reg#(Bool) startFrameEnabled <- mkReg(False);

    rule nextent if (readAddrReg != 24'hFFFFFF 
    && readAddrReg > segmentLimitReg
                     && !nextent2Enabled);
        $display("nextent readAddrReg %h segmentLimitReg %h", readAddrReg, segmentLimitReg);
        let index = sglistIndexReg+1;
        nextent2Enabled <= True;
        sglist.portA.readAddr(index);
    endrule

    rule nextent2 if (nextent2Enabled);
        nextent2Enabled <= False;
        let index = sglistIndexReg+1;
        let sgent <- sglist.portA.readData();
        sglistIndexReg <= index;
        let segmentOffset = {sgent.address,12'd0} - extend(sgent.startingOffset);
        let segmentLimit = sgent.limitOffset;
        segmentOffsetReg <= segmentOffset;
        segmentLimitReg <= segmentLimit;
    endrule

    rule startFrameRule if (startFrameEnabled);
        startFrameEnabled <= False;
        fbc <= nextFbc;
        Bit#(8) segmentIndex = truncate(nextFbc.base);
        ScatterGather sgent <- sglist.portB.readData();
        sglistIndexReg <= segmentIndex;
        let segmentOffset = {sgent.address,12'd0} - extend(sgent.startingOffset);
        let segmentLimit = sgent.limitOffset;
        segmentOffsetReg <= segmentOffset;
        segmentLimitReg <= segmentLimit;
        $display("startFrame address %h startingOffset %h segmentOffset %h readLimit %h",
                 {sgent.address,12'd0}, sgent.startingOffset,
                 segmentOffset,
                 sgent.startingOffset + extend(nextFbc.stridebytes));

        lineAddrReg <= sgent.startingOffset;
        readAddrReg <= 24'hFFFFFF; // indicates have not received first hsync pulse
        readLimitReg <= sgent.startingOffset + extend(nextFbc.stridebytes);
        lineCountReg <= nextFbc.lines;
        pixelCountReg <= nextFbc.pixels;

        runningReg <= True;
    endrule

    method Bool running();
        return runningReg;
    endmethod

    method Bit#(32) base();
        return fbc.base;
    endmethod

    method Action configure(FrameBufferConfig newConfig);
        nextFbc <= newConfig;
    endmethod

    method Action setSgEntry(Bit#(8) index, Bit#(24) startingOffset, Bit#(20) address, Bit#(20) length);
        ScatterGather newEnt = ScatterGather { 
            startingOffset: startingOffset,
            address:  address,
            length:  length,
            limitOffset: startingOffset + truncate({length,12'd0})
        };
        $display("setSgEntry startingOffset %d address %d length %h limitOffset %h",
                 startingOffset, address, length, startingOffset + {length,4'd0});
        sglist.portA.write(index, newEnt);
    endmethod

    method Action startFrame() if (!startFrameEnabled);
        startFrameEnabled <= True;
        Bit#(8) segmentIndex = truncate(nextFbc.base);
        sglist.portB.readAddr(segmentIndex);
    endmethod

    method Action startLine();
        if (runningReg)
        begin
            let lineAddr = lineAddrReg;
            let readLimit = readLimitReg;
            let lineCount = lineCountReg;
            if (readAddrReg != 24'hFFFFFF) // if not the first line
            begin
                lineAddr = lineAddr + extend(fbc.stridebytes);
                readLimit = readLimit + extend(fbc.stridebytes);
                lineCount = lineCount - 1;
            end
            $display("startLine readAddr %h readLimit %h stridebytes %h", lineAddr, readLimit, fbc.stridebytes);

            lineAddrReg <= lineAddr;
            readAddrReg <= lineAddr;
            readLimitReg <= readLimit;
            lineCountReg <= lineCount;

            pixelCountReg2 <= 0;

            if (lineCount == 0)
            begin
                runningReg <= False;
            end
        end
    endmethod

   interface Axi3Client axi;
       interface Axi3ReadClient read;
           method ActionValue#(Axi3ReadRequest#(6)) address() if (runningReg
								  && readAddrReg != 24'hFFFFFF
								  && readAddrReg < readLimitReg
								  && readAddrReg <= segmentLimitReg
								  );
               Bit#(32) addr = extend(readAddrReg) + segmentOffsetReg;
	       Bit#(5) burstLen = burstCount-1;
               readAddrReg <= readAddrReg + burstCount*bytesPerWord;
               return Axi3ReadRequest { address: addr, burstLen: truncate(burstLen), id: 0} ;
           endmethod
           method Action data(Axi3ReadResponse#(32,6) response);
               pixelCountReg2 <= pixelCountReg2 + pixelsPerWord;
               syncBRAM.portB.write(pixelCountReg2 / pixelsPerWord, response.data);
           endmethod
       endinterface

       //interface Axi3WriteClient write = nullAxiClient.write;
   endinterface
   interface NrccBRAM buffer = syncBRAM.portA;
endmodule
