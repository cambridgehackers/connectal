/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

import ConnectalMemTypes::*;

typedef 6 MemTagSize;
typedef 40 PhysAddrWidth;
typedef 10 BurstLenSize;
typedef 64 DataBusWidth;

typedef struct {
   Bit#(addrWidth) addr;
   Bit#(BurstLenSize) burstLen;
   Bit#(MemTagSize) tag;
   } PhysMemRequest#(numeric type addrWidth) deriving (Bits);

typedef struct {
   Bit#(dsz) data;
   Bit#(MemTagSize) tag;
   Bool last;
   } MemData#(numeric type dsz) deriving (Bits);

interface PhysMemMasterRequest;
   method Action readReq(PhysMemRequest#(PhysAddrWidth) v);
   method Action writeReq(PhysMemRequest#(PhysAddrWidth) v);
   method Action writeData(MemData#(DataBusWidth) v);
endinterface

interface PhysMemMasterIndication;
   method Action readData(MemData#(DataBusWidth) v);
   method Action writeDone(Bit#(MemTagSize) v);
endinterface
