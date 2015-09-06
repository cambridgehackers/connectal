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
#if defined(BSIM) || defined(BOARD_xsim)
#define numBytes 0x1240
#else
#define numBytes 0x1240000 // make sure to allocate at least one entry of each size
#endif

static PortalInternal intarr[MAX_INDARRAY];
static sem_t test_sem;
static int burstLen = 16 * sizeof(uint32_t);
static DmaManagerPrivate priv;

int ReadTestIndicationWrapperreadDone_cb (  struct PortalInternal *p, const uint32_t mismatchCount )
{
    PORTAL_PRINTF( "ReadTest_readDone(mismatch = %x)\n", mismatchCount);
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
        intarr[i].item->event(&intarr[i]);
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

static MMUIndicationCb TestMMUIndication_cbTable = {
    portal_disconnect,
    MMUIndicationWrapperidResponse_cb,
    MMUIndicationWrapperconfigResp_cb,
    MMUIndicationWrappererror_cb,
};
static ReadTestIndicationCb TestReadTestIndication_cbTable = {
    portal_disconnect,
    ReadTestIndicationWrapperreadDone_cb,
};
int main(int argc, const char **argv)
{
    int srcAlloc;
    unsigned int *srcBuffer;
    unsigned int ref_srcAlloc;
    unsigned int i;
    pthread_t tid = 0;

    init_portal_internal(&intarr[0], IfcNames_MMUIndicationH2S,     0, MMUIndication_handleMessage, &TestMMUIndication_cbTable, NULL, NULL, MMUIndication_reqinfo);// fpga1
    init_portal_internal(&intarr[1], IfcNames_ReadTestIndicationH2S,DEFAULT_TILE, ReadTestIndication_handleMessage, &TestReadTestIndication_cbTable, NULL, NULL, ReadTestIndication_reqinfo); // fpga2
    init_portal_internal(&intarr[2], IfcNames_MMURequestS2H,     0, NULL, NULL, NULL, NULL, MMURequest_reqinfo); // fpga3
    init_portal_internal(&intarr[3], IfcNames_ReadTestRequestS2H,DEFAULT_TILE, NULL, NULL, NULL, NULL, ReadTestRequest_reqinfo);    // fpga4

    sem_init(&test_sem, 0, 0);
    DmaManager_init(&priv, &intarr[2]);
    srcAlloc = portalAlloc(numBytes, 0);
    if (srcAlloc < 0){
        PORTAL_PRINTF("portal alloc failed rc=%d\n", srcAlloc);
        return srcAlloc;
    }
    srcBuffer = (unsigned int *)portalMmap(srcAlloc, numBytes);
    for (i = 0; i < numBytes/sizeof(srcBuffer[0]); i++)
        srcBuffer[i] = i;
    portalCacheFlush(srcAlloc, srcBuffer, numBytes, 1);

    PORTAL_PRINTF( "Main: creating exec thread\n");
    if(pthread_create(&tid, NULL, pthread_worker, NULL)){
       PORTAL_PRINTF( "error creating exec thread\n");
       return -1;
    }

    PORTAL_PRINTF( "Test 1: check for match\n");
    PORTAL_PRINTF( "Main: before DmaManager_reference(%x)\n", srcAlloc);
    ref_srcAlloc = DmaManager_reference(&priv, srcAlloc);
    PORTAL_PRINTF( "Main: starting read %08x\n", numBytes);
    ReadTestRequest_startRead (&intarr[3], ref_srcAlloc, numBytes, burstLen, 1);
    PORTAL_PRINTF( "Main: waiting for semaphore1\n");
    sem_wait(&test_sem);

    PORTAL_PRINTF( "Test 2: check that mismatch is detected\n");
    srcBuffer[0] = -1;
    srcBuffer[numBytes/sizeof(srcBuffer[0])/2] = -1;
    srcBuffer[numBytes/sizeof(srcBuffer[0])-1] = -1;
    portalCacheFlush(srcAlloc, srcBuffer, numBytes, 1);

    ReadTestRequest_startRead (&intarr[3], ref_srcAlloc, numBytes, burstLen, 1);
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
