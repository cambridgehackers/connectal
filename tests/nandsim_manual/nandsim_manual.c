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
#ifndef SIMULATION
#define numWords 0x1240000/4 // make sure to allocate at least one entry of each size
#else
#define numWords 0x124000/4
#endif
static long alloc_sz = numWords*sizeof(unsigned int);
static DmaManagerPrivate priv;
size_t numBytes = 1 << 12;
size_t nandBytes = 1 << 24;

int NandCfgIndicationWrappereraseDone_cb(  struct PortalInternal *p, const uint32_t tag )
{
        PORTAL_PRINTF( "NandCfg_eraseDone(tag = %x)\n", tag);
        sem_post(&test_sem);
        return 0;
}
int NandCfgIndicationWrapperwriteDone_cb(  struct PortalInternal *p, const uint32_t tag )
{
        PORTAL_PRINTF( "NandCfg_writeDone(tag = %x)\n", tag);
        sem_post(&test_sem);
        return 0;
}
int NandCfgIndicationWrapperreadDone_cb(  struct PortalInternal *p, const uint32_t tag )
{
        PORTAL_PRINTF( "NandCfg_readDone(tag = %x)\n", tag);
        sem_post(&test_sem);
        return 0;
}
int NandCfgIndicationWrapperconfigureNandDone_cb(  struct PortalInternal *p )
{
        PORTAL_PRINTF( "NandCfg_NandDone\n");
        sem_post(&test_sem);
        return 0;
}
int DmaIndicationWrapperconfigResp_cb(  struct PortalInternal *p, const uint32_t pointer )
{
        PORTAL_PRINTF("DmaIndication_configResp(physAddr=%x)\n", pointer);
        sem_post(&priv.confSem);
        return 0;
}
int DmaIndicationWrapperaddrResponse_cb(  struct PortalInternal *p, const uint64_t physAddr )
{
        PORTAL_PRINTF("DmaIndication_addrResponse(physAddr=%"PRIx64")\n", physAddr);
        return 0;
}
int DmaIndicationWrapperreportStateDbg_cb(  struct PortalInternal *p, const DmaDbgRec rec )
{
        PORTAL_PRINTF("reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
        sem_post(&priv.dbgSem);
        return 0;
}
int DmaIndicationWrapperreportMemoryTraffic_cb(  struct PortalInternal *p, const uint64_t words )
{
        //PORTAL_PRINTF("reportMemoryTraffic: words=%"PRIx64"\n", words);
        priv.mtCnt = words;
        sem_post(&priv.mtSem);
        return 0;
}
int DmaIndicationWrapperdmaError_cb(  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra ) 
{
        PORTAL_PRINTF("DmaIndication::dmaError(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
        return 0;
}

void manual_event(void)
{
    int i;
    for(i = 0; i < MAX_INDARRAY; i++)
      event_hardware(&intarr[i]);
}

#ifdef __KERNEL__
DECLARE_COMPLETION(worker_completion);
#endif
static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while(1) {
#if defined(BSIM) && !defined(__KERNEL__)
        if(bsim_poll_interrupt())
#endif
        manual_event();
#ifdef __KERNEL__
        msleep(10);
        if(kthread_should_stop()) {
		    PORTAL_PRINTF("pthread_worker ends\n");
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
  unsigned int ref_nandAlloc;
  int rc = 0;
  unsigned int i;
  pthread_t tid = 0;

  init_portal_internal(&intarr[0], IfcNames_DmaIndicationH2S, DEFAULT_TILE, DmaIndication_handleMessage, NULL, NULL, NULL, DmaIndication_reqinfo);
  init_portal_internal(&intarr[1], IfcNames_NandCfgIndicationH2S, DEFAULT_TILE, NandCfgIndication_handleMessage, NULL, NULL, NULL, NandCfgIndication_reqinfo);
  init_portal_internal(&intarr[2], IfcNames_MMURequestS2H, DEFAULT_TILE, NULL, NULL, NULL, NULL, MMURequest_reqinfo);
  init_portal_internal(&intarr[3], IfcNames_NandCfgRequestS2H, DEFAULT_TILE, NULL, NULL, NULL, NULL, NandCfgRequest_reqinfo);

  sem_init(&test_sem, 0, 0);
  DmaManager_init(&priv, &intarr[2]);
  srcAlloc = portalAlloc(alloc_sz, 0);
  if(rc){
    PORTAL_PRINTF("portal alloc failed rc=%d\n", rc);
    return rc;
  }

  PORTAL_PRINTF( "Main: creating exec thread\n");
  if(pthread_create(&tid, NULL, pthread_worker, NULL)){
   PORTAL_PRINTF( "error creating exec thread\n");
   return -1;
  }
  srcBuffer = (unsigned int *)portalMmap(srcAlloc, alloc_sz);

  for(i = 0; i < numWords; i++) {
    srcBuffer[i] = i;
  }

  PORTAL_PRINTF("Test 1: check for operations\n");
  portalCacheFlush(srcAlloc, srcBuffer, alloc_sz, 1);
  PORTAL_PRINTF("Main: before DmaManager_reference(%u)\n", srcAlloc);
  ref_srcAlloc = DmaManager_reference(&priv, srcAlloc);


  nandAlloc = portalAlloc(nandBytes, 0);
  ref_nandAlloc = DmaManager_reference(&priv, nandAlloc);
  PORTAL_PRINTF("Main::configure NAND fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
  NandCfgRequest_configureNand(&intarr[3], ref_nandAlloc, nandBytes);
  sem_wait(&test_sem);


  PORTAL_PRINTF( "Main::starting write - begin %08lx\n", (long)numBytes);
  NandCfgRequest_startWrite(&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  PORTAL_PRINTF( "Main:: wait for semaphore\n");
  sem_wait(&test_sem);

  for(i = 0; i < numWords; i++) {
    srcBuffer[i] = 0;
  }
  PORTAL_PRINTF( "Main::starting read %08lx\n", (long)numBytes);
  NandCfgRequest_startRead(&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  sem_wait(&test_sem);
  PORTAL_PRINTF("read: %u %u %u %u\n", srcBuffer[0], srcBuffer[1], srcBuffer[2], srcBuffer[3]);

  PORTAL_PRINTF( "Main::starting erase %08lx\n", (long)numBytes);
  NandCfgRequest_startErase(&intarr[3], 0, numBytes);
  sem_wait(&test_sem);

  PORTAL_PRINTF( "Main::starting read %08lx\n", (long)numBytes);
  NandCfgRequest_startRead(&intarr[3], ref_srcAlloc, 0, 0, numBytes, 16);
  sem_wait(&test_sem);
  PORTAL_PRINTF("read: %u %u %u %u\n", srcBuffer[0], srcBuffer[1], srcBuffer[2], srcBuffer[3]);


  PORTAL_PRINTF("\n\nTest 2: check for match\n");
  {
  unsigned long loop = 0;
  unsigned long match = 0, mismatch = 0;
  while(loop < nandBytes) {
	  unsigned int i;
	  for(i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  srcBuffer[i] = loop+i;
	  }

	  /*PORTAL_PRINTF("Main::starting write ref=%d, len=%08lx (%lu)\n", ref_srcAlloc, (long)numBytes, loop);*/
  	  NandCfgRequest_startWrite(&intarr[3], ref_srcAlloc, 0, loop, numBytes, 16);
      sem_wait(&test_sem);

	  loop+=numBytes;
  }

  loop = 0;
  while(loop < nandBytes) {
	  unsigned int i;
	  /*PORTAL_PRINTF("Main::starting read %08lx (%lu)\n", (long)numBytes, loop);*/
	  NandCfgRequest_startRead(&intarr[3], ref_srcAlloc, 0, loop, numBytes, 16);
	  sem_wait(&test_sem);

	  for(i = 0; i < numBytes/sizeof(srcBuffer[0]); i++) {
		  if(srcBuffer[i] != loop+i) {
			  PORTAL_PRINTF("Main::mismatch [%08lx] != [%08lx]\n", (long)loop+i, (long)srcBuffer[i]);
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

  PORTAL_PRINTF( "Main: all done\n");
#ifdef __KERNEL__
  if(tid && !kthread_stop(tid)) {
    PORTAL_PRINTF("kthread stops\n");
  }
  wait_for_completion(&worker_completion);
#endif
  PORTAL_PRINTF("Main: ends\n");
  return 0;
}
