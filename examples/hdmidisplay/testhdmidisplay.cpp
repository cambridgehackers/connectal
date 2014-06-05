
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
#include <ctype.h>
#include "i2chdmi.h"
#include "edid.h"

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
    PortalPoller *poller = 0;
    PortalAlloc *portalAlloc = 0;;
    DmaConfigProxy *dma;
    DmaIndicationWrapper *dmaIndication;

    poller = new PortalPoller();
    device = new HdmiDisplayRequestProxy(IfcNames_HdmiDisplayRequest, poller);
    dma = new DmaConfigProxy(IfcNames_DmaConfig);
    dmaIndication = new DmaIndication(dma, IfcNames_DmaIndication);
    HdmiInternalIndicationWrapper *hdmiIndication = new HdmiIndication(IfcNames_HdmiInternalIndication);
    HdmiDisplayIndicationWrapper *displayIndication = new DisplayIndication(IfcNames_HdmiDisplayIndication);
    hdmiInternal = new HdmiInternalRequestProxy(IfcNames_HdmiInternalRequest);

    // read out monitor EDID from ADV7511
    struct edid edid;
    init_i2c_hdmi();
    int i2cfd = i2c_open();
    fprintf(stderr, "Monitor EDID:\n");
    for (int i = 0; i < 256; i++) {
      edid.raw[i] = i2c_read_reg(i2cfd, 0x3f, i);
      fprintf(stderr, " %02x", edid.raw[i]);
      if ((i % 16) == 15) {
	fprintf(stderr, " ");
	for (int j = i-15; j <= i; j++) {
	  unsigned char c = edid.raw[j];
	  fprintf(stderr, "%c", (isprint(c) && isascii(c)) ? c : '.');
	}
	fprintf(stderr, "\n");
      }
    }
    close(i2cfd);
    parseEdid(edid);

    pthread_t thread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&thread, &attr, thread_routine, 0);

    int status;
    status = poller->setClockFrequency(0, 100000000, 0);

    int nlines = 1080;
    int npixels = 1920;

    for (int i = 0; i < 4; i++) {
      int pixclk = (long)edid.timing[i].pixclk * 10000;
      if ((pixclk > 0) && (pixclk < 170000000)) {
	nlines = edid.timing[i].nlines;
	npixels = edid.timing[i].npixels;
	int lmin = edid.timing[i].blines;
	int pmin = edid.timing[i].bpixels;
	int vsyncwidth = edid.timing[i].vsyncwidth;
	int hsyncwidth = edid.timing[i].hsyncwidth;

	fprintf(stderr, "Using pixclk %d calc_pixclk %d npixels %d nlines %d\n",
		pixclk,
		60l * (long)(pmin + npixels) * (long)(lmin + nlines),
		npixels, nlines);
	status = poller->setClockFrequency(1, pixclk, 0);

	hdmiInternal->setNumberOfLines(lmin + nlines);
	hdmiInternal->setNumberOfPixels(pmin + npixels);
	hdmiInternal->setDeLineCountMinMax (lmin - vsyncwidth, lmin + nlines - vsyncwidth, (lmin + lmin + nlines) / 2 - vsyncwidth);
        hdmiInternal->setDePixelCountMinMax (pmin, pmin + npixels, pmin + npixels / 2);
	break;
      }
    }

    int fbsize = nlines*npixels*4;
    int err = dma->alloc(fbsize, &portalAlloc);
    int fd = portalAlloc->header.fd;
    int *ptr = (int*)mmap(0, fbsize, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);

    fprintf(stderr, "Filling frame buffer ptr=%p... ", ptr);
    for (int line = 0; line < nlines; line++) {
      for (int pixel = 0; pixel < npixels; pixel++) {
	int i = line*npixels + pixel;
	float red = (float)line / (float)nlines;
	//float blue = (float)pixel / (float)npixels;
	float blue = 0.0;
	int v = (int)(255*red) << 16 | (int)(255*blue);
	ptr[i] = v;
      }
    }
    fprintf(stderr, "done\n");
    dma->dCacheFlushInval(portalAlloc, ptr);
    fprintf(stderr, "calling dma->reference\n");
    unsigned int ref_srcAlloc = dma->reference(portalAlloc);
    fprintf(stderr, "mem_stats=%10u\n", dma->show_mem_stats(ChannelType_Read));
    sleep(10);
    if (0) hdmiInternal->waitForVsync(0);
    if (0) {
      fprintf(stderr, "Starting frame buffer ref=%d...", ref_srcAlloc);
      device->startFrameBuffer0(ref_srcAlloc);
      fprintf(stderr, "done\n");
    }
    while (1) {
      fprintf(stderr, "mem_stats=%10u\n", dma->show_mem_stats(ChannelType_Read));
      sleep(1);
    }
}
