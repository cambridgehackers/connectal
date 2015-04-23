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

#include "StdDmaIndication.h"
#include "MMURequest.h"
#include "Ov7670ControllerRequest.h"
#include "Ov7670ControllerIndication.h"
#include "pthread.h"

int slaveaddr[3];
int addr;

int rdClock[64];
int rdData[64];
int rdOutEn[64];
volatile int rdSample[64];
volatile int cursor = 0;
volatile int phase = 0;
sem_t bit_sem;

class Ov7670ControllerIndication : public Ov7670ControllerIndicationWrapper {
  int datacount;
  int gapcount;
public:
  Ov7670ControllerIndication(unsigned int id) : Ov7670ControllerIndicationWrapper(id), datacount(0), gapcount(0) {}
  ~Ov7670ControllerIndication() {}
  virtual void i2cResponse(uint8_t bus, uint8_t data) {
    fprintf(stderr, "i2c bus %d device %d addr %x response %02x\n", bus, slaveaddr[bus], addr, data);
  }
  virtual void pinResponse(uint8_t sdaIn) {
    int pos = (phase == 2) ? cursor-1 : cursor;
    if (pos > 0) {
      int newsample = (rdSample[cursor] << 1) | sdaIn;
      fprintf(stderr, "i2c cursor %3d phase %d sda %d %d %d\n", cursor, phase, sdaIn, rdSample[cursor], newsample);
      rdSample[cursor] = newsample;
    }
    sem_post(&bit_sem);
  }
  virtual void vsync(uint32_t cycles, uint8_t href) {
    //fprintf(stderr, "vsync %8d href %d\n", cycles, href);
    if (datacount) {
      fprintf(stderr, "vsync datacount=%8d gapcount=%8d\n", datacount, gapcount);
      datacount = 0;
      gapcount = 0;
    }
  }
  virtual void data(uint8_t first, uint8_t gap, uint8_t data) {
    //if (gap) fprintf(stderr, "data %8x first %d gap %d\n", data, first, gap);
    datacount++;
    if (gap) gapcount++;
  }
  virtual void frameStarted(uint8_t first) {
    //if (first) fprintf(stderr, "frameStarted %d\n", first);
  }
  virtual void frameTransferred() {
    //fprintf(stderr, "frameTransferred\n");
  }
  virtual void data4(uint32_t data) {
  }
};

void enqueueStart()
{
  rdClock[cursor] = 0b110;
  rdData[cursor] = 0b100;
  rdOutEn[cursor] = 0b111;
  cursor++;
}
void enqueueStop()
{
  rdClock[cursor] = 0b001;
  rdData[cursor] = 0b011;
  rdOutEn[cursor] = 0b111;
  cursor++;
}
void enqueueIdle()
{
  rdClock[cursor] = 0b111;
  rdData[cursor] = 0b111;
  rdOutEn[cursor] = 0b111;
  cursor++;
}
void enqueueBitOut(int b)
{
    rdClock[cursor] = 0b010;
    rdData[cursor] = b ? 0b111 : 0b000;
    rdOutEn[cursor] = 0b111;
    cursor++;
}
void enqueueBitIn()
{
    rdClock[cursor] = 0b010;
    rdData[cursor] = 0;
    rdOutEn[cursor] = 0b000;
    cursor++;
}
void enqueueAck()
{
    rdClock[cursor] = 0b010;
    rdData[cursor] = 0;
    rdOutEn[cursor] = 0b000;
    cursor++;
}
void enqueueMAck()
{
    rdClock[cursor] = 0b010;
    rdData[cursor] = 0b111;
    rdOutEn[cursor] = 0b111;
    cursor++;
}

int bit(int v, int pos)
{
  return (v >> pos) & 1;
}

int main(int argc, const char **argv)
{
  Ov7670ControllerRequestProxy device(IfcNames_Ov7670ControllerRequestS2H);
  Ov7670ControllerIndication deviceResponse(IfcNames_Ov7670ControllerIndicationH2S);
  MMURequestProxy *mmuRequest = new MMURequestProxy(IfcNames_MMURequestS2H);
  DmaManager *dma = new DmaManager(mmuRequest);
  MemServerRequestProxy *memServerRequest = new MemServerRequestProxy(IfcNames_MemServerRequestS2H);
  MemServerIndication *memServerIndication = new MemServerIndication(memServerRequest, IfcNames_MemServerIndicationH2S);
  MMUIndication mmuIndication(dma, IfcNames_MMUIndicationH2S);

  int len = 640*480*4;
  int nfbAlloc = portalAlloc(4096, 0);
  unsigned int *nfbBuffer = (unsigned int *)portalMmap(nfbAlloc, 4096);
  unsigned int ref_nfbAlloc = dma->reference(nfbAlloc);
  int fbAlloc = portalAlloc(len, 0);
  unsigned int *fbBuffer = (unsigned int *)portalMmap(fbAlloc, len);
  unsigned int ref_fbAlloc = dma->reference(fbAlloc);

  device.setPowerDown(0);
  device.setReset(0);
  sleep(1);
  device.setReset(1);
  fprintf(stderr, "ref_fbAlloc=%d\n", ref_fbAlloc);
  device.setFramePointer(ref_fbAlloc);
  // hsync instead of href
  //device.i2cRequest(0, 1, 0x21, 0x15, 0x40);
  // always has href
  device.i2cRequest(0, 1, slaveaddr[0], 0x3c, 0x80);

  slaveaddr[0] = 0x21;
  slaveaddr[1] = 0x1e;
  slaveaddr[2] = 0x69;
  addr = 0x5a;

  cursor = 0;
  // START symbol
  enqueueStart();
  for (int s = 6; s >= 0; s--) {
    enqueueBitOut(bit(slaveaddr[0], s));
  }
  enqueueBitOut(0); // write
  enqueueAck();
  for (int s = 7; s >= 0; s--) {
    enqueueBitOut(bit(addr, s));
  }
  enqueueAck();
  //enqueueStop();
  //enqueueIdle();
  //enqueueStart();
  for (int s = 6; s >= 0; s--) {
    enqueueBitOut(bit(slaveaddr[0], s));
  }
  enqueueBitOut(1); // read
  enqueueAck();
  for (int s = 7; s >= 0; s--) {
    enqueueBitIn();
  }
  enqueueMAck();
  enqueueStop();
  enqueueIdle();
  int max_cursor = cursor;

  for (int i = 0; i < cursor; i++) {
    fprintf(stderr, "CYCLE %3d CLK %d OUT %d OE %d IN %x\n", i, rdClock[i], rdData[i], rdOutEn[i], rdSample[i]);
  }
  cursor = 0;
  sem_init(&bit_sem, 0, 0);
  for (int i = 0; i < max_cursor; i++) {
    cursor = i;
    for (phase = 2; phase >= 0; phase--) {
      device.pinRequest(bit(rdOutEn[i], phase), bit(rdClock[i], phase), bit(rdData[i], phase));
      sem_wait(&bit_sem);
    }
  }
  for (int i = 0; i < max_cursor; i++) {
    fprintf(stderr, "CYCLE %3d CLK %d OUT %d OE %d IN %x\n", i, rdClock[i], rdData[i], rdOutEn[i], rdSample[i]);
  }
  return 0;


  for (int i = 0; i < 128; i++) {
    int write = 0;
    int val = 0x33;
    addr = i;
    device.i2cRequest(0, write, slaveaddr[0], addr, val);
    device.i2cRequest(1, write, slaveaddr[1], addr, val);
    device.i2cRequest(2, write, slaveaddr[2], addr, val);
    if (0) {
    // product ID: 0x76
    device.i2cRequest(0, 0, slaveaddr[0], 0x0a, 0);
    // product VER: 0x70
    device.i2cRequest(0, 0, slaveaddr[0], 0x0b, 0);
    // mfg id: 0x7F
    device.i2cRequest(0, 0, slaveaddr[0], 0x1c, 0);
    // mfg id: 0xA2
    device.i2cRequest(0, 0, slaveaddr[0], 0x1d, 0);
    }
    sleep(1);
  }
  for (int i = 0; i < 64; i++)
    fprintf(stderr, " %02x", fbBuffer[i] & 0xff);
  fprintf(stderr, "\n");
  return 0;
}
