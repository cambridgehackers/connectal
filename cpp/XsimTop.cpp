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
#include <queue>
#include <XsimMsgRequest.h>
#include <XsimMsgIndication.h>

static int trace_xsimtop = 0;

class XsimMsgRequest : public XsimMsgRequestWrapper {
public:
  std::queue<uint32_t> sinkbeats[16];

  XsimMsgRequest(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0):XsimMsgRequestWrapper(id, item, param, poller){}
  ~XsimMsgRequest() {}
  void msgSink ( const uint32_t portal, const uint32_t data ) {
      if (trace_xsimtop)
          fprintf(stderr, "XsimRX: portal %d data=%08x\n", portal, data);
      sinkbeats[portal].push(data);
  }
  void msgSinkFd ( const uint32_t portal, const uint32_t data ) {
      //if (trace_xsimtop)
          fprintf(stderr, "XsimRXFD: portal %d data=%08x\n", portal, data);
      sinkbeats[portal].push(data);
  }
};

static Portal                 *mcommon;
static XsimMsgIndicationProxy *xsimIndicationProxy;
static XsimMsgRequest         *xsimRequest;

static int finish = 0;
static int xsim_disconnect(struct PortalInternal *pint)
{
  fprintf(stderr, "%s:%d pint=%p calling $finish\n", __FUNCTION__, __LINE__, pint);
  finish = 1;
  return 0;
}

static PortalHandlerTemplate xsim_handler = {
  xsim_disconnect
};

extern "C" int dpi_finish()
{
  return finish;
}

extern "C" void dpi_init()
{
    if (trace_xsimtop)
      fprintf(stderr, "%s:%d &xsim_handler=%p\n", __FUNCTION__, __LINE__, &xsim_handler);
    defaultPoller->stop();
    mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, &xsim_handler, &transportSocketResp, NULL, NULL);
    PortalMuxParam param = {};
    param.pint = &mcommon->pint;
    xsimIndicationProxy = new XsimMsgIndicationProxy(XsimIfcNames_XsimMsgIndication, &transportMux, &param);
    xsimRequest = new XsimMsgRequest(XsimIfcNames_XsimMsgRequest, &transportMux, &param);
    fprintf(stderr, "%s: end\n", __FUNCTION__);
}

extern "C" void dpi_msgSink_beat(int portal, int *p_beat, int *p_src_rdy)
{
  if (xsimRequest->sinkbeats[portal].size() > 0) {
      uint32_t beat = xsimRequest->sinkbeats[portal].front();
      if (trace_xsimtop)
          fprintf(stderr, "%s: portal %d beat %08x\n", __FUNCTION__, portal, beat);
      *p_beat = beat;
      *p_src_rdy = 1;
      xsimRequest->sinkbeats[portal].pop();
  } else {
      *p_beat = 0xbad0da7a;
      *p_src_rdy = 0;
      void *rc = defaultPoller->pollFn(1);
      if ((long)rc > 0)
          defaultPoller->event();
  }
}

extern "C" void dpi_msgSource_beat(int portal, int beat)
{
    if (trace_xsimtop)
        fprintf(stderr, "dpi_msgSource_beat: portal %d beat=%08x\n", portal, beat);
    xsimIndicationProxy->msgSource(portal, beat);
}
