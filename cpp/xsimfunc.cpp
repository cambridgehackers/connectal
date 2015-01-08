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
public:
  std::queue<int> intrs;

  XsimMemSlaveIndication(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0)
    : XsimMemSlaveIndicationWrapper(id, item, param, poller),
      portal_count(0)
  {
    memset(ids, 0, sizeof(ids));
  }
  virtual void readData ( const uint32_t data ) {
    fprintf(stderr, "[%s:%d] FIXME data=%d\n", __FUNCTION__, __LINE__, data);
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

    int fpgaNumber(int fpgaId);
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


Portal *mcommon;
static void connect_to_xsim()
{
  if (memSlaveRequestProxy == 0) {
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    mcommon = new Portal(0, sizeof(uint32_t), portal_mux_handler, NULL, &socketfuncInit, &paramSocket, 0);
    param.pint = &mcommon->pint;
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
  fprintf(stderr, "FIXME [%s:%d]\n", __FUNCTION__, __LINE__);
  connect_to_xsim();
  //pint->fpga_number = memSlaveIndication->fpgaNumber(pint->fpga_number);
  return 0;
}

static volatile unsigned int *mapchannel_xsim(struct PortalInternal *pint, unsigned int v)
{
    return 0;
}

static unsigned int read_portal_xsim(PortalInternal *pint, volatile unsigned int **addr)
{
  fprintf(stderr, "FIXME [%s:%d] %08lx\n", __FUNCTION__, __LINE__, (long)*addr);
  memSlaveRequestProxy->read(pint->fpga_number, (uint32_t)(long)*addr);
  //FIXME: wait for response
  return 0;
}

static void write_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "[%s:%d] fd %08lx %08x\n", __FUNCTION__, __LINE__, (long)*addr, v);
  memSlaveRequestProxy->write(pint->fpga_number, (uint32_t)(long)*addr, v);
}
void write_portal_fd_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "FIXME [%s:%d] fd %d\n", __FUNCTION__, __LINE__, v);
//FIXME
}

int event_portal_xsim(struct PortalInternal *pint)
{
  fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
  return -1;
}

PortalItemFunctions xsimfunc = {
    init_xsim, read_portal_xsim, write_portal_xsim, write_portal_fd_xsim, mapchannel_hardware, mapchannel_hardware,
    send_portal_null, recv_portal_null, busy_portal_null, enableint_portal_null, event_portal_xsim, notfull_null};
