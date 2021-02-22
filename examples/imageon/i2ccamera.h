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
#define BYTE_OPERATION 0x80 // to use BYTE_READ/WRITE instead of BLOCK_READ/WRITE (cdce913 datasheet, table 8)
static void init_i2c_camera(void)
{
// PCA9546A Mux:
//     Channel 0: HDMIO_DDC   0x01
//     Channel 1: HDMIO       0x02
//     Channel 2: HDMII       0x04
//     Channel 3: PLL-IO      0x08
static unsigned char cmuxdata[] = {8, 8};
static unsigned char cdce913_data[] = {
    0x00, 0x81,  0x01, 0x01,
                  // [1:0] - Slave Address A[1:0]=01b
    //0x02, 0xB4,
    //0x03, 0x01,
    0x02, 0xB4,   // [  7] = M1 = 1 (PLL1 Clock)
                  // [1:0] = PDIV1[9:8] = 0
    0x03, 0x02,   // [7:0] = PDIV1[7:0] = 2
    0x04, 0x02,  0x05, 0x50,  0x06, 0x60,  0x07, 0x00,
    0x08, 0x00,  0x09, 0x00,  0x0A, 0x00,  0x0B, 0x00,
    0x0C, 0x00,  0x0D, 0x00,  0x0E, 0x00,  0x0F, 0x00,
    0x10, 0x00,  0x11, 0x00,  0x12, 0x00,  0x13, 0x00,
    //0x14, 0xED,
    0x14, 0x6D,   // [  7] = MUX1 = 0 (PLL1)
                  // [  6] = M2 = 1 (PDIV2)
                  // [5:4] = M3 = 2 (PDIV3)
    0x15, 0x02,
    //0x16, 0x01,
    //0x17, 0x01,
    0x16, 0x00,   // [6:0] = PDIV2 = 0 (reset and stand-by)
    0x17, 0x00,   // [6:0] = PDIV3 = 0 (reset and stand-by)
    //0x18, 0x00,
    //0x19, 0x40,
    //0x1A, 0x02,
    //0x1B, 0x08,
                  // PLL1 : Fin=27MHz, M=2, N=11, PDIV=2 Fout=74.25MHz
                  //        Fvco = 148.5 MHz
                  //        P = 4 - int(log2(11/2)) = 4 - 2 = 2
                  //        N'= 11 * 2^2 = 44
                  //        Q = int(44/2) = 22
                  //        R = 44 - 2*22 = 0
    0x18, 0x00,   // [7:0] = PLL1_0N[11:4] = 00000000
    0x19, 0xB0,   // [7:4] = PLL1_0N[3:0] = 1011
                  // [3:0] = PLL1_0R[8:5] = 0000
    0x1A, 0x02,   // [7:3] = PLL1_0R[4:0] = 00000
                  // [2:0] = PLL1_0Q[5:3] = 010
    0x1B, 0xC9,   // [7:5] = PLL1_0Q[2:0] = 110
                  // [4:2] = PLL1_0P[2:0] = 010
                  // [1:0] = VC01_0_RANGE[1:0] = 01 (125 MHz < Fvco1 < 150 MHz)
    //0x1C, 0x00,
    //0x1D, 0x40,
    //0x1E, 0x02,
    //0x1F, 0x08,
                  // PLL1 : Fin=27MHz, M=2, N=11, PDIV=2 Fout=74.25MHz
                  //        Fvco = 148.5 MHz
                  //        P = 4 - int(log2(11/2)) = 4 - 2 = 2
                  //        N'= 11 * 2^2 = 44
                  //        Q = int(44/2) = 22
                  //        R = 44 - 2*22 = 0
    0x1C, 0x00,   // [7:0] = PLL1_1N[11:4] = 00000000
    0x1D, 0xB0,   // [7:4] = PLL1_1N[3:0] = 1011
                  // [3:0] = PLL1_1R[8:5] = 0000
    0x1E, 0x02,   // [7:3] = PLL1_1R[4:0] = 00000
                  // [2:0] = PLL1_1Q[5:3] = 010
    0x1F, 0xC9,   // [7:5] = PLL1_1Q[2:0] = 110
                  // [4:2] = PLL1_1P[2:0] = 010
                  // [1:0] = VC01_1_RANGE[1:0] = 01 (125 MHz < Fvco1 < 150 MHz)
    // 148.500000 MHz
    // PLL1: M = 2, N = 11, Pdiv = 1
    //       Fin  = 27.000000MHz
    //       Fvco = Fin * N/M = 148.500000MHz
    //       Range = 1 (125 MHz <= Fvco < 150 MHz)
    //       Fout = Fvco / Pdiv = 148.500000MHz
    //       P = 4 - int(log2(M/N)) = 2
    //       Np = N * 2^P = 44
    //       Q = int(Np/M) = 22
    //       R = Np - M*Q = 0
    0x02, 0xB4,   // [  7] = M1 = 1 (PLL1 clock)
                  // [1:0] = Pdiv1[9:8]
    0x03, 0x01,   // [7:0] = Pdiv1[7:0]
    0x18, 0x00,   // [7:0] = PLL1_0N[11:4]
    0x19, 0xB0,   // [7:4] = PLL1_0N[3:0]
                  // [3:0] = PLL1_0R[8:5]
    0x1A, 0x02,   // [7:3] = PLL1_0R[4:0]
                  // [2:0] = PLL1_0Q[5:3]
    0x1B, 0xC9};  // [7:5] = PLL1_0Q[2:0]
                  // [4:2] = PLL1_0P[2:0]
                  // [1:0] = VCO1_0_RANGE[1:0]

    int fd = open("/dev/i2c-1", O_RDWR);
printf("[%s:%d] /dev/i2c-1 open fd %d\n", __FUNCTION__, __LINE__, fd);
    if (fd < 0)
        printf("[%s] /dev/i2c-1 open failed\n", __FUNCTION__);
    // setup mux for enabling clock generator
    if (i2c_write_array(fd, 0x70, cmuxdata, sizeof(cmuxdata), 0))
        printf("[%s] write mux failed\n", __FUNCTION__);
    int version = i2c_read_reg(fd, 0x65, 0x00 | BYTE_OPERATION);
printf("[%s:%d] pllversion %x\n", __FUNCTION__, __LINE__, version);
    // initialize clock generator
    if (i2c_write_array(fd, 0x65, cdce913_data, sizeof(cdce913_data), BYTE_OPERATION))
        printf("[%s] write data failed\n", __FUNCTION__);
    close(fd);
}
