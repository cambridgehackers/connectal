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

#ifdef __KERNEL__
#include <linux/delay.h>  // msleep
#include <linux/kthread.h>
#else
#include <string.h>
#include <sys/mman.h>
#include <pthread.h>
#include <fcntl.h>
#include <sys/select.h>
#endif

#include "dmaManager.h"
#include "sock_utils.h"  // bsim_poll_interrupt()
#include "GeneratedTypes.h" 

#define MAX_INDARRAY 4
static PortalInternal intarr[MAX_INDARRAY];

static sem_t test_sem;
static int burstLen = 16;
#ifndef BSIM
#define numWords 0x1240000/4 // make sure to allocate at least one entry of each size
#else
#define numWords 0x1240/4
#endif
static long alloc_sz = numWords*sizeof(unsigned int);
static DmaManagerPrivate priv;

int RtestIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount )
{
         PORTAL_PRINTF( "Rtest_readDone(mismatch = %x)\n", mismatchCount);
         sem_post(&test_sem);
	 return 0;
}
int MMUIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer)
{
        //PORTAL_PRINTF("configResp %x\n", pointer);
        sem_post(&priv.confSem);
	return 0;
}
int MMUIndicationWrapperidResponse_cb (  struct PortalInternal *p, const uint32_t sglId ) {
        priv.sglId = sglId;
        sem_post(&priv.sglIdSem);
	return 0;
};
int MMUIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra ) {
  static int maxnumber = 10;
  if (maxnumber-- > 0)
    PORTAL_PRINTF("DmaIndication::dmaError(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
  return 0;
}

void manual_event(void)
{
    int i;

    for (i = 0; i < MAX_INDARRAY; i++)
      portalCheckIndication(&intarr[i]);
}

#ifdef __KERNEL__
DECLARE_COMPLETION(worker_completion);
#endif
static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (1) {
#if defined(BSIM) && !defined(__KERNEL__)
        if (bsim_poll_interrupt())
#endif
            manual_event();
#ifdef __KERNEL__
        msleep(10);
        if (kthread_should_stop())
            break;
#else ///////////////////////// userspace version
        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 10000;
        select(0, NULL, NULL, NULL, &timeout);
#endif
    }
#ifdef __KERNEL__
    complete(&worker_completion);
#endif
    return rc;
}

MMUIndicationCb MMUIndication_cbTable = {
    MMUIndicationWrapperidResponse_cb,
    MMUIndicationWrapperconfigResp_cb,
    MMUIndicationWrappererror_cb,
};
RtestIndicationCb RtestIndication_cbTable = {
    RtestIndicationWrapperreadDone_cb,
};
int main(int argc, const char **argv)
{
  int srcAlloc;
  unsigned int *srcBuffer;
  unsigned int ref_srcAlloc;
  int rc = 0, i;
  pthread_t tid = 0;

  init_portal_internal(&intarr[0], IfcNames_HostMMUIndication, 0, MMUIndication_handleMessage, &MMUIndication_cbTable, NULL, NULL, MMUIndication_reqinfo);// fpga1
  init_portal_internal(&intarr[1], IfcNames_RtestIndication,   0, RtestIndication_handleMessage, &RtestIndication_cbTable, NULL, NULL, RtestIndication_reqinfo); // fpga2
  init_portal_internal(&intarr[2], IfcNames_HostMMURequest,    0, NULL, NULL, NULL, NULL, MMURequest_reqinfo); // fpga3
  init_portal_internal(&intarr[3], IfcNames_RtestRequest,      0, NULL, NULL, NULL, NULL, RtestRequest_reqinfo);    // fpga4

  sem_init(&test_sem, 0, 0);
  DmaManager_init(&priv, &intarr[2]);
  srcAlloc = portalAlloc(alloc_sz);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d\n", rc);
    return rc;
  }

  PORTAL_PRINTF( "Main: creating exec thread\n");
  if(pthread_create(&tid, NULL, pthread_worker, NULL)){
   PORTAL_PRINTF( "error creating exec thread\n");
   return -1;
  }
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

  for (i = 0; i < numWords; i++)
    srcBuffer[i] = i;

  PORTAL_PRINTF( "Test 1: check for match\n");
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  PORTAL_PRINTF( "Main: before DmaManager_reference(%x)\n", srcAlloc);
  ref_srcAlloc = DmaManager_reference(&priv, srcAlloc);
  PORTAL_PRINTF( "Main: starting read %08x\n", numWords);
  RtestRequest_startRead (&intarr[3], ref_srcAlloc, numWords, burstLen, 1);
  PORTAL_PRINTF( "Main: waiting for semaphore1\n");
  sem_wait(&test_sem);

  PORTAL_PRINTF( "Test 2: check that mismatch is detected\n");
  for (i = 0; i < numWords; i++)
    srcBuffer[i] = 1-i;
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  RtestRequest_startRead (&intarr[3], ref_srcAlloc, numWords, burstLen, 1);
  PORTAL_PRINTF( "Main: waiting for semaphore2\n");
  sem_wait(&test_sem);

  PORTAL_PRINTF( "Main: all done\n");
#ifdef __KERNEL__
  if (tid && !kthread_stop (tid)) {
    printk("kthread stops");
  }
  wait_for_completion(&worker_completion);
#endif

#ifdef __KERNEL__
  portalmem_dmabuffer_destroy(srcAlloc);
#endif
  return 0;
}
