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


typedef enum {

   IfcNames_MemServerRequestS2H,
   IfcNames_MemServerIndicationH2S,

   IfcNames_NandMemServerRequestS2H,
   IfcNames_NandMemServerIndicationH2S,
	
   IfcNames_BackingStoreMMURequestS2H,
   IfcNames_BackingStoreMMUIndicationH2S,

   IfcNames_MMURequestS2H,
   IfcNames_MMUIndicationH2S,
   IfcNames_AlgoMMURequestS2H,
   IfcNames_AlgoMMUIndicationH2S,

   IfcNames_NandMMURequestS2H,
   IfcNames_NandMMUIndicationH2S,

   IfcNames_NandCfgRequestS2H,
   IfcNames_NandCfgIndicationH2S,

   IfcNames_AlgoRequestS2H,
   IfcNames_AlgoIndicationH2S

   } IfcNames deriving (Eq,Bits);

