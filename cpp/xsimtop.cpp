#include <stdlib.h>
#include <string>
#include <iostream>
#include <unistd.h>
#include <stdio.h>

#include "xsi_loader.h"

#include <portal.h>
#include <sock_utils.h>
#include <GeneratedTypes.h>
#include <XsimMemSlaveRequest.h>
#include <XsimMemSlaveIndication.h>

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
    : xsiInstance(loader), port(-1), name(name), width(bits), value({1, 1}) {
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
    int mask = ((1 << width) - 1);
    if (value.bVal != 0) {
      char charval[] = { '0', '1', 'Z', 'X' };
      int encoding = (value.aVal & mask) | ((value.bVal & mask) << 1);
      printf("port %2d.%16s value=%08x.%08x %c\n", port, name, value.aVal, value.bVal, charval[encoding]);
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
public:
  int connected;

  XsimMemSlaveRequest(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : XsimMemSlaveRequestWrapper(id, item, param, poller), connected(0) { }
  ~XsimMemSlaveRequest() {}
  virtual void connect () {
    fprintf(stderr, "FIXME [%s:%d]\n", __FUNCTION__, __LINE__);
    // send back directory info
  }
  virtual void read ( const uint32_t addr ) {
    fprintf(stderr, "FIXME [%s:%d] addr=%08x\n", __FUNCTION__, __LINE__, addr);
  }
  virtual void write ( const uint32_t addr, const uint32_t data ) {
    fprintf(stderr, "FIXME [%s:%d] addr=%08x\n", __FUNCTION__, __LINE__, addr);
  }
};

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
    xsiport read_addr(xsiInstance, "read_addr", 32);
    xsiport en_read(xsiInstance, "EN_read");
    xsiport rdy_read(xsiInstance, "RDY_read");
    xsiport readData(xsiInstance, "readData", 32);
    xsiport en_readData(xsiInstance, "EN_readData");
    xsiport rdy_readData(xsiInstance, "RDY_readData");
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
    rst_n.write(1);

    read_addr.write(0);
    en_read.write(0);
    en_readData.write(0);
    en_write.write(0);

    xsiInstance.run(10);

    int portal_number = 0;
    int waiting_for_read = 0;
    int read_dir_val = 0;
    int portal_ids[16];
    int offset = 0x00;

    for (int i = 0; i < 100; i++)
    {

	void *rc = portalExec_poll(1);
	if ((long)rc >= 0) {
	    portalExec_event();
	}

	//en_readData.write(0);
	//en_read.write(0);
	if (i > 2)
	    rst_n.write(1);

	switch (state) {
	case xt_reset:
	    if (i > 2) {
		//rst_n.write(1);
		state = xt_read_directory;
	    }
	    break;
	case xt_read_directory:
	    if (portal_number < 16) {
		if (!waiting_for_read && rdy_read.read()) {
		    unsigned int addr = offset + portal_number * 0x10000;
		    fprintf(stderr, "Reading %08x rdy_readdata=%d\n", addr, rdy_readData.read());
		    en_read.write(1);
		    read_addr.write(addr);
		    waiting_for_read = 1;
		} else if (waiting_for_read && rdy_readData.read()) {
		    fprintf(stderr, "Read ID %08x for portal %d\n", readData.read(), portal_number);
		    en_readData.write(1);
		    waiting_for_read = 0;
		    read_dir_val = 1;
		    portal_ids[portal_number] = readData.read();
		    if (offset <= 0x20) {
			offset += 4;
		    } else {
			portal_number++;
			offset = 0x10;
		    }
		} else {
		    en_read.write(0);
		    en_readData.write(0);
		}
	    } else {
		state = xt_active;
	    }
	    break;
	case xt_active:
	    break;
	}
	clk.write(1);
	//rdy_read.read();
	xsiInstance.run(10);
	if (waiting_for_read)
	    fprintf(stderr, "rdy_read=%d rdy_readData=%d readData=%x\n", rdy_read.read(), rdy_readData.read(), readData.read());

	if (read_dir_val) {
	    fprintf(stderr, "after posedge,  ID %08x for portal %d\n", readData.read(), portal_number);
	    read_dir_val = 0;
	}
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
