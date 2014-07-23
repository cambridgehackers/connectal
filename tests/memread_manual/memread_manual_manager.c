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
#define PRIx64 "llx"
typedef int sem_t;
#define sem_post(A)
#define sem_wait(A)
#else
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include <sys/mman.h>
#include <pthread.h>
#include <fcntl.h>
#include <sys/select.h>
#endif

#include "portal.h"
#include "dmaManager.h"
#include "GeneratedTypes.h" 

static int trace_memory;// = 1;

#define MAX_INDARRAY 4
typedef int (*INDFUNC)(PortalInternal *p, unsigned int channel);
static PortalInternal *intarr[MAX_INDARRAY];
static INDFUNC indfn[MAX_INDARRAY];

static sem_t test_sem;
static int burstLen = 16;
#ifdef MMAP_HW
#define numWords 0x1240000/4 // make sure to allocate at least one entry of each size
#else
#define numWords 0x124000/4
#endif
static long test_sz  = numWords*sizeof(unsigned int);
static long alloc_sz = numWords*sizeof(unsigned int);
static DmaManagerPrivate priv;

void MemreadIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount )
{
         PORTAL_PRINTF( "Memread_readDone(mismatch = %x)\n", mismatchCount);
         sem_post(&test_sem);
}
void DmaIndicationWrapperconfigResp_cb (  struct PortalInternal *p, const uint32_t pointer)
{
        //PORTAL_PRINTF("configResp %x\n", pointer);
        sem_post(&priv.confSem);
}
void DmaIndicationWrapperaddrResponse_cb (  struct PortalInternal *p, const uint64_t physAddr )
{
        PORTAL_PRINTF("DmaIndication_addrResponse(physAddr=%"PRIx64")\n", physAddr);
}
void DmaIndicationWrapperreportStateDbg_cb (  struct PortalInternal *p, const DmaDbgRec rec )
{
        //PORTAL_PRINTF("reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", rec.x,rec.y,rec.z,rec.w);
        DmaDbgRec dbgRec = rec;
        PORTAL_PRINTF("dbgResp: %08x %08x %08x %08x\n", dbgRec.x, dbgRec.y, dbgRec.z, dbgRec.w);
        sem_post(&priv.dbgSem);
}
void DmaIndicationWrapperreportMemoryTraffic_cb (  struct PortalInternal *p, const uint64_t words )
{
        //PORTAL_PRINTF("reportMemoryTraffic: words=%"PRIx64"\n", words);
        priv.mtCnt = words;
        sem_post(&priv.mtSem);
}
void DmaIndicationWrapperdmaError_cb (  struct PortalInternal *p, const uint32_t code, const uint32_t pointer, const uint64_t offset, const uint64_t extra ) {
        PORTAL_PRINTF("DmaIndication::dmaError(code=%x, pointer=%x, offset=%"PRIx64" extra=%"PRIx64"\n", code, pointer, offset, extra);
}

static void manual_event(void)
{
    int i;
    for (i = 0; i < MAX_INDARRAY; i++) {
      PortalInternal *instance = intarr[i];
      volatile unsigned int *map_base = instance->map_base;
      unsigned int queue_status;
      while ((queue_status= READL(instance, &map_base[IND_REG_QUEUE_STATUS]))) {
        unsigned int int_src = READL(instance, &map_base[IND_REG_INTERRUPT_FLAG]);
        unsigned int int_en  = READL(instance, &map_base[IND_REG_INTERRUPT_MASK]);
        unsigned int ind_count  = READL(instance, &map_base[IND_REG_INTERRUPT_COUNT]);
        PORTAL_PRINTF("(%d:fpga%d) about to receive messages int=%08x en=%08x qs=%08x cnt=%x\n", i, instance->fpga_number, int_src, int_en, queue_status, ind_count);
        if (indfn[i])
            indfn[i](instance, queue_status-1);
      }
    }
}

#ifndef __KERNEL__ ///////////////////////// userspace version
static void *pthread_worker(void *p)
{
    void *rc = NULL;
    while (1) {
        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 10000;
        manual_event();
        select(0, NULL, NULL, NULL, &timeout);
    }
    return rc;
}
#endif

int main(int argc, const char **argv)
{
  PortalInternal intarrtemp[MAX_INDARRAY];
  PortalAlloc *srcAlloc;
  unsigned int *srcBuffer;
  unsigned int ref_srcAlloc;
  int rc, i;

  intarr[0] = init_portal_internal(&intarrtemp[0], IfcNames_DmaIndication);     // fpga1
  intarr[1] = init_portal_internal(&intarrtemp[1], IfcNames_MemreadIndication); // fpga2
  intarr[2] = init_portal_internal(&intarrtemp[2], IfcNames_DmaConfig);         // fpga3
  intarr[3] = init_portal_internal(&intarrtemp[3], IfcNames_MemreadRequest);    // fpga4
  indfn[0] = DmaIndicationWrapper_handleMessage;
  indfn[1] = MemreadIndicationWrapper_handleMessage;
  indfn[2] = DmaConfigProxy_handleMessage;
  indfn[3] = MemreadRequestProxy_handleMessage;

  DmaManager_init(&priv, intarr[2]);
  rc = DmaManager_alloc(&priv, alloc_sz, &srcAlloc);
  if (rc){
    PORTAL_PRINTF("portal alloc failed rc=%d\n", rc);
    return rc;
  }

#ifndef __KERNEL__ ///////////////////////// userspace version
  {
  pthread_t tid;
  PORTAL_PRINTF( "Main: creating exec thread\n");
  if(pthread_create(&tid, NULL,  pthread_worker, NULL)){
   PORTAL_PRINTF( "error creating exec thread\n");
   exit(1);
  }
  }
  srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);
#else   /// kernel version
//??????
  srcBuffer = NULL;
#endif ////////////////////////////////

  for (i = 0; i < numWords; i++)
    srcBuffer[i] = i;

#ifndef __KERNEL__   //////////////// userspace code for flushing dcache for srcAlloc
  DmaManager_dCacheFlushInval(&priv, srcAlloc, srcBuffer);
#else   /// kernel version
//??????
#endif /////////////////////
  ref_srcAlloc = DmaManager_reference(&priv, srcAlloc);
  PORTAL_PRINTF( "Main: starting read %08x\n", numWords);
  MemreadRequestProxy_startRead (intarr[3], ref_srcAlloc, numWords, burstLen, 1);
  sem_wait(&test_sem);
  return 0;
}
