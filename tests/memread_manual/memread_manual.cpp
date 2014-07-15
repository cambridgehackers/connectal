#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <monkit.h>
#include <sys/select.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "portal.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "DmaIndicationWrapper.h"
#include "dmaManager.h"

#define MAX_INDARRAY 4
sem_t test_sem;

int burstLen = 16;

int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
static PortalInternal *intarr[MAX_INDARRAY];
static DmaManager *portalMemory;
typedef int (*INDFUNC)(volatile unsigned int *map_base, unsigned int channel);

static INDFUNC indfn[MAX_INDARRAY];

#if 0 // for now
class DmaConfigProxysglistMSG : public PortalMessage
{
public:
    struct {
        uint32_t pointer:32;
        uint64_t addr:64;
        uint32_t len:32;

    } payload;
    size_t size(){return 16;}
    void marshall(unsigned int *buff) {
        int i = 0;
        buff[i++] = payload.len;
        buff[i++] = payload.addr;
        buff[i++] = (payload.addr>>32);
        buff[i++] = payload.pointer;

    }
    void demarshall(unsigned int *buff){ printf("[%s:%d]\n", __FUNCTION__, __LINE__); exit(-1); }
    void indicate(void *ind){ assert(false); }
};
void DmaConfigProxy::sglist ( const uint32_t pointer, const uint64_t addr, const uint32_t len )
{
    DmaConfigProxysglistMSG msg;
    msg.channel = CHAN_NUM_DmaConfigProxy_sglist;
    msg.payload.pointer = pointer;
    msg.payload.addr = addr;
    msg.payload.len = len;

    sendMessage(&msg);
};

class DmaConfigProxyregionMSG : public PortalMessage
{
public:
    struct {
        uint32_t pointer:32;
        uint64_t barr8:64;
        uint32_t off8:32;
        uint64_t barr4:64;
        uint32_t off4:32;
        uint64_t barr0:64;
        uint32_t off0:32;

    } payload;
    size_t size(){return 40;}
    void marshall(unsigned int *buff) {
        int i = 0;
        buff[i++] = payload.off0;
        buff[i++] = payload.barr0;
        buff[i++] = (payload.barr0>>32);
        buff[i++] = payload.off4;
        buff[i++] = payload.barr4;
        buff[i++] = (payload.barr4>>32);
        buff[i++] = payload.off8;
        buff[i++] = payload.barr8;
        buff[i++] = (payload.barr8>>32);
        buff[i++] = payload.pointer;

    }
    void demarshall(unsigned int *buff){ printf("[%s:%d]\n", __FUNCTION__, __LINE__); exit(-1); }
    void indicate(void *ind){ assert(false); }
};

void DmaConfigProxy::region ( const uint32_t pointer, const uint64_t barr8, const uint32_t off8, const uint64_t barr4, const uint32_t off4, const uint64_t barr0, const uint32_t off0 )
{
    DmaConfigProxyregionMSG msg;
    msg.channel = CHAN_NUM_DmaConfigProxy_region;
    msg.payload.pointer = pointer;
    msg.payload.barr8 = barr8;
    msg.payload.off8 = off8;
    msg.payload.barr4 = barr4;
    msg.payload.off4 = off4;
    msg.payload.barr0 = barr0;
    msg.payload.off0 = off0;

    sendMessage(&msg);
};

class DmaConfigProxyaddrRequestMSG : public PortalMessage
{
public:
    struct {
        uint32_t pointer:32;
        uint32_t offset:32;

    } payload;
    size_t size(){return 8;}
    void marshall(unsigned int *buff) {
        int i = 0;
        buff[i++] = payload.offset;
        buff[i++] = payload.pointer;

    }
    void demarshall(unsigned int *buff){ printf("[%s:%d]\n", __FUNCTION__, __LINE__); exit(-1); }
    void indicate(void *ind){ assert(false); }
};

void DmaConfigProxy::addrRequest ( const uint32_t pointer, const uint32_t offset )
{
    DmaConfigProxyaddrRequestMSG msg;
    msg.channel = CHAN_NUM_DmaConfigProxy_addrRequest;
    msg.payload.pointer = pointer;
    msg.payload.offset = offset;

    sendMessage(&msg);
};

class DmaConfigProxygetStateDbgMSG : public PortalMessage
{
public:
    struct {
        ChannelType rc;

    } payload;
    size_t size(){return 4;}
    void marshall(unsigned int *buff) {
        int i = 0;
        buff[i++] = payload.rc;

    }
    void demarshall(unsigned int *buff){ printf("[%s:%d]\n", __FUNCTION__, __LINE__); exit(-1); }
    void indicate(void *ind){ assert(false); }
};

void DmaConfigProxy::getStateDbg ( const ChannelType& rc )
{
    DmaConfigProxygetStateDbgMSG msg;
    msg.channel = CHAN_NUM_DmaConfigProxy_getStateDbg;
    msg.payload.rc = rc;

    sendMessage(&msg);
};

class DmaConfigProxygetMemoryTrafficMSG : public PortalMessage
{
public:
    struct {
        ChannelType rc;

    } payload;
    size_t size(){return 4;}
    void marshall(unsigned int *buff) {
        int i = 0;
        buff[i++] = payload.rc;

    }
    void demarshall(unsigned int *buff){ printf("[%s:%d]\n", __FUNCTION__, __LINE__); exit(-1); }
    void indicate(void *ind){ assert(false); }
};

void DmaConfigProxy::getMemoryTraffic ( const ChannelType& rc )
{
    DmaConfigProxygetMemoryTrafficMSG msg;
    msg.channel = CHAN_NUM_DmaConfigProxy_getMemoryTraffic;
    msg.payload.rc = rc;

    sendMessage(&msg);
};
#endif //0 (for now)

static int DmaIndicationWrapper_handleMessage(volatile unsigned int *map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    
    switch (channel) {

    case CHAN_NUM_DmaIndicationWrapper_configResp: 
    { 
    struct {
        uint32_t pointer:32;
        uint64_t msg:64;

    } payload;
        for (int i = (12/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_configResp)]);
        int i = 0;
        payload.msg = (uint64_t)(buf[i]);
        i++;
        payload.msg |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
    //fprintf(stderr, "configResp: %x, %"PRIx64"\n", payload.pointer, payload.msg);
    portalMemory->confResp(payload.pointer);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_addrResponse: 
    { 
    struct {
        uint64_t physAddr:64;

    } payload;
        for (int i = (8/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_addrResponse)]);
        int i = 0;
        payload.physAddr = (uint64_t)(buf[i]);
        i++;
        payload.physAddr |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
    fprintf(stderr, "DmaIndication::addrResponse(physAddr=%"PRIx64")\n", payload.physAddr);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_badPointer: 
    { 
    struct {
        uint32_t pointer:32;

    } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_badPointer)]);
        int i = 0;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
        fprintf(stderr, "DmaIndication::badPointer(pointer=%x)\n", payload.pointer);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_badAddrTrans: 
    { 
    struct {
        uint32_t pointer:32;
        uint64_t offset:64;
        uint64_t barrier:64;

    } payload;
        for (int i = (20/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_badAddrTrans)]);
        int i = 0;
        payload.barrier = (uint64_t)(buf[i]);
        i++;
        payload.barrier |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        payload.offset = (uint64_t)(buf[i]);
        i++;
        payload.offset |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
        fprintf(stderr, "DmaIndication::badAddrTrans(pointer=%x, offset=%"PRIx64" barrier=%"PRIx64"\n", payload.pointer, payload.offset, payload.barrier);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_badPageSize: 
    { 
    struct {
        uint32_t pointer:32;
        uint32_t sz:32;

    } payload;
        for (int i = (8/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_badPageSize)]);
        int i = 0;
        payload.sz = (uint32_t)(buf[i]);
        i++;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
        fprintf(stderr, "DmaIndication::badPageSize(pointer=%x, len=%x)\n", payload.pointer, payload.sz);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_badNumberEntries: 
    { 
    struct {
        uint32_t pointer:32;
        uint32_t sz:32;
        uint32_t idx:32;

    } payload;
        for (int i = (12/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_badNumberEntries)]);
        int i = 0;
        payload.idx = (uint32_t)(buf[i]);
        i++;
        payload.sz = (uint32_t)(buf[i]);
        i++;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
        fprintf(stderr, "DmaIndication::badNumberEntries(pointer=%x, len=%x, idx=%x)\n", payload.pointer, payload.sz, payload.idx);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_badAddr: 
    { 
    struct {
        uint32_t pointer:32;
        uint64_t offset:64;
        uint64_t physAddr:64;

    } payload;
        for (int i = (20/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_badAddr)]);
        int i = 0;
        payload.physAddr = (uint64_t)(buf[i]);
        i++;
        payload.physAddr |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        payload.offset = (uint64_t)(buf[i]);
        i++;
        payload.offset |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        payload.pointer = (uint32_t)(buf[i]);
        i++;
        fprintf(stderr, "DmaIndication::badAddr(pointer=%x offset=%"PRIx64" physAddr=%"PRIx64")\n", payload.pointer, payload.offset, payload.physAddr);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_reportStateDbg: 
    { 
    struct {
        DmaDbgRec rec;

    } payload;
        for (int i = (16/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_reportStateDbg)]);
        int i = 0;
        payload.rec.w = (uint32_t)(buf[i]);
        i++;
        payload.rec.z = (uint32_t)(buf[i]);
        i++;
        payload.rec.y = (uint32_t)(buf[i]);
        i++;
        payload.rec.x = (uint32_t)(buf[i]);
        i++;
        //fprintf(stderr, "reportStateDbg: {x:%08x y:%08x z:%08x w:%08x}\n", payload.rec.x,payload.rec.y,payload.rec.z,payload.rec.w);
        portalMemory->dbgResp(payload.rec);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_reportMemoryTraffic: 
    { 
    struct {
        uint64_t words:64;

    } payload;
        for (int i = (8/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_reportMemoryTraffic)]);
        int i = 0;
        payload.words = (uint64_t)(buf[i]);
        i++;
        payload.words |= (uint64_t)(((uint64_t)(buf[i])<<32));
        i++;
        //fprintf(stderr, "reportMemoryTraffic: words=%"PRIx64"\n", payload.words);
        portalMemory->mtResp(payload.words);
        break;
    }

    case CHAN_NUM_DmaIndicationWrapper_tagMismatch: 
    { 
    struct {
        ChannelType x;
        uint32_t a:32;
        uint32_t b:32;
    } payload;
        for (int i = (12/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaIndicationWrapper_tagMismatch)]);
        int i = 0;
        payload.b = (uint32_t)(buf[i]);
        i++;
        payload.a = (uint32_t)(buf[i]);
        i++;
        payload.x = (ChannelType)(((buf[i])&0x1ul));
        i++;
        fprintf(stderr, "tagMismatch: %s %d %d\n", payload.x==ChannelType_Read ? "Read" : "Write", payload.a, payload.b);
        break;
    }

    default:
        printf("DmaIndicationWrapper_handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}

static int MemreadIndicationWrapper_handleMessage(volatile unsigned int *map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    
    switch (channel) {
    case CHAN_NUM_MemreadIndicationWrapper_readDone: 
    { 
    struct {
        uint32_t mismatchCount:32;
    } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_MemreadIndicationWrapper_readDone)]);
        int i = 0;
        payload.mismatchCount = (uint32_t)(buf[i]);
        i++;
         printf( "Memread::readDone(mismatch = %x)\n", payload.mismatchCount);
         sem_post(&test_sem);
        break;
    }

    default:
        printf("MemreadIndicationWrapper_handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}
//zedboard/jni/DmaConfigProxy.cpp

static int DmaConfigProxyStatus_handleMessage(volatile unsigned int *map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    
    switch (channel) {

    case CHAN_NUM_DmaConfigProxyStatus_putFailed: 
    { 
        struct {
            uint32_t v:32;
        } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_DmaConfigProxyStatus_putFailed)]);
        const char* methodNameStrings[] = {"sglist", "region", "addrRequest", "getStateDbg", "getMemoryTraffic"};
        fprintf(stderr, "putFailed: %s\n", methodNameStrings[payload.v]);
        break;
    }

    default:
        printf("DmaConfigProxyStatus_handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}

static int MemreadRequestProxyStatus_handleMessage(volatile unsigned int *map_base, unsigned int channel)
{    
    unsigned int buf[1024];
    switch (channel) {

    case CHAN_NUM_MemreadRequestProxyStatus_putFailed: 
    { 
        struct {
            uint32_t v:32;
        } payload;
        for (int i = (4/4)-1; i >= 0; i--)
            buf[i] = READL(this, &map_base[PORTAL_IND_FIFO(CHAN_NUM_MemreadRequestProxyStatus_putFailed)]);
        const char* methodNameStrings[] = {"startRead"};
        fprintf(stderr, "putFailed: %s\n", methodNameStrings[payload.v]);
        break;
    }

    default:
        printf("MemreadRequestProxyStatus_handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}

static void manual_event(void)
{
    for (int i = 0; i < sizeof(intarr)/sizeof(intarr[i]); i++) {
      PortalInternal *instance = intarr[i];
      unsigned int queue_status;
      while ((queue_status= instance->map_base[IND_REG_QUEUE_STATUS])) {
        unsigned int int_src = instance->map_base[IND_REG_INTERRUPT_FLAG];
        unsigned int int_en  = instance->map_base[IND_REG_INTERRUPT_MASK];
        unsigned int ind_count  = instance->map_base[IND_REG_INTERRUPT_COUNT];
        fprintf(stderr, "(%d:%s) about to receive messages int=%08x en=%08x qs=%08x indfn %p\n", i, instance->name, int_src, int_en, queue_status, indfn[i]);
        if (indfn[i])
            indfn[i](instance->map_base, queue_status-1);
      }
    }
}

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

int main(int argc, const char **argv)
{
  intarr[0] = new PortalInternal(IfcNames_MemreadRequest);
  intarr[1] = new PortalInternal(IfcNames_MemreadIndication);
  intarr[2] = new PortalInternal(IfcNames_DmaConfig);
  intarr[3] = new PortalInternal(IfcNames_DmaIndication);
  indfn[0] = MemreadRequestProxyStatus_handleMessage;
  indfn[1] = MemreadIndicationWrapper_handleMessage;
  indfn[2] = DmaConfigProxyStatus_handleMessage;
  indfn[3] = DmaIndicationWrapper_handleMessage;

  DmaConfigProxy *dmap = new DmaConfigProxy(IfcNames_DmaConfig);
  portalMemory = new DmaManager(dmap);

  //sem_init(&test_sem, 0, 0);
  PortalAlloc *srcAlloc;
  portalMemory->alloc(alloc_sz, &srcAlloc);
  unsigned int *srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);

  pthread_t tid;
  printf( "Main::creating exec thread\n");
  if(pthread_create(&tid, NULL,  pthread_worker, NULL)){
   printf( "error creating exec thread\n");
   exit(1);
  }
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  portalMemory->dCacheFlushInval(srcAlloc, srcBuffer);
  unsigned int ref_srcAlloc = portalMemory->reference(srcAlloc);
  printf( "Main::starting read %08x\n", numWords);
  {
    unsigned int buf[128];
    int i = 0;
    buf[i++] = 1; /* iterCnt */
    buf[i++] = burstLen;
    buf[i++] = numWords;
    buf[i++] = ref_srcAlloc;
    //sendMessage(&msg);
    for (int i = 16/4-1; i >= 0; i--)
      intarr[0]->map_base[PORTAL_REQ_FIFO(CHAN_NUM_MemreadRequestProxy_startRead)] = buf[i];
  };
  sem_wait(&test_sem);
  return 0;
}
