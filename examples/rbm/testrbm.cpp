
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

#include <RbmRequest.h>
#include <RbmIndication.h>
#include "MemServerRequest.h"
#include "MMURequest.h"
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <semaphore.h>
#include <pthread.h>
#include <errno.h>
#include <math.h> // frexp(), fabs()
#include <assert.h>
#include "portalmat.h"
#include "rbm.h"
#include "mnist.h"

MmRequestTNProxy *mmdevice = 0;
MemServerRequestProxy *hostMemServerRequest;
MmIndication *mmdeviceIndication = 0;
SigmoidIndication *sigmoidindication = 0;
SigmoidRequestProxy *sigmoiddevice = 0;
RbmIndication *rbmDeviceIndication = 0;
RbmRequestProxy *rbmdevice = 0;
TimerIndication *timerdeviceIndication = 0;
TimerRequestProxy *timerdevice = 0;

long dotprod = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s ", prefix);
    for (unsigned int i = 0; i < (len > 64 ? 64 : len) ; i++) {
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
	if (i % 4 == 3)
	  fprintf(stderr, " ");
    }
    fprintf(stderr, "\n");
}

void *dbgThread(void *)
{
  while (1) {
    sleep(1);
    mmdevice->debug();
    //rbmdevice->sumOfErrorSquaredDebug();
    if (hostMemServerRequest) hostMemServerRequest->stateDbg(ChannelType_Read);
    sleep(5);
  }
  return 0;
}

int main(int argc, const char **argv)
{
  fprintf(stderr, "%s %s\n", __DATE__, __TIME__);
 
  mmdevice = new MmRequestTNProxy(IfcNames_MmRequestTNS2H);
  rbmdevice = new RbmRequestProxy(IfcNames_RbmRequestS2H);
  rbmDeviceIndication = new RbmIndication(IfcNames_RbmIndicationH2S);
  mmdeviceIndication = new MmIndication(IfcNames_MmIndicationH2S);
  sigmoiddevice = new SigmoidRequestProxy(IfcNames_SigmoidRequestS2H);
  sigmoidindication = new SigmoidIndication(IfcNames_SigmoidIndicationH2S);
  timerdevice = new TimerRequestProxy(IfcNames_TimerRequestS2H);
  timerdeviceIndication = new TimerIndication(IfcNames_TimerIndicationH2S);
  DmaManager *dma = platformInit();

  if(sem_init(&mul_sem, 1, 0)){
    fprintf(stderr, "failed to init mul_sem\n");
    return -1;
  }

  pthread_t dbgtid;
  fprintf(stderr, "creating debug thread\n");
  if(pthread_create(&dbgtid, NULL,  dbgThread, NULL)){
   fprintf(stderr, "error creating debug thread\n");
   exit(1);
  }

  matAllocator = new PortalMatAllocator(dma);
  configureSigmoidTable();
  int rv = 0;

  RBM rbm(dma);
  rbm.run();

  rbmdevice->finish();
  exit(rv);
}
