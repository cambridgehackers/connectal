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
#include <XsimTop.h>
#include <XsimMsgRequest.h>
#include <XsimMsgIndication.h>
#include <pthread.h>

static int trace_xsimtop; // = 1;

class XsimMsgRequest : public XsimMsgRequestWrapper {
  pthread_mutex_t mutex;
  std::queue<uint32_t> sinkbeats[16];
public:
  XsimMsgRequest(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0):XsimMsgRequestWrapper(id, item, param, poller){
    pthread_mutex_init(&mutex, 0);
  }
  ~XsimMsgRequest() {
    pthread_mutex_destroy(&mutex);
  }
  void msgSink ( const uint32_t portal, const uint32_t data ) {
      if (trace_xsimtop)
          fprintf(stderr, "XsimRX: portal %d data=%08x\n", portal, data);
      pthread_mutex_lock(&mutex);
      sinkbeats[portal].push(data);
      pthread_mutex_unlock(&mutex);
  }
  void msgSinkFd ( const uint32_t portal, const uint32_t data ) {
      if (trace_xsimtop)
          fprintf(stderr, "XsimRXFD: portal %d data=%08x\n", portal, data);
      pthread_mutex_lock(&mutex);
      sinkbeats[portal].push(data);
      pthread_mutex_unlock(&mutex);
  }
  bool notEmpty(int portal) {
      pthread_mutex_lock(&mutex);
      bool notEmpty = sinkbeats[portal].size() > 0;
      pthread_mutex_unlock(&mutex);
      return notEmpty;
  }
  uint32_t get(int portal) {
      pthread_mutex_lock(&mutex);
      uint32_t data = sinkbeats[portal].front();
      sinkbeats[portal].pop();
      pthread_mutex_unlock(&mutex);
      return data;
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

long cycleCount;

extern "C" int dpi_cycle()
{
  cycleCount++;
  return finish;
}

double sc_time_stamp()
{
  return (double)cycleCount;
}

extern "C" void dpi_init()
{
    if (trace_xsimtop)
      fprintf(stderr, "%s:%d &xsim_handler=%p\n", __FUNCTION__, __LINE__, &xsim_handler);
#ifdef POLL_IN_DPI_POLL
    defaultPoller->stop();
#endif
    mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, &xsim_handler, &transportSocketResp, NULL, NULL);
    PortalMuxParam param = {};
    param.pint = &mcommon->pint;
    xsimIndicationProxy = new XsimMsgIndicationProxy(XsimIfcNames_XsimMsgIndication, &transportMux, &param);
    xsimRequest = new XsimMsgRequest(XsimIfcNames_XsimMsgRequest, &transportMux, &param);
    if (trace_xsimtop) fprintf(stderr, "%s: end\n", __FUNCTION__);
}

#ifdef POLL_IN_DPI_POLL
extern "C" void dpi_poll()
{
      void *rc = defaultPoller->pollFn(1);
      //fprintf(stderr, "%s:%d: rc=%ld\n", __FUNCTION__, __LINE__, (long)rc);
      if ((long)rc > 0)
	  defaultPoller->event();
}
#endif

extern "C" long long dpi_msgSink_beat(int portal)
{
  long long result = 0xbadad7a;
  //if (trace_xsimtop) fprintf(stderr, "%s: portal %d rdy %d\n", __FUNCTION__, portal, (int)xsimRequest->sinkbeats[portal].size());
  if (xsimRequest->notEmpty(portal)) {
      uint32_t beat = xsimRequest->get(portal);
      if (trace_xsimtop)
          fprintf(stderr, "%s: portal %d beat %08x\n", __FUNCTION__, portal, beat);
      result = (1ll << 32) | beat;
  }
  return result;
}

extern "C" void dpi_msgSource_beat(int portal, int beat)
{
    if (trace_xsimtop)
        fprintf(stderr, "dpi_msgSource_beat: portal %d beat=%08x\n", portal, beat);
    xsimIndicationProxy->msgSource(portal, beat);
}
