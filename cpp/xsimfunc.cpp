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
  virtual void directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last )
  {
    fprintf(stderr, "[%s:%d] fpga=%d id=%d last=%d\n", __FUNCTION__, __LINE__, fpgaNumber, fpgaId, last);
    struct idInfo info = { fpgaNumber, fpgaId, 1 };
    ids[fpgaNumber] = info;
    if (last)
      portal_count = fpgaNumber+1;
  }
  virtual void interrupt (const uint32_t intrNumber )	{
    fprintf(stderr, "[%s:%d] fpga=%d\n", __FUNCTION__, __LINE__, intrNumber);
    intrs.push(intrNumber);
  }

  void msgSource ( const uint32_t data ) {
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
#ifndef BluenocTop
  if (poller) poller->portalExec_event();
  pthread_mutex_lock(&readDataMutex);
  int hasData = readDataQueue.size();
  if (hasData && data) {
    *data = readDataQueue.size();
    readDataQueue.pop();
  }
  pthread_mutex_unlock(&readDataMutex);
  return hasData;
#else
#endif
}


Portal *mcommon;
static void connect_to_xsim()
{
  if (memSlaveRequestProxy == 0) {
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    mcommon = new Portal(0, sizeof(uint32_t), portal_mux_handler, NULL, &socketfuncInit, &paramSocket, defaultPoller);
    param.pint = &mcommon->pint;
    fprintf(stderr, "[%s:%d] adding fd %d\n", __FUNCTION__, __LINE__, mcommon->pint.client_fd[0]);

  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  memSlaveIndication = new XsimMemSlaveIndication(XsimIfcNames_XsimMemSlaveIndication, &muxfunc, &param, defaultPoller);
  memSlaveRequestProxy = new XsimMemSlaveRequestProxy(XsimIfcNames_XsimMemSlaveRequest, &muxfunc, &param);
  fprintf(stderr, "[%s:%d] calling connect()\n", __FUNCTION__, __LINE__);
    memSlaveRequestProxy->connect();
  fprintf(stderr, "[%s:%d] called connect\n", __FUNCTION__, __LINE__);
  }
}

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
  fprintf(stderr, "FIXME [%s:%d]\n", __FUNCTION__, __LINE__);
  connect_to_xsim();
  //pint->fpga_number = memSlaveIndication->fpgaNumber(pint->fpga_number);
  return 0;
}

static volatile unsigned int *mapchannel_xsim(struct PortalInternal *pint, unsigned int v)
{
    return 0;
}

uint32_t hdr = 0;
int numwords = 0;
static int recv_portal_xsim(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd)
{
#ifdef BluenocTop
  // nothing to do here?
#endif
}

static unsigned int read_portal_xsim(PortalInternal *pint, volatile unsigned int **addr)
{
#ifndef BluenocTop
  fprintf(stderr, "FIXME [%s:%d] id=%d addr=%08lx\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr);
  memSlaveRequestProxy->read(pint->fpga_number, (uint32_t)(long)*addr);
  while (1) {
    uint32_t data;
    int hasData = memSlaveIndication->getReadData(&data);
    if (hasData) {
      fprintf(stderr, "[%s:%d] id=%d addr=%08lx got data %08lx\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr, data);
      return data;
    }
  }
  return 0xDeadBeef;
#else
  size_t numwords = memSlaveIndication->srcbeats.size();
  uint32_t beat = memSlaveIndication->srcbeats.front();
  memSlaveIndication->srcbeats.pop();
  fprintf(stderr, "FIXME [%s:%d] id=%d addr=%08lx data=%08x numwords=%d\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr, beat, numwords);
  return beat;
#endif

}

//FIXME, should go into pint->something
std::queue<uint32_t> msgbeats;
static void write_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "[%s:%d] id=%d addr=%08lx data=%08x\n", __FUNCTION__, __LINE__, pint->fpga_number, (long)*addr, v);
#ifndef BluenocTop
  memSlaveRequestProxy->write(pint->fpga_number, (uint32_t)(long)*addr, v);
#else
  msgbeats.push(v);
#endif
}
static void send_portal_xsim(struct PortalInternal *pint, volatile unsigned int *data, unsigned int hdr, int sendFd)
{
#ifdef BluenocTop
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
#endif
}

void write_portal_fd_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "FIXME [%s:%d] fd %d\n", __FUNCTION__, __LINE__, v);
//FIXME
}

static void enableint_portal_xsim(struct PortalInternal *pint, int val)
{
#ifndef BluenocTop
  fprintf(stderr, "[%s:%d] id %d val %d\n", __FUNCTION__, __LINE__, pint->fpga_number, val);
  memSlaveRequestProxy->enableint(pint->fpga_number, val);
#endif
}

int event_portal_xsim(struct PortalInternal *pint)
{
#ifndef BluenocTop
  fprintf(stderr, "[%s:%d] num_intrs=%d\n", __FUNCTION__, __LINE__, memSlaveIndication->intrs.size());
  if (memSlaveIndication->intrs.size()) {
    volatile unsigned int *map_base = 0;
    volatile unsigned int *statp = &map_base[PORTAL_CTRL_REG_IND_QUEUE_STATUS];
    for (int fpgaId = memSlaveIndication->intrs.front(); memSlaveIndication->intrs.size(); memSlaveIndication->intrs.pop()) {
      int status = read_portal_xsim(pint, &statp);
    }
  }
#else
  memSlaveIndication->lockReadData();
  if (memSlaveIndication->srcbeats.size()) {
    uint32_t bluenoc_hdr = memSlaveIndication->srcbeats.front();
    //hmm, which portal?
    uint32_t numwords = (bluenoc_hdr >> 16) & 0xFF;
    uint32_t methodId = (bluenoc_hdr >> 24) & 0xFF;

    fprintf(stderr, "[%s:%d] pint=%p srcbeats=%d methodwords=%d methodId=%d hdr=%08x\n",
	    __FUNCTION__, __LINE__, pint, memSlaveIndication->srcbeats.size(), numwords, methodId, bluenoc_hdr);
    if (memSlaveIndication->srcbeats.size() > numwords+1) {
          memSlaveIndication->srcbeats.pop();
	  if (pint->handler)
	    pint->handler(pint, methodId, 0);
    }
  }
  memSlaveIndication->unlockReadData();
#endif

  return -1;
}

PortalItemFunctions xsimfunc = {
    init_xsim, read_portal_xsim, write_portal_xsim, write_portal_fd_xsim, mapchannel_hardware, mapchannel_hardware,
    send_portal_xsim, recv_portal_xsim, busy_portal_null, enableint_portal_xsim, event_portal_xsim, notfull_null};
