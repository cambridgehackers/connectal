
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
#include "/usr/include/linux/spi/spidev.h"

#include "SPIRequest.h"
#include "SPIResponse.h"

#define SPIDEVICENAME "/dev/spidev2.0"

static int spidevicefd;
static uint8_t spimode = 0;
static uint8_t spibits = 8;
static uint32_t speed = 25000;
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
    int sson = bit_sel(9,9,v);
    int mosi = bit_sel(8,8,v);
    int cnt  = bit_sel(0,7,v);
    fprintf(stderr, "emio_sample{sson:%d, mosi:%d, cnt:%d}\n", sson, mosi, cnt);
  }
  virtual void cnt_cycle_resp(uint32_t v){
    fprintf(stderr, "cnt_cycle_resp %d\n", v);
  } 
  virtual void spi_word(uint32_t v){
    fprintf(stderr, "spi_word %08x\n", v);
  }
  SPIResponse(unsigned int id) : SPIResponseWrapper(id){}
};


int main(int argc, const char **argv)
{
  SPIRequestProxy *device = new SPIRequestProxy(IfcNames_ControllerRequest);
  SPIResponse *ind = new SPIResponse(IfcNames_ControllerResponse);

  spidevicefd = open(SPIDEVICENAME, O_RDWR);
  if (spidevicefd < 0)
    printf("Error: cannot open SPI device\n");
  else if (ioctl(spidevicefd, SPI_IOC_WR_MODE, &spimode) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_MODE, &spimode) == -1
      || ioctl(spidevicefd, SPI_IOC_WR_BITS_PER_WORD, &spibits) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_BITS_PER_WORD, &spibits) == -1
      || ioctl(spidevicefd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1
      || ioctl(spidevicefd, SPI_IOC_RD_MAX_SPEED_HZ, &speed) == -1)
    printf("Error: cannot configure SPI device\n");
  else
    printf("Successfully opened spi %x\n", spidevicefd);

  device->cnt_cycle_req(16);
  device->set_spew_en(1);

  uint8_t iter = 1;
  while(1) {
    uint8_t tx[sizeof(uint32_t)], rx[sizeof(uint32_t)];
    for(int i = 0; i < sizeof(uint32_t); i++)
      tx[i] = iter;
    struct spi_ioc_transfer tr;
    tr.tx_buf = (unsigned long)tx;
    tr.rx_buf = (unsigned long)rx;
    tr.len = sizeof(tx);
    tr.delay_usecs = delay;
    tr.speed_hz = speed;
    tr.bits_per_word = spibits;
    if (ioctl(spidevicefd, SPI_IOC_MESSAGE(1), &tr) < 1)
      printf("can't send spi message\n");
    else
      printf("successfully sent spi message\n");
    iter++;
    sleep(2);
  }

}
