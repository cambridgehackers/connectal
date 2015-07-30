
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
#include <sys/ioctl.h>
#include <linux/types.h>
#include "linux/spi/spidev.h"

#include "SPIRequest.h"
#include "SPIResponse.h"

#define SPIDEVICENAME "/dev/spidev2.0"

static int spidevicefd;
static uint8_t spimode = 0;
static uint8_t spibits = 8;
static uint32_t speed = 16666666;
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
  virtual void emio_sample(const Spew v){
    fprintf(stderr, "emio_sample{mo:%d, motn:%d, sson:%d, ssntn:%d, sclko:%d, sclktn:%d, cnt:%d}\n", 
	                       v.mo,  v.motn,  v.sson,  v.ssntn,  v.sclko,  v.sclktn,  v.cnt);
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
  SPIResponse ind(IfcNames_ControllerResponse);
  uint8_t iter = 1;

  device->set_clk_inv(0);
  device->set_spew_en(0);
  device->set_spew_src(0);
  spidevicefd = open(SPIDEVICENAME, O_RDWR);
  if (spidevicefd < 0){
    printf("Error: cannot open SPI device\n");
    goto finish;
  } else if (ioctl(spidevicefd, SPI_IOC_WR_MODE, &spimode) == -1
	     || ioctl(spidevicefd, SPI_IOC_RD_MODE, &spimode) == -1
	     || ioctl(spidevicefd, SPI_IOC_WR_BITS_PER_WORD, &spibits) == -1
	     || ioctl(spidevicefd, SPI_IOC_RD_BITS_PER_WORD, &spibits) == -1
	     || ioctl(spidevicefd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) == -1
	     || ioctl(spidevicefd, SPI_IOC_RD_MAX_SPEED_HZ, &speed) == -1){
    printf("Error: cannot configure SPI device\n");
    goto finish;
  } else {
    printf("Successfully opened spi %x\n", spidevicefd);
  }

  while(iter < 4){
    uint8_t tx[sizeof(uint32_t)], rx[sizeof(uint32_t)];
    for(unsigned int i = 0; i < sizeof(uint32_t); i++)
      tx[i] = 1;
    struct spi_ioc_transfer tr;
    tr.tx_buf = (unsigned long)tx;
    tr.rx_buf = (unsigned long)rx;
    tr.len = sizeof(tx);
    tr.delay_usecs = delay;
    tr.speed_hz = speed;
    tr.bits_per_word = spibits;
    {
      struct CycleReq cr;
      cr.clk_sel = 0;
      cr.clk_cnt = 10000;
      device->cnt_cycle_req(cr);
    }
    if (ioctl(spidevicefd, SPI_IOC_MESSAGE(1), &tr) < 1)
      printf("can't send spi message\n");
    else
      printf("successfully sent spi message\n");
    iter++;
    sleep(1);
  }
 finish:
  if (spidevicefd >= 0) 
    close(spidevicefd);
  return 0;
}
