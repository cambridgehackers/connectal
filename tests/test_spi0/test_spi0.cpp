
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


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <string.h>
#include <fcntl.h>
#include <asm/ioctl.h>
#include <linux/types.h>

#include "SPIRequest.h"
#include "SPIResponse.h"


//***********************************************************************
// copied from linux-xlnx/include/uapi/linux/spi/spidev.h

#define SPI_IOC_MAGIC			'k'

/* Read / Write of SPI mode (SPI_MODE_0..SPI_MODE_3) */
#define SPI_IOC_RD_MODE			_IOR(SPI_IOC_MAGIC, 1, __u8)
#define SPI_IOC_WR_MODE			_IOW(SPI_IOC_MAGIC, 1, __u8)

/* Read / Write SPI bit justification */
#define SPI_IOC_RD_LSB_FIRST		_IOR(SPI_IOC_MAGIC, 2, __u8)
#define SPI_IOC_WR_LSB_FIRST		_IOW(SPI_IOC_MAGIC, 2, __u8)

/* Read / Write SPI device word length (1..N) */
#define SPI_IOC_RD_BITS_PER_WORD	_IOR(SPI_IOC_MAGIC, 3, __u8)
#define SPI_IOC_WR_BITS_PER_WORD	_IOW(SPI_IOC_MAGIC, 3, __u8)

/* Read / Write SPI device default max speed hz */
#define SPI_IOC_RD_MAX_SPEED_HZ		_IOR(SPI_IOC_MAGIC, 4, __u32)
#define SPI_IOC_WR_MAX_SPEED_HZ		_IOW(SPI_IOC_MAGIC, 4, __u32)

//
//***********************************************************************

#define SPIDEVICENAME "/dev/spidev2.0"

static int spidevicefd;
static uint8_t spimode = 0;
static uint8_t spibits = 8;
static uint32_t speed = 50000;
static uint16_t delay = 100;

uint32_t bit_sel(uint32_t lsb, uint32_t msb, uint32_t v)
{
  return (v >> lsb) & ~(~0 << (msb-lsb+1));
}

class SPIResponse : public SPIResponseWrapper
{
public:
  virtual void read_resp(uint8_t v){
    fprintf(stderr, "read_resp cd:%d wp:%d\n", (v&2)>>1, v&1);
  }
  virtual void emio_sample(uint32_t v){
    fprintf(stderr, "emio_sample(%08x)\n", v);
  }
  virtual void cnt_cycle_resp(uint32_t v){
    fprintf(stderr, "cnt_cycle_resp %d\n", v);
  } 
  SPIResponse(unsigned int id) : SPIResponseWrapper(id){}
};


int main(int argc, const char **argv)
{
  SPIRequestProxy *device = new SPIRequestProxy(IfcNames_ControllerRequest);
  SPIResponse *ind = new SPIResponse(IfcNames_ControllerResponse);

  spidevicefd = open(SPIDEVICENAME, O_RDWR);
  if (spidevicefd < 0
      || ioctl(spidevicefd, SPI_IOC_WR_MODE, &spimode) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_MODE, &spimode) == -1
      || ioctl(spidevicefd, SPI_IOC_WR_BITS_PER_WORD, &spibits) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_BITS_PER_WORD, &spibits) == -1
      || ioctl(spidevicefd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_MAX_SPEED_HZ, &speed) == -1)
    printf("Error: cannot open SPI device\n");
  
  while(1){
    sleep(1);
    device->cnt_cycle_req(100);
  }

}
