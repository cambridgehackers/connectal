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

#include <string.h>
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#include <sys/mman.h>
#include <ctype.h>
#include "i2chdmi.h"
#include "edid.h"

#include "MemServerRequest.h"
#include "MMURequest.h"
#include "StdDmaIndication.h"
#include "HdmiDisplayRequest.h"
#include "HdmiDisplayIndication.h"
#include "HdmiInternalIndication.h"
#include "HdmiInternalRequest.h"

#define FRAME_COUNT 2
#define MAX_PIXEL 256
#define INCREMENT_PIXEL 2

static HdmiInternalRequestProxy *hdmiInternal;
static HdmiDisplayRequestProxy *device;
static DmaManager *dma;
static MMURequestProxy *dmap;
static int allocFrame[FRAME_COUNT];
static unsigned int ref_srcAlloc[FRAME_COUNT];
static int *dataptr[FRAME_COUNT];
static int frame_index;
static int nlines = 1080;
static int npixels = 1920;
static int fbsize = nlines*npixels*4;

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

static int corner[] = {0, -1, 0xf00f, 0x0fff};
static int corner_index;
static void fill_pixels(int offset)
{
    int *ptr = dataptr[frame_index];
    for (int line = 0; line < nlines; line++)
      for (int pixel = 0; pixel < npixels; pixel++) {
	int v = ((((MAX_PIXEL *  line) /  nlines)+offset) % MAX_PIXEL) << 16
	       | ((((MAX_PIXEL * pixel) / npixels)+offset) % MAX_PIXEL);
        if (!v)
            v = 1;
        if (line < 20 && pixel < 20)
            v = corner[(corner_index+0) % 4];
        if (line < 30 && pixel > npixels - 40)
            v = corner[(corner_index+1) % 4];
        if (line > nlines - 20 && pixel < 20)
            v = corner[(corner_index+2) % 4];
        if (line > nlines - 30 && pixel > npixels - 40)
            v = corner[(corner_index+3) % 4];
        if (line < 20 && pixel % 20 < 2)
            v = corner[(corner_index+0) % 4];
        if (line % 30 < 2 && pixel > npixels - 40)
            v = corner[(corner_index+1) % 4];
	ptr[line * npixels + pixel] = v;
      }
    corner_index = offset/16;
    portalDCacheFlushInval(allocFrame[frame_index], fbsize, dataptr[frame_index]);
    device->startFrameBuffer(ref_srcAlloc[frame_index], fbsize);
    hdmiInternal->setTestPattern(0);
    hdmiInternal->waitForVsync(0);
    frame_index = 1 - frame_index;
}

static int synccount = 0;
static long long totalcount;
static int number;
class HdmiIndication : public HdmiInternalIndicationWrapper {
public:
    HdmiIndication(int id) : HdmiInternalIndicationWrapper(id) {}
  virtual void vsync ( uint64_t v, uint32_t w ) {
      static int base = 0;

totalcount += v;
number += w;
      fill_pixels(base);
base += INCREMENT_PIXEL;
      if (synccount++ >= 20) {
          synccount = 0;
uint32_t zeros = v & 0xffffffff, pix = v >> 32;
          fprintf(stderr, "[%s] v %"PRIx64" pix=%x:%d. zero=%x:%d. w=%x:%d.\n", __FUNCTION__,v,pix,pix,zeros,zeros,w,w);
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
	fprintf(stderr, "[%s:%d] count=%d cycles=%d sumcycles=%"PRIx64" avgcycles=%f\n", __FUNCTION__, __LINE__, count, cycles, sumcycles, (double)sumcycles / count);
    }
};

int main(int argc, const char **argv)
{
    PortalPoller *poller = 0;

    poller = new PortalPoller();
    device = new HdmiDisplayRequestProxy(IfcNames_HdmiDisplayRequest);
  MemServerRequestProxy *hostMemServerRequest = new MemServerRequestProxy(IfcNames_HostMemServerRequest);
  dmap = new MMURequestProxy(IfcNames_HostMMURequest);
  DmaManager *dma = new DmaManager(dmap);
  MemServerIndication *hostMemServerIndication = new MemServerIndication(hostMemServerRequest, IfcNames_HostMemServerIndication);
  MMUIndication *hostMMUIndication = new MMUIndication(dma, IfcNames_HostMMUIndication);

    HdmiInternalIndicationWrapper *hdmiIndication = new HdmiIndication(IfcNames_HdmiInternalIndication);
    HdmiDisplayIndicationWrapper *displayIndication = new DisplayIndication(IfcNames_HdmiDisplayIndication);
    hdmiInternal = new HdmiInternalRequestProxy(IfcNames_HdmiInternalRequest);

#ifndef BOARD_bluesim
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
#endif

    device->stopFrameBuffer();

    pthread_t thread;
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_create(&thread, &attr, thread_routine, 0);

    int status;
    status = setClockFrequency(0, 100000000, 0);

#ifdef BOARD_bluesim
    nlines = 100;
    npixels = 200;
    int vblank = 10;
    int hblank = 10;
    int vsyncoff = 2;
    int hsyncoff = 2;
    int vsyncwidth = 3;
    int hsyncwidth = 3;

    fprintf(stderr, "lines %d, pixels %d, vblank %d, hblank %d, vwidth %d, hwidth %d\n",
             nlines, npixels, vblank, hblank, vsyncwidth, hsyncwidth);
hblank--; // needed on zc702
    hdmiInternal->setDeLine(vsyncoff,           // End of FrontPorch
                            vsyncoff+vsyncwidth,// End of Sync
                            vblank,             // Start of Visible (start of BackPorch)
                            vblank + nlines, vblank + nlines / 2); // End
        hdmiInternal->setDePixel(hsyncoff,
                            hsyncoff+hsyncwidth, hblank,
                            hblank + npixels, hblank + npixels / 2);
#else
    for (int i = 0; i < 4; i++) {
      int pixclk = (long)edid.timing[i].pixclk * 10000;
      if ((pixclk > 0) && (pixclk < 170000000)) {
	nlines = edid.timing[i].nlines;    // number of visible lines
	npixels = edid.timing[i].npixels;
	int vblank = edid.timing[i].blines; // number of blanking lines
	int hblank = edid.timing[i].bpixels;
	int vsyncoff = edid.timing[i].vsyncoff; // number of lines in FrontPorch (within blanking)
	int hsyncoff = edid.timing[i].hsyncoff;
	int vsyncwidth = edid.timing[i].vsyncwidth; // width of Sync (within blanking)
	int hsyncwidth = edid.timing[i].hsyncwidth;

	fprintf(stderr, "lines %d, pixels %d, vblank %d, hblank %d, vwidth %d, hwidth %d\n",
             nlines, npixels, vblank, hblank, vsyncwidth, hsyncwidth);
	fprintf(stderr, "Using pixclk %d calc_pixclk %ld npixels %d nlines %d\n",
		pixclk,
		60l * (long)(hblank + npixels) * (long)(vblank + nlines),
		npixels, nlines);
	status = setClockFrequency(1, pixclk, 0);
hblank--; // needed on zc702
	hdmiInternal->setDeLine(vsyncoff,           // End of FrontPorch
                                vsyncoff+vsyncwidth,// End of Sync
                                vblank,             // Start of Visible (start of BackPorch)
                                vblank + nlines, vblank + nlines / 2); // End
        hdmiInternal->setDePixel(hsyncoff,
                                hsyncoff+hsyncwidth, hblank,
                                hblank + npixels, hblank + npixels / 2);
	break;
      }
    }
#endif

    fbsize = nlines*npixels*4;

    for (int i = 0; i < FRAME_COUNT; i++) {
        allocFrame[i] = portalAlloc(fbsize);
        dataptr[i] = (int*)portalMmap(allocFrame[i], fbsize);
        memset(dataptr[i], i ? 0xff : 0, fbsize);
        fprintf(stderr, "calling dma->reference\n");
        ref_srcAlloc[i] = dma->reference(allocFrame[i]);
    }

    uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    fprintf(stderr, "first mem_stats=%"PRIx64"\n", beats);
    sleep(3);
    fprintf(stderr, "Starting frame buffer ref=%d...", ref_srcAlloc[0]);
    fill_pixels(0);
    fprintf(stderr, "done\n");
    int limit = 30;
    while (limit-- > 0) {
      uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
      fprintf(stderr, "mem_stats=%"PRIx64"\n", beats);
      sleep(1);
    }
}
