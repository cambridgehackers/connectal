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
/* copied from jca's i2chdmi.h */

#include <linux/types.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include "/usr/include/linux/i2c.h"
#include "/usr/include/linux/i2c-dev.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "i2c_zedboardandroid.h"



int fmcomms1_get_version(int fd, int device, unsigned char *datap, int size)
{
  int status;
  struct i2c_msg msgs[2];
  unsigned char command = 1;
  struct i2c_rdwr_ioctl_data arg;
  msgs[0].addr = device;
  msgs[0].flags = 0;
  msgs[0].len = 1;
  msgs[0].buf = &command;
  msgs[1].addr = device;
  msgs[1].flags = I2C_M_RD | I2C_M_RECV_LEN;
  msgs[1].len = 33;
  msgs[1].buf = datap;
  arg.msgs = &msgs[0];
  arg.nmsgs = 1;
  datap[0] = 1;
  status = ioctl(fd, I2C_RDWR, &arg);
  if (status != 0) {
    fprintf(stdout, "[%s:%d]: ioctl I2C_RW write status=%d errno=%d [%s]\n", __FILE__, __LINE__, status, errno, strerror(errno));
  }
  arg.msgs = &msgs[1];
  status = ioctl(fd, I2C_RDWR, &arg);
  if (status != 0) {
    fprintf(stdout, "[%s:%d]: ioctl I2C_RW read status=%d errno=%d [%s]\n", __FILE__, __LINE__, status, errno, strerror(errno));
  }
  return status;
}


unsigned char version_data[256];
unsigned char msgbuf[256];
void testi2c(const char *i2cdevice, int deviceid)
{
   

  int fd;
    int i;
    int res;
    printf("i2cdevice is %s, deviceid is 0x%02x\n", i2cdevice, deviceid);
    I2C_Init(i2cdevice, deviceid);


    // start version query
    memset(version_data, 0, 256);
    for (i = 0; i < 256; i += 16) {
      int j;
      res = I2C_Read(0x50, i, 64, msgbuf);
      printf("returned %d bytes\n", msgbuf[0]);
      for (j=0; j < 17; j += 1) {
	printf(" %2x[%c]", msgbuf[j],isalnum(msgbuf[j]) ? msgbuf[j]:' ');
      }
      printf("\n");
      if (res < 0) {
	fprintf(stdout, "testi2c failed eeprom read at %d\n", i);
	return;
      }
    }

    /*
    memset(version_data, 0, 128);
    res = fmcomms1_get_version(fd, deviceid, version_data, 128);
    printf ("getversion result %d\n", res);
    for (i = 0; i < 32; i += 1) {
      if ((i != 0) && ((i % 16) == 0)) printf("\n");
      printf(" %2x[%c]", version_data[i],isalnum(version_data[i]) ? version_data[i]:' ');
    }
    printf("\n");
    */
}
