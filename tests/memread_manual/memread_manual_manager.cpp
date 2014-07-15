#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/select.h>
#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include "portal.h"
#include "DmaConfigProxy.h"
#include "GeneratedTypes.h" 
#include "DmaIndicationWrapper.h"

static int local_manager_handle;
static sem_t localmanager_confSem;
static sem_t localmanager_mtSem;
static sem_t localmanager_dbgSem;
static uint64_t localmanager_mtCnt;
static DmaDbgRec localmanager_dbgRec;
static int portalmem_fd;

// ugly hack (mdk)
typedef int SGListId;
static int trace_memory;// = 1;

#define MAX_INDARRAY 4
sem_t test_sem;

int burstLen = 16;

int numWords = 0x1240000/4; // make sure to allocate at least one entry of each size

size_t test_sz  = numWords*sizeof(unsigned int);
size_t alloc_sz = test_sz;
static PortalInternal *intarr[MAX_INDARRAY];
typedef int (*INDFUNC)(volatile unsigned int *map_base, unsigned int channel);

static INDFUNC indfn[MAX_INDARRAY];

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
        //fprintf(stderr, "configResp %d\n", payload.pointer);
        sem_post(&localmanager_confSem);
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
        fprintf(stderr, "DmaIndication_addrResponse(physAddr=%"PRIx64")\n", payload.physAddr);
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
        fprintf(stderr, "DmaIndication_badPointer(pointer=%x)\n", payload.pointer);
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
        fprintf(stderr, "DmaIndication_badAddrTrans(pointer=%x, offset=%"PRIx64" barrier=%"PRIx64"\n", payload.pointer, payload.offset, payload.barrier);
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
        fprintf(stderr, "DmaIndication_badPageSize(pointer=%x, len=%x)\n", payload.pointer, payload.sz);
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
        fprintf(stderr, "DmaIndication_badNumberEntries(pointer=%x, len=%x, idx=%x)\n", payload.pointer, payload.sz, payload.idx);
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
        fprintf(stderr, "DmaIndication_badAddr(pointer=%x offset=%"PRIx64" physAddr=%"PRIx64")\n", payload.pointer, payload.offset, payload.physAddr);
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
        localmanager_dbgRec = payload.rec;
        fprintf(stderr, "dbgResp: %08x %08x %08x %08x\n", localmanager_dbgRec.x, localmanager_dbgRec.y, localmanager_dbgRec.z, localmanager_dbgRec.w);
        sem_post(&localmanager_dbgSem);
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
        localmanager_mtCnt = payload.words;
        sem_post(&localmanager_mtSem);
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
         printf( "Memread_readDone(mismatch = %x)\n", payload.mismatchCount);
         sem_post(&test_sem);
        break;
    }

    default:
        printf("MemreadIndicationWrapper_handleMessage: unknown channel 0x%x\n", channel);
        return 0;
    }
    return 0;
}

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

static void local_manager_localDmaManager()
{
  const char* path = "/dev/portalmem";
  local_manager_handle = 1;
  portalmem_fd = open(path, O_RDWR);
  if (portalmem_fd < 0){
    fprintf(stderr, "Failed to open %s portalmem_fd=%d errno=%d\n", path, portalmem_fd, errno);
  }
  if (sem_init(&localmanager_confSem, 1, 0)){
    fprintf(stderr, "failed to init localmanager_confSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&localmanager_mtSem, 0, 0)){
    fprintf(stderr, "failed to init localmanager_mtSem errno=%d:%s\n", errno, strerror(errno));
  }
  if (sem_init(&localmanager_dbgSem, 0, 0)){
    fprintf(stderr, "failed to init localmanager_dbgSem errno=%d:%s\n", errno, strerror(errno));
  }
}

static int local_manager_reference(PortalAlloc* pa)
{
  const int PAGE_SHIFT0 = 12;
  const int PAGE_SHIFT4 = 16;
  const int PAGE_SHIFT8 = 20;
  uint64_t regions[3] = {0,0,0};
  uint64_t shifts[3] = {PAGE_SHIFT8, PAGE_SHIFT4, PAGE_SHIFT0};
  int id = local_manager_handle++;
  int ne = pa->header.numEntries;
  int size_accum = 0;
  // HW interprets zeros as end of sglist
  pa->entries[ne].dma_address = 0;
  pa->entries[ne].length = 0;
  pa->header.numEntries++;
  if (trace_memory)
    fprintf(stderr, "local_manager_reference id=%08x, numEntries:=%d len=%08lx)\n", id, ne, pa->header.size);
  for(int i = 0; i < pa->header.numEntries; i++){
    DmaEntry *e = &(pa->entries[i]);
    switch (e->length) {
    case (1<<PAGE_SHIFT0):
      regions[2]++;
      break;
    case (1<<PAGE_SHIFT4):
      regions[1]++;
      break;
    case (1<<PAGE_SHIFT8):
      regions[0]++;
      break;
    case (0):
      break;
    default:
      fprintf(stderr, "local_manager_unsupported sglist size %x\n", e->length);
    }
    dma_addr_t addr = e->dma_address;
    if (trace_memory)
      fprintf(stderr, "local_manager_sglist(id=%08x, i=%d dma_addr=%08lx, len=%08x)\n", id, i, (long)addr, e->length);
    {
    unsigned int buf[128];
    struct {
        uint32_t pointer:32;
        uint64_t addr:64;
        uint32_t len:32;
    } payload;
    payload.pointer = id;
    payload.addr = addr;
    payload.len = e->length;
    int i = 0;
    buf[i++] = payload.len;
    buf[i++] = payload.addr;
    buf[i++] = (payload.addr>>32);
    buf[i++] = payload.pointer;
    for (int i = 16/4-1; i >= 0; i--)
      intarr[2]->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_sglist)] = buf[i];
    };
    size_accum += e->length;
    // fprintf(stderr, "%s:%d sem_wait\n", __FILE__, __LINE__);
    sem_wait(&localmanager_confSem);
  }
  uint64_t border = 0;
  unsigned char entryCount = 0;
  struct {
    uint64_t border;
    unsigned char idxOffset;
  } borders[3];
  for(int i = 0; i < 3; i++){
    if (i == 0)
      borders[i].idxOffset = 0;
    else
      borders[i].idxOffset = entryCount - ((border >> shifts[i])&0xff);

    border += regions[i]*(1<<shifts[i]);
    borders[i].border = border;
    entryCount += regions[i];
  }
  if (trace_memory) {
    fprintf(stderr, "regions %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,regions[0], regions[1], regions[2]);
    fprintf(stderr, "borders %d (%"PRIx64" %"PRIx64" %"PRIx64")\n", id,borders[0].border, borders[1].border, borders[2].border);
  }
  {
    unsigned int buf[128];
    struct {
        uint32_t pointer:32;
        uint64_t barr8:64;
        uint32_t off8:32;
        uint64_t barr4:64;
        uint32_t off4:32;
        uint64_t barr0:64;
        uint32_t off0:32;
    } payload;
    payload.pointer = id;
    payload.barr8 = borders[0].border;
    payload.off8 = borders[0].idxOffset;
    payload.barr4 = borders[1].border;
    payload.off4 = borders[1].idxOffset;
    payload.barr0 = borders[2].border;
    payload.off0 = borders[2].idxOffset;
    int i = 0;
    buf[i++] = payload.off0;
    buf[i++] = payload.barr0;
    buf[i++] = (payload.barr0>>32);
    buf[i++] = payload.off4;
    buf[i++] = payload.barr4;
    buf[i++] = (payload.barr4>>32);
    buf[i++] = payload.off8;
    buf[i++] = payload.barr8;
    buf[i++] = (payload.barr8>>32);
    buf[i++] = payload.pointer;
    for (int i = 40/4-1; i >= 0; i--)
      intarr[2]->map_base[PORTAL_REQ_FIFO(CHAN_NUM_DmaConfigProxy_region)] = buf[i];
  };
  sem_wait(&localmanager_confSem);
  return id;
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

  local_manager_localDmaManager();

  //sem_init(&test_sem, 0, 0);
  PortalAlloc *srcAlloc;
  //local_manager_alloc(alloc_sz, &srcAlloc);
//static int local_manager_alloc(size_t size, PortalAlloc **ppa)
  srcAlloc = (PortalAlloc *)malloc(sizeof(PortalAlloc));
  memset(srcAlloc, 0, sizeof(PortalAlloc));
  srcAlloc->header.size = alloc_sz;
#if 1 ////////////// userspace version
  int rc = ioctl(portalmem_fd, PA_ALLOC, srcAlloc);
  if (!rc){
      float mb = (float)srcAlloc->header.size/(float)(1<<20);
      fprintf(stderr, "alloc size=%fMB rc=%d fd=%d numEntries=%d\n", mb, rc, srcAlloc->header.fd, srcAlloc->header.numEntries);
      srcAlloc = (PortalAlloc *)realloc(srcAlloc, sizeof(PortalAlloc)+((srcAlloc->header.numEntries+1)*sizeof(DmaEntry)));
      rc = ioctl(portalmem_fd, PA_DMA_ADDRESSES, srcAlloc);
  }
#endif /////////////////////
  if (rc){
    fprintf(stderr, "portal alloc failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
    return rc;
  }
  unsigned int *srcBuffer = (unsigned int *)mmap(0, alloc_sz, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED, srcAlloc->header.fd, 0);

  pthread_t tid;
  printf( "Main: creating exec thread\n");
  if(pthread_create(&tid, NULL,  pthread_worker, NULL)){
   printf( "error creating exec thread\n");
   exit(1);
  }
  for (int i = 0; i < numWords; i++)
    srcBuffer[i] = i;
  //local_manager_dCacheFlushInval(srcAlloc, srcBuffer);
//static int local_manager_dCacheFlushInval(PortalAlloc *srcAlloc, void *srcBuffer)
  {
#if defined(__arm__)
    int rc = ioctl(portalmem_fd, PA_DCACHE_FLUSH_INVAL, srcAlloc);
    if (rc){
      fprintf(stderr, "portal dcache flush failed rc=%d errno=%d:%s\n", rc, errno, strerror(errno));
      return rc;
    }
#elif defined(__i386__) || defined(__x86_64__)
    // not sure any of this is necessary (mdk)
    for(int i = 0; i < srcAlloc->header.size; i++){
      char foo = *(((volatile char *)srcBuffer)+i);
      asm volatile("clflush %0" :: "m" (foo));
    }
    asm volatile("mfence");
#else
#error("dCAcheFlush not defined for unspecified architecture")
#endif
  //fprintf(stderr, "dcache flush\n");
  }
  unsigned int ref_srcAlloc = local_manager_reference(srcAlloc);
  printf( "Main: starting read %08x\n", numWords);
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
