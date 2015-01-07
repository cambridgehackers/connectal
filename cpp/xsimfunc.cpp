#include <portal.h>
#include <sock_utils.h>
#include <GeneratedTypes.h>
#include <XsimMemSlaveRequest.h>
#include <XsimMemSlaveIndication.h>

static XsimMemSlaveRequestProxy *memSlaveRequestProxy;

static void connect_to_xsim()
{
  if (memSlaveRequestProxy == 0) {
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    Portal *mcommon = new Portal(0, sizeof(uint32_t), portal_mux_handler, NULL, &socketfuncResp, &paramSocket, 0);
    param.pint = &mcommon->pint;
    memSlaveRequestProxy = new XsimMemSlaveRequestProxy(XsimIfcNames_XsimMemSlaveRequest, &muxfunc, &param);
  }
}

static int init_xsim(struct PortalInternal *pint, void *init_param)
{
  fprintf(stderr, "FIXME [%s:%d]\n", __FUNCTION__, __LINE__);
  connect_to_xsim();
  return 0;
}

static unsigned int read_portal_xsim(PortalInternal *pint, volatile unsigned int **addr)
{
  fprintf(stderr, "FIXME [%s:%d] %08lx\n", __FUNCTION__, __LINE__, (long)*addr);
  memSlaveRequestProxy->read((uint32_t)(long)*addr);
  //FIXME: wait for response
  return 0;
}

static void write_portal_xsim(PortalInternal *pint, volatile unsigned int **addr, unsigned int v)
{
  fprintf(stderr, "[%s:%d] fd %08lx %08x\n", __FUNCTION__, __LINE__, (long)*addr, v);
  memSlaveRequestProxy->write((uint32_t)(long)*addr, v);
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
    send_portal_null, recv_portal_null, busy_hardware, enableint_hardware, event_portal_xsim, notfull_hardware};
