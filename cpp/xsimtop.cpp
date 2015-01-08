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
  //int width;
  //int direction;
  const char *name;
public:
  xsiport(Xsi::Loader &loader, const char *name, int bitds = 1) : xsiInstance(loader), port(-1), name(name) {
    port = xsiInstance.get_port_number(name);
    //width = xsiInstance.get_int_port(port, xsiHDLValueSize);
    std::cout << "Port name=" << name << " number=" << port << std::endl;
  }
  int read();
  void write(int val);

};

int xsiport::read()
{
    s_xsi_vlog_logicval value;
    xsiInstance.get_value(port, &value);
    if (1 || value.bVal != 0) {
      printf("value=%08x.%08x\n", value.aVal, value.bVal);
    }
    return value.aVal;
}
void xsiport::write(int val) 
{
    s_xsi_vlog_logicval value = { val, 0 };
    xsiInstance.put_value(port, &val);
}

class XsimMemSlaveRequest : public XsimMemSlaveRequestWrapper {
public:
  XsimMemSlaveRequest(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : XsimMemSlaveRequestWrapper(id, item, param, poller) { }
  ~XsimMemSlaveRequest() {}
  virtual void connect () {
    fprintf(stderr, "FIXME [%s:%d]", __FUNCTION__, __LINE__);
  }
  virtual void read ( const uint32_t addr ) {
    fprintf(stderr, "FIXME [%s:%d] addr=%08x\n", __FUNCTION__, __LINE__, addr);
  }
  virtual void write ( const uint32_t addr, const uint32_t data ) {
    fprintf(stderr, "FIXME [%s:%d] addr=%08x\n", __FUNCTION__, __LINE__, addr);
  }
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
    info.logFileName = NULL;
    xsiInstance.open(&info);
    
    xsiport rst_n(xsiInstance, "RST_N");
    xsiport clk(xsiInstance, "CLK");
    xsiport read_addr(xsiInstance, "read_addr", 32);
    xsiport en_read(xsiInstance, "EN_read");
    xsiport rdy_read(xsiInstance, "RDY_read");

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
    xsiInstance.run(10);

    for (int i = 0; i < 100; i++) {

      portalExec_event();

      if (i > 2)
	rst_n.write(1);
      clk.write(1);
      //rdy_read.read();
      xsiInstance.run(10);

      clk.write(0);
      xsiInstance.run(10);
    }
    portalExec_end();
}
