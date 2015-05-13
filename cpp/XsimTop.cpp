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
#include <stdlib.h>
#include <string>
#include <iostream>
#include <unistd.h>
#include <stdio.h>
#include <queue>
#include "svdpi.h"
#include <portal.h>
#include <sock_utils.h>
#include <XsimMsgRequest.h>
#include <XsimMsgIndication.h>

static int trace_xsimtop = 0;

class XsimMsgRequest : public XsimMsgRequestWrapper {
  struct idInfo {
    int number;
    int id;
    int valid;
  } ids[16];
  int portal_count;
public:
  struct readreq {
    uint32_t addr;
  };
  struct writereq {
    uint32_t addr;
    uint32_t data;
  };
  std::queue<readreq> readreqs;
  std::queue<uint32_t> readdata;
  std::queue<writereq> writereqs;
  std::queue<uint32_t> sinkbeats;

  int connected;

  XsimMsgRequest(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0) : XsimMsgRequestWrapper(id, item, param, poller), connected(0) { }
  ~XsimMsgRequest() {}
  virtual void connect () {
      connected = 1;
  }
  void enableint( const uint32_t fpgaId, const uint8_t val);
  //virtual void read ( const uint32_t fpgaId, const uint32_t addr );
  //virtual void write ( const uint32_t fpgaId, const uint32_t addr, const uint32_t data );
  virtual void msgSink ( const uint32_t data );

  void directory( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last );
  int fpgaNumber(int fpgaId);
  //int fpgaId(int fpgaNumber);

};

enum xsimtop_state {
  xt_reset, xt_read_directory, xt_active
};
void XsimMsgRequest::enableint( const uint32_t fpgaId, const uint8_t val)
{
  int number = fpgaNumber(fpgaId);
  uint32_t hwaddr = number << 16 | 4;
  writereq req = { hwaddr, val };
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x\n", __FUNCTION__, __LINE__, fpgaId, number, hwaddr);
  writereqs.push(req);
}
#if 0

void XsimMsgRequest::read ( const uint32_t fpgaId, const uint32_t addr )
{
  int number = fpgaNumber(fpgaId);
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x\n", __FUNCTION__, __LINE__, fpgaId, number, addr);
  uint32_t hwaddr = number << 16 | addr;
  readreq req = { hwaddr };
  readreqs.push(req);
}

void XsimMsgRequest::write ( const uint32_t fpgaId, const uint32_t addr, const uint32_t data )
{
  int number = fpgaNumber(fpgaId);
  uint32_t hwaddr = number << 16 | addr;
  writereq req = { hwaddr, data };
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x/%08x data=%08x\n", __FUNCTION__, __LINE__, fpgaId, fpgaNumber(fpgaId), addr, hwaddr, data);
  writereqs.push(req);
}
#endif
void XsimMsgRequest::msgSink ( const uint32_t data )
{
  if (trace_xsimtop)
      fprintf(stderr, "[%s:%d] data=%08x\n", __FUNCTION__, __LINE__, data);
  sinkbeats.push(data);
}

void XsimMsgRequest::directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last )
{
    fprintf(stderr, "[%s:%d] fpga=%d id=%d last=%d\n", __FUNCTION__, __LINE__, fpgaNumber, fpgaId, last);
    struct idInfo info = { (int)fpgaNumber, (int)fpgaId, 1 };
    ids[fpgaNumber] = info;
    if (last)
      portal_count = fpgaNumber+1;
}
int XsimMsgRequest::fpgaNumber(int fpgaId)
{
    for (int i = 0; ids[i].valid; i++)
        if (ids[i].id == fpgaId) {
            return ids[i].number;
        }

    PORTAL_PRINTF( "Error: %s: did not find fpga_number %d\n", __FUNCTION__, fpgaId);
    PORTAL_PRINTF( "    Found fpga numbers:");
    for (int i = 0; ids[i].valid; i++)
        PORTAL_PRINTF( " %d", ids[i].id);
    PORTAL_PRINTF( "\n");

    return 0;
}
#if 0
int XsimMsgRequest::fpgaId(int fpgaNumber)
{
  return ids[fpgaNumber].id;
}
#endif

static Portal                 *mcommon;
static XsimMsgIndicationProxy *xsimIndicationProxy;
static XsimMsgRequest         *xsimRequest;
static int dpiwdst_rdy, dpiwsrc_rdy;
static uint32_t dpiwsrc_beat;

extern "C" {
void dpi_init()
{
    //if (trace_xsimtop) 
        fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    dpiwdst_rdy = 0;
    dpiwsrc_rdy = 0;
    fprintf(stderr, "[%s:%d] using BluenocTop\n", __FILE__, __LINE__);
    mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, NULL, &transportSocketResp, NULL);
    PortalMuxParam param = {};
    param.pint = &mcommon->pint;
    xsimIndicationProxy = new XsimMsgIndicationProxy(XsimIfcNames_XsimMsgIndication, &transportMux, &param);
    xsimRequest = new XsimMsgRequest(XsimIfcNames_XsimMsgRequest, &transportMux, &param);

    fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    defaultPoller->stop();
    sleep(2);
    fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
}

void dpi_poll()
{
  void *rc = defaultPoller->pollFn(1);
  if ((long)rc > 0)
      defaultPoller->event();
  if (dpiwsrc_rdy || dpiwdst_rdy) {
      if (trace_xsimtop) fprintf(stderr, "============================================================\n");
      if (trace_xsimtop)
	  fprintf(stderr, "[%s:%d] rc=%ld src_rdy=%d src_beat=%08x dst_rdy=%d\n",
		  __FUNCTION__, __LINE__, (long)rc, dpiwsrc_rdy, dpiwsrc_beat, dpiwdst_rdy);
      // called on @(negedge CLK)
      if (dpiwdst_rdy) {
          // msgSink consumed one beat of data
          if (trace_xsimtop) fprintf(stderr, "[%s:%d] sinkbeats.pop()\n", __FUNCTION__, __LINE__);
          xsimRequest->sinkbeats.pop();
          dpiwdst_rdy = 0;
      }
      if (dpiwsrc_rdy) {
          // we got some data from the msgSource
          if (trace_xsimtop) fprintf(stderr, "[%s:%d] srcbeats.push() src_beat=%08x\n", __FUNCTION__, __LINE__, dpiwsrc_beat);
          xsimIndicationProxy->msgSource(dpiwsrc_beat);
          dpiwsrc_rdy = 0;
      }
      if (trace_xsimtop)
	  fprintf(stderr, "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
  }
}

void dpi_msgSink_beat(int dst_rdy, int *p_beat, int *p_src_rdy)
{
  if (dst_rdy && (xsimRequest->sinkbeats.size() > 0)) {
      uint32_t beat = xsimRequest->sinkbeats.front();
      if (trace_xsimtop)
          fprintf(stderr, "[%s:%d] sink message beat %08x\n", __FUNCTION__, __LINE__, beat);
      *p_beat = beat;
      *p_src_rdy = 1;
      dpiwdst_rdy = 1;
  } else {
      *p_beat = 0xbad0da7a;
      *p_src_rdy = 0;
  }
}

void dpi_msgSource_beat(int src_rdy, int beat, int *p_dst_rdy)
{
  if (src_rdy) {
      if (trace_xsimtop)
	  fprintf(stderr, "dpi_msgSource_beat() called beat=%08x src_rdy=%d\n", beat, src_rdy);
      dpiwsrc_beat = beat;
      dpiwsrc_rdy = 1;
  }
  *p_dst_rdy = src_rdy;
}
} // extern "C"
