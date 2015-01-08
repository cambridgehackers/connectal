#include <stdlib.h>
#include <string>
#include <iostream>
#include <unistd.h>
#include <stdio.h>
#include <queue>

#include "xsi_loader.h"

#include <portal.h>
#include <sock_utils.h>
#include <GeneratedTypes.h>
#include <XsimMemSlaveRequest.h>
#include <XsimMemSlaveIndication.h>

XsimMemSlaveIndicationProxy *memSlaveIndicationProxy;
class XsimMemSlaveRequest;
XsimMemSlaveRequest *memSlaveRequest;

//deleteme
std::string getcurrentdir()
{
    return get_current_dir_name();
}

class xsiport {
  Xsi::Loader &xsiInstance;
  int port;
  //int direction;
  const char *name;
  int width;
  s_xsi_vlog_logicval value;
public:
  xsiport(Xsi::Loader &loader, const char *name, int bits = 1)
    : xsiInstance(loader), port(-1), name(name), width(bits)
  {
    value = {1, 1};
    port = xsiInstance.get_port_number(name);
    //width = xsiInstance.get_int_port(port, xsiHDLValueSize);
    std::cout << "Port name=" << name << " number=" << port << std::endl;
  }
  int read();
  void write(int val);

};

int xsiport::read()
{
    xsiInstance.get_value(port, &value);
    int mask = (width == 32) ? -1 : ((1 << width) - 1);
    if (value.bVal != 0) {
      char charval[] = { '0', '1', 'Z', 'X' };
      int encoding = (value.aVal & mask) | ((value.bVal & mask) << 1);
      fprintf(stderr, "port %2d.%16s value=%08x.%08x mask=%08x width=%2d %c\n", port, name, value.aVal, value.bVal, mask, width, charval[encoding]);
    }
    return value.aVal & mask;
}
void xsiport::write(int aVal)
{
    value.aVal = aVal;
    value.bVal = 0;
    xsiInstance.put_value(port, &value);
}

class XsimMemSlaveRequest : public XsimMemSlaveRequestWrapper {
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

  int connected;

  XsimMemSlaveRequest(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : XsimMemSlaveRequestWrapper(id, item, param, poller), connected(0) { }
  ~XsimMemSlaveRequest() {}
  virtual void connect () {
      connected = 1;
  }
  virtual void read ( const uint32_t fpgaId, const uint32_t addr );
  virtual void write ( const uint32_t fpgaId, const uint32_t addr, const uint32_t data );

  void directory( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last );
  int fpgaNumber(int fpgaId);
  int fpgaId(int fpgaNumber);

};

void XsimMemSlaveRequest::read ( const uint32_t fpgaId, const uint32_t addr )
{
  int number = fpgaNumber(fpgaId);
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x\n", __FUNCTION__, __LINE__, fpgaId, number, addr);
  uint32_t hwaddr = number << 16 | addr;
  readreq req = { hwaddr };
  readreqs.push(req);
}

void XsimMemSlaveRequest::write ( const uint32_t fpgaId, const uint32_t addr, const uint32_t data )
{
  int number = fpgaNumber(fpgaId);
  uint32_t hwaddr = number << 16 | addr;
  writereq req = { hwaddr, data };
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x/%08x data=%08x\n", __FUNCTION__, __LINE__, fpgaId, fpgaNumber(fpgaId), addr, hwaddr, data);
  writereqs.push(req);
}

void XsimMemSlaveRequest::directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last )
{
    fprintf(stderr, "[%s:%d] fpga=%d id=%d last=%d\n", __FUNCTION__, __LINE__, fpgaNumber, fpgaId, last);
    struct idInfo info = { fpgaNumber, fpgaId, 1 };
    ids[fpgaNumber] = info;
    if (last)
      portal_count = fpgaNumber+1;
}

int XsimMemSlaveRequest::fpgaNumber(int fpgaId)
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
int XsimMemSlaveRequest::fpgaId(int fpgaNumber)
{
  return ids[fpgaNumber].id;
}

enum xsimtop_state {
  xt_reset, xt_read_directory, xt_active
};

int main(int argc, char **argv)
{
    std::string cwd = getcurrentdir();
    std::string simengine_libname = "librdi_simulator_kernel.so";
    std::string design_libname = getcurrentdir() + "/xsim.dir/mkXsimTop/xsimk.so";

    std::cout << "Design DLL     : " << design_libname << std::endl;
    std::cout << "Sim Engine DLL : " << simengine_libname << std::endl;

    // See xsi.h header for more details on how Verilog values are stored as aVal/bVal pairs
    Xsi::Loader xsiInstance(design_libname, simengine_libname);
    s_xsi_setup_info info;
    info.logFileName = "/tmp/xsim.log";
    xsiInstance.open(&info);
    
    xsimtop_state state = xt_reset;

    xsiport rst_n(xsiInstance, "RST_N");
    xsiport clk(xsiInstance, "CLK");
    xsiport en_interrupt(xsiInstance, "EN_interrupt");
    xsiport rdy_interrupt(xsiInstance, "RDY_interrupt");
    xsiport interrupt(xsiInstance, "interrupt", 4);

    xsiport en_directoryEntry(xsiInstance, "EN_directoryEntry");
    xsiport rdy_directoryEntry(xsiInstance, "RDY_directoryEntry");
    xsiport directoryEntry(xsiInstance, "directoryEntry", 32);
    xsiport read_addr(xsiInstance, "read_addr", 32);
    xsiport en_read(xsiInstance, "EN_read");
    xsiport rdy_read(xsiInstance, "RDY_read");
    xsiport readData(xsiInstance, "readData", 32);
    xsiport en_readData(xsiInstance, "EN_readData");
    xsiport rdy_readData(xsiInstance, "RDY_readData");
    xsiport write_addr(xsiInstance, "write_addr");
    xsiport write_data(xsiInstance, "write_data");
    xsiport en_write(xsiInstance, "EN_write");
    xsiport rdy_write(xsiInstance, "RDY_write");
    xsiport clk_singleClock(xsiInstance, "CLK_singleClock");

    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    Portal *mcommon = new Portal(0, sizeof(uint32_t), portal_mux_handler, NULL, &socketfuncResp, &paramSocket, 0);
    param.pint = &mcommon->pint;
    XsimMemSlaveIndicationProxy *memSlaveIndicationProxy = new XsimMemSlaveIndicationProxy(XsimIfcNames_XsimMemSlaveIndication, &muxfunc, &param);
    XsimMemSlaveRequest *memSlaveRequest = new XsimMemSlaveRequest(XsimIfcNames_XsimMemSlaveRequest, &muxfunc, &param);

    portalExec_init();

    // start low clock
    clk.write(0);
    rst_n.write(0);

    read_addr.write(0);
    en_read.write(0);
    en_readData.write(0);
    en_write.write(0);

    xsiInstance.run(10);

    int portal_number = 0;
    int waiting_for_read = 0;
    int read_dir_val = 0;
    int portal_ids[16];
    int portal_count = 0;
    int offset = 0x00;

    for (int i = 0; 1; i++)
    {

	void *rc = portalExec_poll(1);
	if ((long)rc >= 0) {
	    portalExec_event();
	}

	if (i > 2) {
	    rst_n.write(1);
	    state = xt_active;
	}

	if (rdy_directoryEntry.read() && !portal_count) {
	  fprintf(stderr, "directoryEntry %08x\n", directoryEntry.read());
	  unsigned int val = directoryEntry.read();
	  bool last = (val & 0x80000000) != 0;
	  uint32_t id = val & 0x7fffffff;
	  memSlaveRequest->directory(portal_number, id, last);

	  portal_ids[portal_number++] = id;
	  if (val & 0x80000000) {
	      portal_count = portal_number;
	      portal_number = 0;
	      fprintf(stderr, "portal_count=%d\n", portal_count);
	  }

	  en_directoryEntry.write(1);
	} else {
	  en_directoryEntry.write(0);
	}
	  
	if (memSlaveRequest->connected && (portal_number < portal_count)) {
	    memSlaveIndicationProxy->directory(portal_number, portal_ids[portal_number], portal_number == (portal_count-1));
	    portal_number++;
	}

	if (state == xt_active) {
	  if (memSlaveRequest->readreqs.size() && rdy_read.read()) {
	    XsimMemSlaveRequest::readreq readreq = memSlaveRequest->readreqs.front();
	    memSlaveRequest->readreqs.pop();
	    en_read.write(1);
	    fprintf(stderr, "Reading from addr %08x\n", readreq.addr);
	    read_addr.write(readreq.addr);
	  } else {
	    en_read.write(0);
	  }
	  if (rdy_readData.read()) {
	    en_readData.write(1);
	    uint32_t data = readData.read();
	    fprintf(stderr, "Reading data %08x\n", data);
	    memSlaveIndicationProxy->readData(data);
	  } else {
	    en_readData.write(0);
	  }
	  if (memSlaveRequest->writereqs.size() && rdy_write.read()) {
	    XsimMemSlaveRequest::writereq writereq = memSlaveRequest->writereqs.front();
	    memSlaveRequest->writereqs.pop();
	    en_write.write(1);
	    fprintf(stderr, "Writing to addr %08x data %08x\n", writereq.addr, writereq.data);
	    write_addr.write(writereq.addr);
	    write_data.write(writereq.data);
	  } else {
	    en_write.write(0);
	  }
	}
	if (memSlaveRequest->connected && rdy_interrupt.read()) {
	  en_interrupt.write(1);
	  int intr = interrupt.read();
	  int id = memSlaveRequest->fpgaId(intr);
	  fprintf(stderr, "Got interrupt number %d id %d\n", intr, id);
	  //memSlaveIndicationProxy->interrupt(id);
	} else {
	  en_interrupt.write(0);
	}

	clk.write(1);
	xsiInstance.run(10);

	if (0) {
	    // clock is divided by two
	    clk.write(0);
	    xsiInstance.run(10);

	    clk.write(1);
	    xsiInstance.run(10);
	}

	clk.write(0);
	xsiInstance.run(10);
    }
    sleep(10);
    portalExec_end();
}
