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
#include <ctype.h>
#include "dmaManager.h"
#include "HdmiDisplayRequest.h"
#include "HdmiDisplayIndication.h"
#include "HdmiGeneratorIndication.h"
#include "HdmiGeneratorRequest.h"
#include "i2chdmi.h"
#ifndef BOARD_bluesim
#include "edid.h"
#endif

#define FRAME_COUNT 2
#define MAX_PIXEL 256
#define INCREMENT_PIXEL 2

static HdmiGeneratorRequestProxy *hdmiGenerator;
static HdmiDisplayRequestProxy *device;
static int allocFrame[FRAME_COUNT];
static unsigned int ref_srcAlloc[FRAME_COUNT];
static int *dataptr[FRAME_COUNT];
static int frame_index;
static int nlines = 1080;
static int npixels = 1920;
static int fbsize;

void memdump(unsigned char *p, int len, char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                fprintf(stdout, "\n");
            fprintf(stdout, "%s: ",title);
        }
        fprintf(stdout, "%02x ", *p++);
        i++;
        len--;
    }
    fprintf(stdout, "\n");
}

static int corner[] = {0, -1, 0xf00f, 0x0fff};
static int corner_index;
static void fill_pixels(int offset)
{
printf("[%s:%d]\n", __FUNCTION__, __LINE__);
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
    portalCacheFlush(allocFrame[frame_index], dataptr[frame_index], fbsize, 1);
    hdmiGenerator->setTestPattern(0);
    device->startFrameBuffer(ref_srcAlloc[frame_index], fbsize);
    hdmiGenerator->waitForVsync(0);
    frame_index = 1 - frame_index;
}

static int synccount = 0;
static long long totalcount;
static int number;
class HdmiIndication : public HdmiGeneratorIndicationWrapper {
public:
    HdmiIndication(int id) : HdmiGeneratorIndicationWrapper(id) {}
  virtual void vsync ( uint64_t v, uint32_t w ) {
      static int base = 0;

printf("[%s:%d]\n", __FUNCTION__, __LINE__);
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
    virtual void transferFinished ( uint32_t v, uint32_t len ) {
      fprintf(stderr, "[%s:%d] v=%d len=%d\n", __FUNCTION__, __LINE__, v, len);
    }
    virtual void transferStats ( uint32_t count, uint32_t cycles, uint64_t sumcycles ) {
	fprintf(stderr, "[%s:%d] count=%d cycles=%d sumcycles=%"PRIx64" avgcycles=%f\n", __FUNCTION__, __LINE__, count, cycles, sumcycles, (double)sumcycles / count);
    }
};

int main(int argc, const char **argv)
{
    device = new HdmiDisplayRequestProxy(IfcNames_HdmiDisplayRequestS2H);
    DmaManager *dma = platformInit();
    HdmiIndication hdmiIndication(IfcNames_HdmiGeneratorIndicationH2S);
    DisplayIndication displayIndication(IfcNames_HdmiDisplayIndicationH2S);
    hdmiGenerator = new HdmiGeneratorRequestProxy(IfcNames_HdmiGeneratorRequestS2H);

    //device->setTraceTransfers(1);
    device->stopFrameBuffer();
    //setClockFrequency(0, 100000000, 0);

    int vblank, hblank, vsyncoff, hsyncoff, vsyncwidth, hsyncwidth;
#ifdef BOARD_bluesim
    nlines = 300;
    npixels = 500;
    vblank = 10;
    hblank = 10;
    vsyncoff = 2;
    hsyncoff = 2;
    vsyncwidth = 3;
    hsyncwidth = 3;

hblank--; // needed on zc702
#else
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
    long actualFrequency = 0;
    int status;
    status = setClockFrequency(0, 100000000, &actualFrequency);
    printf("[%s:%d] setClockFrequency 0 100000000 status=%d actualfreq=%ld\n", __FUNCTION__, __LINE__, status, actualFrequency);
    status = setClockFrequency(1, 160000000, &actualFrequency);
    printf("[%s:%d] setClockFrequency 1 160000000 status=%d actualfreq=%ld\n", __FUNCTION__, __LINE__, status, actualFrequency);
    status = setClockFrequency(3, 200000000, &actualFrequency);
    printf("[%s:%d] setClockFrequency 3 200000000 status=%d actualfreq=%ld\n", __FUNCTION__, __LINE__, status, actualFrequency);

    for (int i = 0; i < 4; i++) {
      int pixclk = (long)edid.timing[i].pixclk * 10000;
      if ((pixclk > 0) && (pixclk < 148000000)) {
	nlines = edid.timing[i].nlines;    // number of visible lines
	npixels = edid.timing[i].npixels;
	vblank = edid.timing[i].blines; // number of blanking lines
	hblank = edid.timing[i].bpixels;
	vsyncoff = edid.timing[i].vsyncoff; // number of lines in FrontPorch (within blanking)
	hsyncoff = edid.timing[i].hsyncoff;
	vsyncwidth = edid.timing[i].vsyncwidth; // width of Sync (within blanking)
	hsyncwidth = edid.timing[i].hsyncwidth;

	fprintf(stderr, "Using pixclk %d calc_pixclk %ld npixels %d nlines %d\n",
		pixclk,
		60l * (long)(hblank + npixels) * (long)(vblank + nlines),
		npixels, nlines);
	setClockFrequency(1, pixclk, 0);
//hblank--; // needed on zc702
	break;
      }
    }
#endif
    fprintf(stderr, "lines %d, pixels %d, vblank %d, hblank %d, vwidth %d, hwidth %d\n",
             nlines, npixels, vblank, hblank, vsyncwidth, hsyncwidth);
    hdmiGenerator->setDeLine(vsyncoff,          // End of FrontPorch
                            vsyncoff+vsyncwidth,// End of Sync
                            vblank-1,           // Start of Visible (start of BackPorch)
                            vblank + nlines, vblank + nlines / 2); // End
    hdmiGenerator->setDePixel(hsyncoff,
                            hsyncoff+hsyncwidth, hblank,
                            hblank + npixels, hblank + npixels / 2);
#if 0
    // horiz: frontPorch:87, sync: 44, backPorch:148, (blank=87+44+148=279) pixel:1920
    // vert: frontPorch:3, sync:5, backPorch:36, (blank = 36+5+8=49) lines:1080
    dePixelStartSync <- mkSyncReg(              87
    dePixelEndSync <- mkSyncReg(           44 + 87
    dePixelStartVisible <- mkSyncReg(148 + 44 + 87
    dePixelEnd <- mkSyncReg(  1920 + 148 + 44 + 87
    dePixelMid <- mkSyncReg((1920/2) + 148 + 44

    deLineStartSync <- mkSyncReg(              3
    deLineEndSync <- mkSyncReg(            5 + 3
    deLineStartVisible <- mkSyncReg(  36 + 5 + 3
    deLineEnd <- mkSyncReg(    1080 + 36 + 5 + 3
    deLineMid <- mkSyncReg((1080/2) + 41
#endif

    fbsize = nlines*npixels*sizeof(uint32_t);

    for (int i = 0; i < FRAME_COUNT; i++) {
        allocFrame[i] = portalAlloc(fbsize, 0);
        dataptr[i] = (int*)portalMmap(allocFrame[i], fbsize);
        memset(dataptr[i], i ? 0xff : 0, fbsize);
        fprintf(stderr, "hdmidisplay: calling dma->reference %d/%d\n", i, FRAME_COUNT);
        ref_srcAlloc[i] = dma->reference(allocFrame[i]);
    }

    //uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
    //fprintf(stderr, "first mem_stats=%"PRIx64"\n", beats);
    fprintf(stderr, "hdmidisplay: sleep 3\n");
    sleep(3);
    fprintf(stderr, "hdmidisplay: Starting frame buffer ref=%d...", ref_srcAlloc[0]);
    fill_pixels(0);
    fprintf(stderr, "hdmidisplay: run test\n");
    sleep(60);
    fprintf(stderr, "hdmidisplay: done\n");
}
