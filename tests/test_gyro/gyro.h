
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

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

#define WHO_AM_I        0x0F
#define CTRL_REG1       0x20
#define CTRL_REG2       0x21
#define CTRL_REG3       0x22
#define CTRL_REG4       0x23
#define CTRL_REG5       0x24
#define REFERENCE       0x25
#define OUT_TEMP        0x26
#define STATUS_REG      0x27
#define OUT_X_L         0x28
#define OUT_X_H         0x29
#define OUT_Y_L         0x2A
#define OUT_Y_H         0x2B
#define OUT_Z_L         0x2C
#define OUT_Z_H         0x2D
#define FIFO_CTRL_REG   0x2E
#define FIFO_SRC_REG    0x2F
#define INT1_CFG        0x30
#define INT1_SRC        0x31
#define INT1_THS_XH     0x32
#define INT1_THS_XL     0x33
#define INT1_THS_YH     0x34
#define INT1_THS_YL     0x35
#define INT1_THS_ZH     0x36
#define INT1_THS_ZL     0x37
#define INT1_DURATION   0x38


#define CTRL_REG1_DR1   0x80
#define CTRL_REG1_DR0   0x40
#define CTRL_REG1_BW1   0x20
#define CTRL_REG1_BW0   0x10
#define CTRL_REG1_PD    0x08
#define CTRL_REG1_ZEN   0x04
#define CTRL_REG1_YEN   0x02
#define CTRL_REG1_XEN   0x01

#define CTRL_REG2_HPM1	0x20
#define CTRL_REG2_HPM0	0x10
#define CTRL_REG2_HPCF3	0x08
#define CTRL_REG2_HPCF2	0x04
#define CTRL_REG2_HPCF1	0x02
#define CTRL_REG2_HPCF0	0x01

#define CTRL_REG3_I1_INT1	0x80
#define CTRL_REG3_I1_BOOT	0x40
#define CTRL_REG3_H_LACTIVE	0x20
#define CTRL_REG3_PP_OD		0x10
#define CTRL_REG3_I2_DRDY	0x08
#define CTRL_REG3_I2_WTM	0x04
#define CTRL_REG3_I2_ORUN	0x02
#define CTRL_REG3_I2_EMPTY	0x01

#define CTRL_REG4_BDU	0x80
#define CTRL_REG4_BLE	0x40
#define CTRL_REG4_FS1	0x20
#define CTRL_REG4_FS0	0x10
#define CTRL_REG4_ST1	0x04
#define CTRL_REG4_ST0	0x02
#define CTRL_REG4_SIM	0x01

#define CTRL_REG5_BOOT	        0x80
#define CTRL_REG5_FIFO_EN	0x40
#define CTRL_REG5_HP_EN         0x10
#define CTRL_REG5_INT1_SEL1	0x08
#define CTRL_REG5_INT1_SEL0	0x04
#define CTRL_REG5_OUT_SEL1	0x02
#define CTRL_REG5_OUT_SEL0	0x01
