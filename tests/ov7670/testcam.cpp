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
#include "dmaManager.h"
#include "Ov7670ControllerRequest.h"
#include "Ov7670ControllerIndication.h"

int slaveaddr[3];
int addr;

sem_t bit_sem;

class Ov7670ControllerIndication : public Ov7670ControllerIndicationWrapper {
  int datacount;
  int gapcount;
public:
  Ov7670ControllerIndication(unsigned int id) : Ov7670ControllerIndicationWrapper(id), datacount(0), gapcount(0) {}
  ~Ov7670ControllerIndication() {}
  virtual void i2cResponse(uint8_t bus, uint8_t data) {
    fprintf(stderr, "i2c bus %d device %d addr %x response %02x\n", bus, slaveaddr[bus], addr, data);
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

int main(int argc, const char **argv)
{
  DmaManager *dma = platformInit();
  Ov7670ControllerRequestProxy device(IfcNames_Ov7670ControllerRequestS2H);
  Ov7670ControllerIndication deviceResponse(IfcNames_Ov7670ControllerIndicationH2S);

  int len = 640*480*4;
  int nfbAlloc = portalAlloc(4096, 0);
  unsigned int *nfbBuffer = (unsigned int *)portalMmap(nfbAlloc, 4096);
  unsigned int ref_nfbAlloc = dma->reference(nfbAlloc);
  int fbAlloc = portalAlloc(len, 0);
  unsigned int *fbBuffer = (unsigned int *)portalMmap(fbAlloc, len);
  unsigned int ref_fbAlloc = dma->reference(fbAlloc);

  sem_init(&bit_sem, 0, 0);

  device.setPowerDown(0);
  device.setReset(0);
  sleep(1);
  device.setReset(1);
  sleep(1);
  fprintf(stderr, "ref_fbAlloc=%d\n", ref_fbAlloc);
  device.setFramePointer(ref_fbAlloc);

  // register reset
  device.i2cRequest(0, 1, 0x21, 0x12, 0x80);

  // hsync instead of href
  //device.i2cRequest(0, 1, 0x21, 0x15, 0x40);
  // always has href
  // device.i2cRequest(0, 1, slaveaddr[0], 0x3c, 0x80);

  slaveaddr[0] = 0x21;
  slaveaddr[1] = 0x1e;
  slaveaddr[2] = 0x69;
  addr = 0x5a;

  for (int i = 0; i < 128; i++) {
    int write = 0;
    int val = 0x33;
    addr = i;
    device.i2cRequest(0, write, slaveaddr[0], addr, val);
    if (!write) sem_wait(&bit_sem);

    device.i2cRequest(1, write, slaveaddr[1], addr, val);
    if (!write) sem_wait(&bit_sem);

    device.i2cRequest(2, write, slaveaddr[2], addr, val);
    if (!write) sem_wait(&bit_sem);

  }
  if (1) {
    // product ID: 0x76
    device.i2cRequest(0, 0, slaveaddr[0], 0x0a, 0);
    sem_wait(&bit_sem);

    // product VER: 0x70
    device.i2cRequest(0, 0, slaveaddr[0], 0x0b, 0);
    sem_wait(&bit_sem);

    // mfg id: 0x7F
    device.i2cRequest(0, 0, slaveaddr[0], 0x1c, 0);
    sem_wait(&bit_sem);

    // mfg id: 0xA2
    device.i2cRequest(0, 0, slaveaddr[0], 0x1d, 0);
    sem_wait(&bit_sem);
  }
  for (int i = 0; i < 64; i++)
    fprintf(stderr, " %02x", fbBuffer[i] & 0xff);
  fprintf(stderr, "\n");
  return 0;
}
