
#include "DmaConfigProxy.h"
#include "DmaIndicationWrapper.h"
#include "StdDmaIndication.h"
#include "GeneratedTypes.h"
#include "HdmiDisplayRequestProxy.h"
#include "HdmiDisplayIndicationWrapper.h"
#include "HdmiInternalIndicationWrapper.h"
#include "HdmiInternalRequestProxy.h"
#include "portal.h"
#include <stdio.h>
#include <sys/mman.h>
#include "i2chdmi.h"

HdmiInternalRequestProxy *hdmiInternal = 0;
HdmiDisplayRequestProxy *device = 0;
PortalAlloc srcAlloc;
PortalAlloc dstAlloc;
int srcFd = -1;
int dstFd = -1;
char *srcBuffer = 0;
char *dstBuffer = 0;

void dump(const char *prefix, char *buf, size_t len)
{
    fprintf(stderr, "%s: ", prefix);
    for (int i = 0; i < 16; i++)
	fprintf(stderr, "%02x", (unsigned char)buf[i]);
    fprintf(stderr, "\n");
}

static void *thread_routine(void *data)
{
    fprintf(stderr, "Calling portalExec\n");
    portalExec(0);
    fprintf(stderr, "portalExec returned ???\n");
    return data;
}

class HdmiIndication : public HdmiInternalIndicationWrapper {
public:
    HdmiIndication(int id) : HdmiInternalIndicationWrapper(id) {}
    virtual void vsync ( uint64_t v ) {
      fprintf(stderr, "[%s:%d] v=%d\n", __FUNCTION__, __LINE__, (uint32_t) v);
      //hdmiInternal->waitForVsync(0);
    }
};
class DisplayIndication : public HdmiDisplayIndicationWrapper {
public:
    DisplayIndication(int id) : HdmiDisplayIndicationWrapper(id) {}
    virtual void transferStarted ( uint32_t v ) {
      fprintf(stderr, "[%s:%d] v=%d\n", __FUNCTION__, __LINE__, v);
    }
    virtual void transferFinished ( uint32_t v ) {
      fprintf(stderr, "[%s:%d] v=%d\n", __FUNCTION__, __LINE__, v);
    }
    virtual void transferStats ( uint32_t count, uint32_t cycles, uint64_t sumcycles ) {
	fprintf(stderr, "[%s:%d] count=%d cycles=%d sumcycles=%lld avgcycles=%f\n", __FUNCTION__, __LINE__, count, cycles, sumcycles, (double)sumcycles / count);
    }
};

int main(int argc, const char **argv)
{
    PortalPoller *poller = new PortalPoller();
    PortalAlloc *portalAlloc = 0;;
    DmaConfigProxy *dma;
    DmaIndicationWrapper *dmaIndication;

    device = new HdmiDisplayRequestProxy(IfcNames_HdmiDisplayRequest, poller);
    dma = new DmaConfigProxy(IfcNames_DmaConfig);
    dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);
    HdmiInternalIndicationWrapper *hdmiIndication = new HdmiIndication(IfcNames_HdmiInternalIndication);
    HdmiDisplayIndicationWrapper *displayIndication = new DisplayIndication(IfcNames_HdmiDisplayIndication);
    hdmiInternal = new HdmiInternalRequestProxy(IfcNames_HdmiInternalRequest);

    pthread_t thread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&thread, &attr, thread_routine, 0);

    int status;
    status = poller->setClockFrequency(0,  80000000, 0);
    status = poller->setClockFrequency(1, 160000000, 0);
    init_i2c_hdmi();

    int lines = 1080;
    int pixels = 1920;
    int fbsize = lines*pixels*4;
    int err = dma->alloc(fbsize, &portalAlloc);
    int fd = portalAlloc->header.fd;
    int *ptr = (int*)mmap(0, fbsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);

    fprintf(stderr, "Filling frame buffer ptr=%p... ", ptr);
    for (int line = 0; line < lines; line++) {
      for (int pixel = 0; pixel < pixels; pixel++) {
	int i = line*pixels + pixel;
	float red = (float)line / (float)lines;
	//float blue = (float)pixel / (float)pixels;
	float blue = 0.0;
	int v = (int)(255*red) << 16 | (int)(255*blue);
	ptr[i] = v;
      }
    }
    fprintf(stderr, "done\n");
    dma->dCacheFlushInval(portalAlloc, ptr);
    fprintf(stderr, "calling dma->reference\n");
    unsigned int ref_srcAlloc = dma->reference(portalAlloc);
    fprintf(stderr, "mem_stats=%d\n", dma->show_mem_stats(ChannelType_Read));
    sleep(10);
    if (0) hdmiInternal->waitForVsync(0);
    fprintf(stderr, "Starting frame buffer ref=%d...", ref_srcAlloc);
    device->startFrameBuffer0(ref_srcAlloc);
    fprintf(stderr, "done\n");
    while (1) {
      fprintf(stderr, "mem_stats=%d\n", dma->show_mem_stats(ChannelType_Read));
      sleep(1);
    }
}
