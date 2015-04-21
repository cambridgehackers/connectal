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

#include <pthread.h>
#include <queue>
#include <string.h>
#include <portal.h>
#include <sock_utils.h>
#include <GeneratedTypes.h>
#include <XsimMemSlaveRequest.h>
#include <XsimMemSlaveIndication.h>

class XsimMemSlaveIndication;
static XsimMemSlaveRequestProxy *memSlaveRequestProxy;
static XsimMemSlaveIndication *memSlaveIndication;
static int trace_xsim ;//= 1;

class XsimMemSlaveIndication : public XsimMemSlaveIndicationWrapper {
  struct idInfo {
    int number;
    int id;
    int valid;
  } ids[16];
  int portal_count;
  std::queue<uint32_t> readDataQueue;
  pthread_mutex_t readDataMutex;
  PortalPoller *poller;
public:
  std::queue<int> intrs;
  std::queue<uint32_t> srcbeats;

  XsimMemSlaveIndication(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0)
    : XsimMemSlaveIndicationWrapper(id, item, param, poller),
      portal_count(0), poller(poller)
  {
    memset(ids, 0, sizeof(ids));
    pthread_mutex_init(&readDataMutex, NULL);
  }
  virtual void readData ( const uint32_t data ) {
    fprintf(stderr, "[%s:%d] FIXME data=%d\n", __FUNCTION__, __LINE__, data);
    pthread_mutex_lock(&readDataMutex);
    readDataQueue.push(data);
    pthread_mutex_unlock(&readDataMutex);
  }
  virtual void directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint8_t last )
  {
    fprintf(stderr, "[%s:%d] fpga=%d id=%d last=%d\n", __FUNCTION__, __LINE__, fpgaNumber, fpgaId, last);
    struct idInfo info = { (int)fpgaNumber, (int)fpgaId, 1 };
    ids[fpgaNumber] = info;
    if (last)
      portal_count = fpgaNumber+1;
  }
  virtual void interrupt (const uint8_t intrNumber )	{
    fprintf(stderr, "[%s:%d] fpga=%d\n", __FUNCTION__, __LINE__, intrNumber);
    intrs.push(intrNumber);
  }

  void msgSource ( const uint32_t data ) {
    if (trace_xsim)
    fprintf(stderr, "[%s:%d] data=%d\n", __FUNCTION__, __LINE__, data);
    srcbeats.push(data);
  }

    int fpgaNumber(int fpgaId);
    int getReadData(uint32_t *data);
  void lockReadData() { pthread_mutex_lock(&readDataMutex); }
  void unlockReadData() { pthread_mutex_unlock(&readDataMutex); }
};

int XsimMemSlaveIndication::fpgaNumber(int fpgaId)
{
    for (int i = 0; ids[i].valid; i++)
	if (ids[i].id == fpgaId) {
	    return ids[i].number;
	}

    PORTAL_PRINTF( "Error: init_xsim: did not find fpga_number %d\n", fpgaId);
    PORTAL_PRINTF( "    Found fpga numbers:");
    for (int i = 0; ids[i].valid; i++)
	PORTAL_PRINTF( " %d", ids[i].id);
    PORTAL_PRINTF( "\n");

    return 0;
}

int XsimMemSlaveIndication::getReadData(uint32_t *data)
{
    return -1;
}

Portal *mcommon;
static void connect_to_xsim()
{
  if (memSlaveRequestProxy == 0) {
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, NULL, &socketfuncInit, &paramSocket);
    param.pint = &mcommon->pint;
    fprintf(stderr, "[%s:%d] adding fd %d\n", __FUNCTION__, __LINE__, mcommon->pint.client_fd[0]);

  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  memSlaveIndication = new XsimMemSlaveIndication(XsimIfcNames_XsimMemSlaveIndication, &muxfunc, &param);
  memSlaveRequestProxy = new XsimMemSlaveRequestProxy(XsimIfcNames_XsimMemSlaveRequest, &muxfunc, &param);
  fprintf(stderr, "[%s:%d] calling connect()\n", __FUNCTION__, __LINE__);
    memSlaveRequestProxy->connect();
  fprintf(stderr, "[%s:%d] called connect\n", __FUNCTION__, __LINE__);
  }
}

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
  //fprintf(stderr, "FIXME [%s:%d]\n", __FUNCTION__, __LINE__);
  connect_to_xsim();
  //pint->fpga_number = memSlaveIndication->fpgaNumber(pint->fpga_number);
  return 0;
}

uint32_t hdr = 0;
int numwords = 0;
static int recv_portal_xsim(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
    return -1;     // nothing to do here?
}

static unsigned int read_portal_xsim(PortalInternal *pint, volatile unsigned int **addr)
{
  size_t numwords = memSlaveIndication->srcbeats.size();
  uint32_t beat = memSlaveIndication->srcbeats.front();
  memSlaveIndication->srcbeats.pop();
  if (trace_xsim)
  fprintf(stderr, "[%s:%d] id=%d addr=%08lx data=%08x numwords=%ld\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr, beat, (long)numwords);
  return beat;
}

//FIXME, should go into pint->something
std::queue<uint32_t> msgbeats;
static void write_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  if (trace_xsim)
  fprintf(stderr, "[%s:%d] id=%d addr=%08lx data=%08x\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr, v);
  msgbeats.push(v);
}
static void send_portal_xsim(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
  // send a BlueNoc header
  uint32_t methodId = (hdr >> 16) & 0xFF;
  uint32_t numwords = (hdr & 0xFF) - 1;
  //FIXME, probably should have portal number in dst (bits 7:0)
  uint32_t bluenoc_hdr = (methodId << 24) | (numwords << 16);
  memSlaveRequestProxy->msgSink(bluenoc_hdr);

  // then the data beats
  while (msgbeats.size()) {
    memSlaveRequestProxy->msgSink(msgbeats.front());
    msgbeats.pop();
  }
}

void write_portal_fd_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "FIXME [%s:%d] fd %d\n", __FUNCTION__, __LINE__, v);
//FIXME
}

static void enableint_portal_xsim(struct PortalInternal *pint, int val)
{
}

int event_portal_xsim(struct PortalInternal *pint)
{
  memSlaveIndication->lockReadData();
  if (memSlaveIndication->srcbeats.size()) {
    uint32_t bluenoc_hdr = memSlaveIndication->srcbeats.front();
    //hmm, which portal?
    uint32_t numwords = (bluenoc_hdr >> 16) & 0xFF;
    uint32_t methodId = (bluenoc_hdr >> 24) & 0xFF;

    if (memSlaveIndication->srcbeats.size() >= numwords+1) {
      fprintf(stderr, "[%s:%d] pint=%p srcbeats=%d methodwords=%d methodId=%d hdr=%08x\n",
	      __FUNCTION__, __LINE__, pint, (int)memSlaveIndication->srcbeats.size(), numwords, methodId, bluenoc_hdr);
          memSlaveIndication->srcbeats.pop();
	  if (pint->handler)
	    pint->handler(pint, methodId, 0);
    }
  }
  memSlaveIndication->unlockReadData();
  return -1;
}

PortalItemFunctions xsimfunc = {
    init_xsim, read_portal_xsim, write_portal_xsim, write_portal_fd_xsim, mapchannel_hardware, mapchannel_hardware,
    send_portal_xsim, recv_portal_xsim, busy_portal_null, enableint_portal_xsim, event_portal_xsim, notfull_null};
