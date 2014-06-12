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

#define FRAME_COUNT 2

static HdmiInternalRequestProxy *hdmiInternal;
static HdmiDisplayRequestProxy *device;
static DmaConfigProxy *dma;
static PortalAlloc *portalAlloc[FRAME_COUNT];
static unsigned int ref_srcAlloc[FRAME_COUNT];
static int *dataptr[FRAME_COUNT];
static int frame_index;
static int nlines = 1080;
static int npixels = 1920;

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

static void fill_pixels(int offset)
{
    int *ptr = dataptr[frame_index];
    for (int line = 0; line < nlines; line++)
      for (int pixel = 0; pixel < npixels; pixel++)
	*ptr++ = ((((128 *  line) /  nlines)+offset) % 128) << 16
	       | ((((128 * pixel) / npixels)+offset) % 128);
    dma->dCacheFlushInval(portalAlloc[frame_index], dataptr[frame_index]);
    device->startFrameBuffer(ref_srcAlloc[frame_index], nlines, npixels, nlines*npixels);
    hdmiInternal->waitForVsync(0);
    frame_index = 1 - frame_index;
}

static int synccount = 0;
class HdmiIndication : public HdmiInternalIndicationWrapper {
public:
    HdmiIndication(int id) : HdmiInternalIndicationWrapper(id) {}
  virtual void vsync ( uint64_t v, uint32_t w ) {
      static int base = 0;

      fill_pixels(2 * base++);
      if (synccount++ >= 30) {
          synccount = 0;
          fprintf(stderr, "[%s:%d] v=%d w=%d\n", __FUNCTION__, __LINE__, (uint32_t) v, w);
      }
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
    int i2cfd = open("/dev/i2c-0", O_RDWR);
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

    device->stopFrameBuffer();

    pthread_t thread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&thread, &attr, thread_routine, 0);

    int status;
    status = poller->setClockFrequency(0, 100000000, 0);

    for (int i = 0; i < 4; i++) {
      int pixclk = (long)edid.timing[i].pixclk * 10000;
      if ((pixclk > 0) && (pixclk < 170000000)) {
	nlines = edid.timing[i].nlines;
	npixels = edid.timing[i].npixels;
	int lmin = edid.timing[i].blines;
	int pmin = edid.timing[i].bpixels;
	int vsyncwidth = edid.timing[i].vsyncwidth;
	int hsyncwidth = edid.timing[i].hsyncwidth;

	fprintf(stderr, "lines %d, pixels %d, lmin %d, pmin %d, vwidth %d, hwidth %d\n", nlines, npixels, lmin, pmin, vsyncwidth, hsyncwidth);
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

    for (int i = 0; i < FRAME_COUNT; i++) {
        int err = dma->alloc(fbsize, &portalAlloc[i]);
        dataptr[i] = (int*)mmap(0, fbsize, PROT_READ|PROT_WRITE, MAP_SHARED, portalAlloc[i]->header.fd, 0);
        fprintf(stderr, "calling dma->reference\n");
        ref_srcAlloc[i] = dma->reference(portalAlloc[i]);
    }

    fprintf(stderr, "first mem_stats=%10u\n", dma->show_mem_stats(ChannelType_Read));
    sleep(3);
    fprintf(stderr, "Starting frame buffer ref=%d...", ref_srcAlloc[0]);
    fill_pixels(0);
    //device->startFrameBuffer(ref_srcAlloc[frame_index], nlines, npixels, nlines*npixels);
    fprintf(stderr, "done\n");
    while (1) {
      fprintf(stderr, "mem_stats=%10u\n", dma->show_mem_stats(ChannelType_Read));
      sleep(1);
    }
}
