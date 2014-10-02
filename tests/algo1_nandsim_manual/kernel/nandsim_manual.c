/* Copyright (c) 2014 Sungjin Lee, MIT
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

static int trace_memory;// = 1;

#define MAX_INDARRAY 4
static PortalInternal intarr[MAX_INDARRAY];

static sem_t test_sem;
static int burstLen = 16;
#ifndef BSIM
/*#define numWords 0x1240000/4 // make sure to allocate at least one entry of each size*/
#define numWords 1024
#else
#define numWords 0x124000/4
#endif
static long test_sz  = numWords*sizeof(unsigned int);
static long alloc_sz = numWords*sizeof(unsigned int);
static DmaManagerPrivate priv;
/*size_t numBytes = 0x1240000;*/
size_t numBytes = 1 << 12;
/*size_t nandBytes = 1 << 28;*/
size_t nandBytes = 1 << 20;

void NandSimIndicationWrappereraseDone_cb (  struct PortalInternal *p, const uint32_t tag )
{
	PORTAL_PRINTF( "cb: NandSim_eraseDone(tag = %x)\n", tag);
         sem_post(&test_sem);
}
void NandSimIndicationWrapperwriteDone_cb (  struct PortalInternal *p, const uint32_t tag )
{
	PORTAL_PRINTF( "cb: NandSim_writeDone(tag = %x)\n", tag);
         sem_post(&test_sem);
}
void NandSimIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t tag )
{
	PORTAL_PRINTF( "cb: NandSim_readDone(tag = %x)\n", tag);
         sem_post(&test_sem);
}
void NandSimIndicationWrapperconfigureNandDone_cb (  struct PortalInternal *p )
{
	PORTAL_PRINTF( "cb: NandSim_NandDone\n");
		 sem_post(&test_sem);
}
void MMUConfigIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer )
{
	PORTAL_PRINTF("cb: MMUConfigIndicationWrapperconfigResp_cb(physAddr=%x)\n", pointer);
        sem_post(&priv.confSem);
}

void MMUConfigIndicationWrapperidResponse_cb (  struct PortalInternal *p, const uint32_t sglId ) 
{
	PORTAL_PRINTF("cb: MMUConfigIndicationWrapperidResponse_cb\n");
        priv.sglId = sglId;
        sem_post(&priv.sglIdSem);
}

void DmaIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr )
{
	PORTAL_PRINTF("cb: DmaIndicationWrapperaddrResponse_cb\n");
}

void DmaIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec rec )
{
	PORTAL_PRINTF("cb: DmaIndicationWrapperreportStateDbg_cb\n");
        sem_post(&priv.dbgSem);
}

void DmaIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words )
{
	PORTAL_PRINTF("cb: DmaIndicationWrapperreportMemoryTraffic_cb\n");
        priv.mtCnt = words;
        sem_post(&priv.mtSem);
}

void DmaIndicationWrapperdmaError_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra ) 
{
	PORTAL_PRINTF("cb: DmaIndicationWrapperdmaError_cb\n");
}

void MMUConfigIndicationWrappererror_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra ) 
{
	PORTAL_PRINTF("cb: MMUConfigIndicationWrappererror_cb\n");
}

void DmaDebugRequestProxy_getMemoryTraffic (struct PortalInternal *p , const ChannelType rc )
{
	PORTAL_PRINTF("cb: DmaDebugRequestProxy_getMemoryTraffic\n");
}


void manual_event(void)
{
    int i;
    for (i = 0; i < MAX_INDARRAY; i++) {
      PortalInternal *instance = &intarr[i];
      volatile unsigned int *map_base = instance->map_base;
      unsigned int queue_status;
	  /*PORTAL_PRINTF ("[%d]\n", i);*/
      while ((queue_status= READL(instance, &map_base[IND_REG_QUEUE_STATUS]))) {
        unsigned int int_src = READL(instance, &map_base[IND_REG_INTERRUPT_FLAG]);
        unsigned int int_en  = READL(instance, &map_base[IND_REG_INTERRUPT_MASK]);
        unsigned int ind_count  = READL(instance, &map_base[IND_REG_INTERRUPT_COUNT]);
		/*PORTAL_PRINTF("(%d:fpga%d) about to receive messages int=%08x en=%08x qs=%08x cnt=%x\n", i, instance->fpga_number, int_src, int_en, queue_status, ind_count);*/
        instance->handler(instance, queue_status-1);
      }
    }
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
        if (kthread_should_stop()) {
		    PORTAL_PRINTF ("pthread_worker ends\n");
            break;
		}
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

int main(int argc, const char **argv)
{
  int srcAlloc;
  int nandAlloc;
  unsigned int *srcBuffer;
  unsigned int ref_srcAlloc;
  unsigned int *nandBuffer;
  unsigned int ref_nandAlloc;
  int rc = 0, i;
  pthread_t tid = 0;


  init_portal_internal(&intarr[2], IfcNames_NandsimMMUConfigRequest, MMUConfigRequestProxy_handleMessage);         // fpga3
  init_portal_internal(&intarr[0], IfcNames_NandsimMMUConfigIndication, MMUConfigIndicationWrapper_handleMessage);     // fpga1
  init_portal_internal(&intarr[3], IfcNames_NandSimRequest, NandSimRequestProxy_handleMessage);    // fpga4
  init_portal_internal(&intarr[1], IfcNames_NandSimIndication, NandSimIndicationWrapper_handleMessage); // fpga2
  DmaManager_init(&priv, NULL, &intarr[2]);
  sem_init(&test_sem, 0, 0);

  PORTAL_PRINTF( "Main: creating exec thread - %lu\n", sizeof (unsigned int) );
  if(pthread_create(&tid, NULL, pthread_worker, NULL)){
   PORTAL_PRINTF( "error creating exec thread\n");
   return -1;
  }

  nandAlloc = portalAlloc (nandBytes);
  PORTAL_PRINTF("nandAlloc=%d\n", nandAlloc);

  ref_nandAlloc = DmaManager_reference(&priv, nandAlloc);
  PORTAL_PRINTF("ref_nandAlloc=%d\n", ref_nandAlloc);

  nandBuffer = (unsigned int*)portalMmap(nandAlloc, nandBytes); 
  /*portalDCacheFlushInval(nandAlloc, nandBytes, nandBuffer);*/

  NandSimRequestProxy_configureNand (&intarr[3], ref_nandAlloc, nandBytes);
  PORTAL_PRINTF("Main::configure NAND fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
  sem_wait(&test_sem);


  srcAlloc = portalAlloc(alloc_sz);
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);
  ref_srcAlloc = DmaManager_reference(&priv, srcAlloc);

#ifdef BSIM
  portalEnableInterrupts(&intarr[0]);
  portalEnableInterrupts(&intarr[1]);
  portalEnableInterrupts(&intarr[2]);
  portalEnableInterrupts(&intarr[3]);
#endif

  PORTAL_PRINTF("Test 1: check for operations\n");
  PORTAL_PRINTF("Main: before DmaManager_reference(%u)\n", srcAlloc);

  for (i = 0; i < numBytes/4; i++) {
  		srcBuffer[i] = i;
  }

  PORTAL_PRINTF( "Main::starting write - begin %08zx\n", numBytes);
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  NandSimRequestProxy_startWrite (&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  PORTAL_PRINTF( "Main:: wait for semaphore\n");
  sem_wait(&test_sem);
  PORTAL_PRINTF ("write: %u %u %u %u\n", srcBuffer[0], srcBuffer[1], srcBuffer[2], srcBuffer[3]);

  for (i = 0; i < numBytes/4; i++) {
    srcBuffer[i] = 0;
  }

  PORTAL_PRINTF( "Main::starting read %08zx\n", numBytes);
  portalDCacheFlushInval(srcAlloc, alloc_sz, srcBuffer);
  NandSimRequestProxy_startRead (&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  sem_wait(&test_sem);
  PORTAL_PRINTF ("read: %u %u %u %u\n", srcBuffer[0], srcBuffer[1], srcBuffer[2], srcBuffer[3]);

  PORTAL_PRINTF( "Main::starting erase %08zx\n", numBytes);
  NandSimRequestProxy_startErase (&intarr[3], 0, numBytes);
  sem_wait(&test_sem);

  PORTAL_PRINTF( "Main::starting read %08zx\n", numBytes);
  NandSimRequestProxy_startRead (&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  sem_wait(&test_sem);
  PORTAL_PRINTF ("read: %u %u %u %u\n", srcBuffer[0], srcBuffer[1], srcBuffer[2], srcBuffer[3]);

  /*

  PORTAL_PRINTF("\n\nTest 2: check for match\n");
  {
	  unsigned long loop = 0;
	  unsigned long match = 0, mismatch = 0;
	  while (loop < nandBytes/4) {
		  int i;
		  for (i = 0; i < numBytes/4; i++) {
			  srcBuffer[i] = loop+i;
		  }

		  PORTAL_PRINTF("Main::starting write ref=%d, len=%08zx (%lu)\n", ref_srcAlloc, numBytes, loop);
		  NandSimRequestProxy_startWrite (&intarr[3], ref_srcAlloc, 0, loop*4, numBytes, 16);
		  sem_wait(&test_sem);

		  loop+=numBytes/4;
	  }

	  loop = 0;
	  while (loop < nandBytes/4) {
		  int i;
		  PORTAL_PRINTF("Main::starting read %08zx (%lu)\n", numBytes, loop);
		  NandSimRequestProxy_startRead (&intarr[3], ref_srcAlloc, 0, loop*4, numBytes, 16);
		  sem_wait(&test_sem);

		  for (i = 0; i < numBytes/4; i++) {
			  if (srcBuffer[i] != loop+i) {
				  PORTAL_PRINTF("Main::mismatch [%08zx] != [%08zx]\n", loop+i, srcBuffer[i]);
				  mismatch++;
			  } else {
				  match++;
			  }
		  }

		  loop+=numBytes/4;
	  }

	  PORTAL_PRINTF("Main::Summary: match=%lu mismatch:%lu (%lu) (%f percent)\n", 
			  match, mismatch, match+mismatch, (float)mismatch/(float)(match+mismatch)*100.0);
  }
  */

  /*
  PORTAL_PRINTF("\n\nTest 3: check for overwrite\n");
  {
  unsigned long loop = 0;
  unsigned long match = 0, mismatch = 0;
  while (loop < nandBytes) {
	  int i;
	  for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  srcBuffer[i] = loop+i+132;
	  }

	  PORTAL_PRINTF("Main::starting write ref=%d, len=%08zx (%lu)\n", ref_srcAlloc, numBytes, loop);
  	  NandSimRequestProxy_startWrite (&intarr[3], ref_srcAlloc, 0, loop, numBytes, 16);
      sem_wait(&test_sem);

	  loop+=numBytes;
  }

  loop = 0;
  while (loop < nandBytes) {
	  int i;
	  PORTAL_PRINTF("Main::starting read %08zx (%lu)\n", numBytes, loop);
	  NandSimRequestProxy_startRead (&intarr[3], ref_srcAlloc, 0, loop, numBytes, 16);
	  sem_wait(&test_sem);

	  for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  if (srcBuffer[i] != loop+i+132) {
			  PORTAL_PRINTF("Main::mismatch [%08zx] != [%08zx]\n", loop+i, srcBuffer[i]);
			  mismatch++;
		  } else {
			  match++;
		  }
	  }

	  loop+=numBytes;
  }

  PORTAL_PRINTF("Main::Summary: match=%lu mismatch:%lu (%lu) (%f percent)\n", 
		match, mismatch, match+mismatch, (float)mismatch/(float)(match+mismatch)*100.0);
  }
  */


  PORTAL_PRINTF( "Main: all done\n");
#ifdef __KERNEL__
  if (tid && !kthread_stop (tid)) {
    PORTAL_PRINTF ("kthread stops\n");
  }
  wait_for_completion(&worker_completion);
#endif
  PORTAL_PRINTF ("Main: ends\n");
  return 0;
}
