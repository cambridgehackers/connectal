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
#include <stdio.h>
#include <string.h>

struct edid {
  unsigned char raw[256];
  struct edid_timing {
  } simple_timing[8];
  struct edid_detailed_timing {
    unsigned short pixclk;
    unsigned short npixels;
    unsigned short bpixels;
    unsigned short nlines;
    unsigned short blines;
    unsigned short hsyncoff;
    unsigned short hsyncwidth;
    unsigned short vsyncoff;
    unsigned short vsyncwidth;
    unsigned short widthmm;
    unsigned short heightmm;
    unsigned char  hborderpxls;
    unsigned char  vborderpxls;
    unsigned char features;
  } timing[4];
};

static void parseEdid(struct edid &edid)
{
  for (int i = 0; i < 4; i++) {
    unsigned char *rec = &edid.raw[54+18*i];
    memset(&edid.timing[i], 0, sizeof(edid.timing[i]));

    if (*(unsigned short*)&rec[0] == 0) {
      unsigned char descriptor_type = rec[3];
      switch (descriptor_type) {
      case 0xFF: // monitor serial number
	fprintf(stderr, "monitor serial number %13.13s\n", &rec[5]);
	break;
      case 0xFE: // text
	fprintf(stderr, "monitor text %.13s\n", &rec[5]);
	break;
      case 0xFC: // monitor name
	fprintf(stderr, "monitor name %.13s\n", &rec[5]);
	break;
      case 0xFA: // more standard timing identifiers
	fprintf(stderr, "standard timing identifiers\n");
	break;

      }
      continue;
    }
    edid.timing[i].pixclk = *(unsigned short*)&rec[0];
    edid.timing[i].npixels = rec[2] | ((rec[4] >> 4) << 8);
    edid.timing[i].bpixels = rec[3] | ((rec[4] & 0xF) << 8);
    edid.timing[i].nlines = rec[5] | ((rec[7] >> 4) << 8);
    edid.timing[i].blines = rec[6] | ((rec[7] & 0xF) << 8);
    edid.timing[i].hsyncoff = rec[8] | ((rec[11] >> 6) << 8);
    edid.timing[i].hsyncwidth = rec[9] | (((rec[11] & 0x30) >> 4) << 8);
    edid.timing[i].vsyncoff = (rec[10] >>  4) | (((rec[11] & 0x0c) >> 2) << 4);
    edid.timing[i].vsyncwidth = (rec[10] & 0xf) | (((rec[11] & 0x03) >> 0) << 4);
    edid.timing[i].widthmm   = rec[12] | ((rec[14] >>  4) << 8);
    edid.timing[i].heightmm  = rec[13] | ((rec[14] & 0xf) << 8);
    edid.timing[i].hborderpxls = rec[15];
    edid.timing[i].vborderpxls = rec[16];
    edid.timing[i].features = rec[17];
  }
  for (int i = 0; i < 4; i++)
    if (edid.timing[i].pixclk) {
      fprintf(stderr, "pixclk=%d w=%dmm h=%dmm features=%x\n",
	      edid.timing[i].pixclk, edid.timing[i].widthmm, edid.timing[i].heightmm, edid.timing[i].features);
      fprintf(stderr, "    npixels=%d bpixels=%d hsyncoff=%d hsyncwidth=%d hbpxls=%d\n",
	      edid.timing[i].npixels, edid.timing[i].bpixels,
	      edid.timing[i].hsyncoff, edid.timing[i].hsyncwidth, edid.timing[i].hborderpxls);
      fprintf(stderr, "    nlines=%d blines=%d vsyncoff=%d vsyncwidth=%d vbpxls=%d\n",
	      edid.timing[i].nlines, edid.timing[i].blines,
	      edid.timing[i].vsyncoff, edid.timing[i].vsyncwidth, edid.timing[i].vborderpxls);
    }
  fprintf(stderr, "\n");
}
