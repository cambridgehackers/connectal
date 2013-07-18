
// Copyright (c) 2013 Quanta Research Cambridge, Inc.

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

import SPI::*;
import I2C::*;

 // for HDMI
 // PORT fmc_imageon_iic_0_Rst_pin = fmc_imageon_iic_0_Rst, DIR = O
 // PORT fmc_imageon_iic_0_Sda_pin = fmc_imageon_iic_0_Sda, DIR = IO
 // PORT fmc_imageon_iic_0_Scl_pin = fmc_imageon_iic_0_Scl, DIR = IO

 // PORT fmc_imageon_video_clk1 = fmc_imageon_video_clk1, DIR = I, SIGIS = CLK, CLK_FREQ = 148500000
 // PORT fmc_imageon_vita_clk_pll = fmc_imageon_vita_clk_pll, DIR = O
 // PORT fmc_imageon_vita_reset_n = fmc_imageon_vita_reset_n, DIR = O
 // PORT fmc_imageon_vita_trigger = fmc_imageon_vita_trigger, DIR = O, VEC = [2:0]
 // PORT fmc_imageon_vita_monitor = fmc_imageon_vita_monitor, DIR = I, VEC = [1:0]
 // PORT fmc_imageon_vita_spi_sclk = fmc_imageon_vita_spi_sclk, DIR = O
 // PORT fmc_imageon_vita_spi_ssel_n = fmc_imageon_vita_spi_ssel_n, DIR = O
 // PORT fmc_imageon_vita_spi_mosi = fmc_imageon_vita_spi_mosi, DIR = O
 // PORT fmc_imageon_vita_spi_miso = fmc_imageon_vita_spi_miso, DIR = I
 // PORT fmc_imageon_vita_clk_out_p = fmc_imageon_vita_clk_out_p, DIR = I
 // PORT fmc_imageon_vita_clk_out_n = fmc_imageon_vita_clk_out_n, DIR = I
 // PORT fmc_imageon_vita_sync_p = fmc_imageon_vita_sync_p, DIR = I
 // PORT fmc_imageon_vita_sync_n = fmc_imageon_vita_sync_n, DIR = I
 // PORT fmc_imageon_vita_data_p = fmc_imageon_vita_data_p, DIR = I, VEC = [7:0]
 // PORT fmc_imageon_vita_data_n = fmc_imageon_vita_data_n, DIR = I, VEC = [7:0]

interface ImageonVita;
    method Bit#(1) reset_n();
    method Bit#(3) trigger();
    method Action monitor(Bit#(2) m);
    method Action data(Bit#(1) sync, Bit#(8) data);
    interface SPI_Pins spiPins;
endinterface
