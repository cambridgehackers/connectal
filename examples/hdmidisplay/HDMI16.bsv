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
import HDMI::*;

typedef HDMI#(Bit#(16)) HDMI16;

import "BDPI" function Action bdpi_hdmi_vsync(Bit#(1) v);
import "BDPI" function Action bdpi_hdmi_hsync(Bit#(1) v);
import "BDPI" function Action bdpi_hdmi_de(Bit#(1) v);
import "BDPI" function Action bdpi_hdmi_data(Bit#(16) v);
module mkResponder#(HDMI#(Bit#(16)) pins)(Empty);
    rule hvconv;
        bdpi_hdmi_vsync(pins.hdmi_vsync);
    endrule
    rule hvconh;
        bdpi_hdmi_hsync(pins.hdmi_hsync);
    endrule
    rule hvconde;
        bdpi_hdmi_de(pins.hdmi_de);
    endrule
    rule hvcond;
        bdpi_hdmi_data(pins.hdmi_data);
    endrule
endmodule
