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
#include <stdlib.h>
#include <unistd.h>

#include <assert.h>
#include <semaphore.h>

#include "ChannelSelectTestRequest.h"
#include "ChannelSelectTestIndication.h"
#include "DDSTestRequest.h"
#include "DDSTestIndication.h"
#include "GeneratedTypes.h"

sem_t data_sem;
sem_t config_sem;

class ChannelSelectTestIndication : public ChannelSelectTestIndicationWrapper
{

public:
  ChannelSelectTestIndication(unsigned int id) : ChannelSelectTestIndicationWrapper(id){}

  virtual void ifreqData(unsigned dataRe, unsigned dataIm){
    fprintf(stdout, "read %x %x\n", dataRe, dataIm);
  }
  virtual void setDataResp(){
    fprintf(stdout, "setDataResp\n");
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stdout, "setDataResp\n");
    sem_post(&config_sem);
  }
};

class DDSTestIndication : public DDSTestIndicationWrapper
{

public:
  DDSTestIndication(unsigned int id) : DDSTestIndicationWrapper(id){}

  virtual void ddsData(unsigned phase, unsigned dataRe, unsigned dataIm){
    fprintf(stdout, "data %d %X %x\n", phase, dataRe, dataIm);
    sem_post(&data_sem);
  }
  virtual void setConfigResp(){
    fprintf(stdout, "dds.setDataResp\n");
    sem_post(&config_sem);
  }
  
};

int main(int argc, const char **argv)
{

  ChannelSelectTestRequestProxy *ctdevice = 0;
  ChannelSelectTestIndication *ctindication = 0;
  DDSTestRequestProxy *ddsdevice = 0;
  DDSTestIndication *ddsindication = 0;
  sem_init(&data_sem, 0, 0);
  sem_init(&config_sem, 0, 0);
  fprintf(stdout, "Main::%s %s\n", __DATE__, __TIME__);

  ctdevice = new ChannelSelectTestRequestProxy(IfcNames_ChannelSelectTestRequest);

  ctindication = new ChannelSelectTestIndication(IfcNames_ChannelSelectTestIndication);

  ddsdevice = new DDSTestRequestProxy(IfcNames_DDSTestRequest);

  ddsindication = new DDSTestIndication(IfcNames_DDSTestIndication);

  fprintf(stdout, "DDSTest\n");
  ddsdevice->setPhaseAdvance(1, 0);

  for (int i = 0; i < 2048; i += 1) {
    ddsdevice->getData();
    sem_wait(&data_sem);
  }


  fprintf(stdout, "Main::starting\n");

  ctdevice->setCoeff(0, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(1, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(2, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setCoeff(3, 1<<21, 0);
  sem_wait(&config_sem);
  ctdevice->setPhaseAdvance(0, 1 << 21);
  sem_wait(&config_sem);

  int i;
  for (i = 0; i < 128; i += 1) {
    ctdevice->rfreqDataWrite(1<<16, 0);   // should be re=1, im=0
    sem_wait(&data_sem);
  }

  fprintf(stdout, "Main::stopping\n");

  exit(0);
}
