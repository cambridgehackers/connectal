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
#include <stdio.h>
#include <linux/types.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include "/usr/include/linux/i2c.h"
#include "/usr/include/linux/i2c-dev.h"

#define I2C_HDMI_ADDR         (0x72/2) // == 0x39 (LSB is just 'W/nR', so elided on linux)
//#define I2C_EDID_ADDR         0x3f
#define I2C_ZC702_MUX_ADDR 0x74
static int i2c_write_array(int fd, int device, unsigned char *datap, int size, int byte_write)
{
    struct i2c_smbus_ioctl_data args;
    union i2c_smbus_data ioctl_data;
    args.read_write = I2C_SMBUS_WRITE;
    args.size = I2C_SMBUS_BYTE_DATA;
    args.data = &ioctl_data;

    int status = ioctl(fd, I2C_SLAVE, device);
    if (status != 0) {
	 fprintf(stderr, "[i2chdmi] i2c_write_array: ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);
         return -1;
    }
    while (size) {
        args.command = *datap++ | byte_write;
        ioctl_data.byte = *datap++;
        status = ioctl(fd, I2C_SMBUS, &args);
	if (status != 0) {
	     fprintf(stderr, "[i2chdmi] i2c_write_array: ioctl I2C_SMBUS status=%d errno=%d\n", status, errno);
             return -1;
        }
        size -= 2;
    }
    return 0;
}
unsigned char i2c_read_reg(int fd, int device, unsigned char reg)
{
    struct i2c_smbus_ioctl_data args;
    union i2c_smbus_data ioctl_data;
    args.read_write = I2C_SMBUS_READ;
    args.size = I2C_SMBUS_BYTE_DATA;
    args.data = &ioctl_data;

    int status = ioctl(fd, I2C_SLAVE, device);
    if (status != 0)
	 fprintf(stderr, "[i2chdmi] i2c_read_reg: ioctl I2C_SLAVE status=%d errno=%d\n", status, errno);

    args.command = reg;
    ioctl_data.byte = 0;
    status = ioctl(fd, I2C_SMBUS, &args);
    if (status != 0)
      fprintf(stderr, "[i2chdmi] i2c_read_reg: ioctl I2C_SMBUS status=%d errno=%d\n", status, errno);
    return ioctl_data.byte;
}
void init_i2c_hdmi(void)
{
static unsigned char muxdata[] = {2, 2};
static unsigned char hdmidata[] = {
#if 1
    0x01, 0x00, // Set N Value(6144)
    0x02, 0x18, // Set N Value(6144)
    0x03, 0x00, // Set N Value(6144)
    0x41, 0x10, /* Powerup the Tx */
    0xA1, 0x3c, // power off TMDS clock and data
    0xD6, 0xC0 | 0x10, /* HPD control (and TMDS CLK soft turn on) */
    // Fixed registers that must be set on powerup
    0x98, 0x03,   0x9A, 0xE0,   0x9C, 0x30,  0x9D, 0x61,
    0xA2, 0xA4,   0xA3, 0xA4,   0xE0, 0xD0,  0xF9, 0x00,

    /* Coefficient Update */
    0x1A, 0x08,   0x1B, 0x00,   0x1C, 0x00,   0x1D, 0x00,
    0x1E, 0x1A,   0x1F, 0x86,   0x20, 0x1A,   0x21, 0x49,
    0x22, 0x08,   0x23, 0x00,   0x24, 0x1D,   0x25, 0x3F,
    0x26, 0x04,   0x27, 0x22,   0x28, 0x00,   0x29, 0x00,
    0x2A, 0x08,   0x2B, 0x00,   0x2C, 0x0E,   0x2D, 0x2D,
    0x2E, 0x19,   0x2F, 0x14,
    0x48, 0x08, /* video input justification */
    0x55, 0x00,   0x56, 0x28, /* AVI InfoFrame */
    // Fixed registers that must be set on powerup
    0xAF, 0x04,
    0xDE, 0x9C, // ADI required write
    0xE4, 0x60, // ADI required Write

#else
    0x15, 0x00, // Input 444 (RGB or YCrCb) with Separate Syncs
    0x16, 0x61, // 44.1kHz fs, YPrPb 444
    0x18, 0x46, // CSC disabled
    0x40, 0x80, // General Control Packet Enable
    0x41, 0x10, // Power Down control
    0x48, 0x48, // Reverse bus, Data right justified
    0x48, 0xA8, // Set Dither_mode - 12-to-10 bit
    0x4C, 0x06, // 12 bit Output
    0x55, 0x00, // Set RGB444 in AVinfo Frame
    0x55, 0x08, // Set active format Aspect
    0x96, 0x20, // HPD Interrupt clear
    0x9D, 0x61, // Set clock divide
    0xAF, 0x16, // Set HDMI Mode
    0xBA, 0x60, // No clock delay
    0xFA, 0x7D // Nbr of times to search for good phase
#endif
    };

printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    int fd = open("/dev/i2c-0", O_RDWR);
    if (fd < 0)
        printf("[%s] open failed\n", __FUNCTION__);
#ifndef BOARD_zedboard     // only initialize mux if not a zedboard
    //set mux for hdmi
    if (i2c_write_array(fd, I2C_ZC702_MUX_ADDR, muxdata, sizeof(muxdata), 0))
        printf("[%s] write mux failed\n", __FUNCTION__);
#endif
    //set hdmi data
    if (i2c_write_array(fd, I2C_HDMI_ADDR, hdmidata, sizeof(hdmidata), 0))
        printf("[%s] write data failed\n", __FUNCTION__);
    close(fd);
}

void i2c_hdmi_start(void)
{
static unsigned char hdmidata[] = {
    0x15, 0x01,   0x16, 0x38, /* Video input mode */
    0x18, 0xAB,   0x19, 0x37, /* Video output mode */
    0xA1, 0x00 // power on TMDS clock and data
};

printf("[%s:%d]\n", __FUNCTION__, __LINE__);
    int fd = open("/dev/i2c-0", O_RDWR);
    if (fd < 0)
        printf("[%s] open failed\n", __FUNCTION__);
    //set hdmi data
    if (i2c_write_array(fd, I2C_HDMI_ADDR, hdmidata, sizeof(hdmidata), 0))
        printf("[%s] write data failed\n", __FUNCTION__);
    for (int i = 0; i <= 0x8; i++) {
        int val = i2c_read_reg(fd, I2C_HDMI_ADDR, i);
printf("[%s:%d] HDMI [%x] = %x\n", __FUNCTION__, __LINE__, i, val);
    }
    close(fd);
}

void init_i2c_hdmi_rgb24(void)
{
static unsigned char muxdata[] = {2, 2};
static unsigned char hdmidata[] = {
    0x41, 0x10,  0xD6, 0xC0,  0x15, 0x00,  0x16, 0x38,
    0x18, 0xAB,  0x19, 0x37,  0x1A, 0x08,  0x1B, 0x00,
    0x1C, 0x00,  0x1D, 0x00,  0x1E, 0x1A,  0x1F, 0x86,
    0x20, 0x1A,  0x21, 0x49,  0x22, 0x08,  0x23, 0x00,
    0x24, 0x1D,  0x25, 0x3F,  0x26, 0x04,  0x27, 0x22,
    0x28, 0x00,  0x29, 0x00,  0x2A, 0x08,  0x2B, 0x00,
    0x2C, 0x0E,  0x2D, 0x2D,  0x2E, 0x19,  0x2F, 0x14,
    0x48, 0x08,  0x55, 0x00,  0x56, 0x28,  0x98, 0x03,
    0x9A, 0xE0,  0x9C, 0x30,  0x9D, 0x61,  0xA2, 0xA4,
    0xA3, 0xA4,  0xAF, 0x04,  0xE0, 0xD0,  0xF9, 0x00};

    int fd = open("/dev/i2c-0", O_RDWR);
    if (fd < 0)
        printf("[%s] open failed\n", __FUNCTION__);
    //set mux for hdmi
    if (i2c_write_array(fd, I2C_ZC702_MUX_ADDR, muxdata, sizeof(muxdata), 0))
        printf("[%s] write mux failed\n", __FUNCTION__);
    //set hdmi data
    if (i2c_write_array(fd, I2C_HDMI_ADDR, hdmidata, sizeof(hdmidata), 0))
        printf("[%s] write data failed\n", __FUNCTION__);
    close(fd);
}
