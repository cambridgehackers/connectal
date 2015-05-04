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
#ifdef SYSTEM_VERILOG
    #include "svdpi.h"
#else
    #include "xsi_loader.h"
#endif
#include <portal.h>
#include <sock_utils.h>
#include <XsimMemSlaveRequest.h>
#include <XsimMemSlaveIndication.h>

extern "C" {
void dpi_init();
void dpi_poll();
void dpi_msgSink_beat(int dst_rdy, int *beat, int *src_rdy);
void dpi_msgSource_beat(int src_rdy, int beat, int *dst_rdy);
}

static int trace_xsimtop = 0;

//deleteme
std::string getcurrentdir()
{
    return get_current_dir_name();
}

#ifndef SYSTEM_VERILOG
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
    value.aVal = 1;
    value.bVal = 1;
    port = xsiInstance.get_port_number(name);
    //width = xsiInstance.get_int_port(port, xsiHDLValueSize);
    std::cout << "Port name=" << name << " number=" << port << std::endl;
  }
  int read();
  void write(int val);
  int valid() { return port >= 0; }
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
#endif // !SYSTEM_VERILOG

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
  std::queue<uint32_t> sinkbeats;

  int connected;

  XsimMemSlaveRequest(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller = 0) : XsimMemSlaveRequestWrapper(id, item, param, poller), connected(0) { }
  ~XsimMemSlaveRequest() {}
  virtual void connect () {
      connected = 1;
  }
  virtual void enableint( const uint32_t fpgaId, const uint8_t val);
  virtual void read ( const uint32_t fpgaId, const uint32_t addr );
  virtual void write ( const uint32_t fpgaId, const uint32_t addr, const uint32_t data );
  virtual void msgSink ( const uint32_t data );

  void directory( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last );
  int fpgaNumber(int fpgaId);
  int fpgaId(int fpgaNumber);

};

void XsimMemSlaveRequest::enableint( const uint32_t fpgaId, const uint8_t val)
{
  int number = fpgaNumber(fpgaId);
  uint32_t hwaddr = number << 16 | 4;
  writereq req = { hwaddr, val };
  fprintf(stderr, "[%s:%d] id=%d number=%d addr=%08x\n", __FUNCTION__, __LINE__, fpgaId, number, hwaddr);
  writereqs.push(req);
}

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

void XsimMemSlaveRequest::msgSink ( const uint32_t data )
{
  if (trace_xsimtop)
      fprintf(stderr, "[%s:%d] data=%08x\n", __FUNCTION__, __LINE__, data);
  sinkbeats.push(data);
}

void XsimMemSlaveRequest::directory ( const uint32_t fpgaNumber, const uint32_t fpgaId, const uint32_t last )
{
    fprintf(stderr, "[%s:%d] fpga=%d id=%d last=%d\n", __FUNCTION__, __LINE__, fpgaNumber, fpgaId, last);
    struct idInfo info = { (int)fpgaNumber, (int)fpgaId, 1 };
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

class DpiWorker {
public:
  DpiWorker();
  void poll();
  //private:
  Portal                      *mcommon;
  XsimMemSlaveIndicationProxy *memSlaveIndicationProxy;
  XsimMemSlaveRequest         *memSlaveRequest;
  // msgSink
  int dst_rdy;
  // msgSource
  int src_rdy;
  uint32_t src_beat;
};

DpiWorker::DpiWorker()
 : dst_rdy(0), src_rdy(0)
{
    PortalSocketParam paramSocket = {};
    PortalMuxParam param = {};

    fprintf(stderr, "[%s:%d] using BluenocTop\n", __FILE__, __LINE__);
    mcommon = new Portal(0, 0, sizeof(uint32_t), portal_mux_handler, NULL, &transportSocketResp, &paramSocket);
    param.pint = &mcommon->pint;
    memSlaveIndicationProxy = new XsimMemSlaveIndicationProxy(XsimIfcNames_XsimMemSlaveIndication, &transportMux, &param);
    memSlaveRequest = new XsimMemSlaveRequest(XsimIfcNames_XsimMemSlaveRequest, &transportMux, &param);

    fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    defaultPoller->stop();
    sleep(2);
    fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);

}
// called on @(negedge CLK)
void DpiWorker::poll()
{
  if (dst_rdy) {
    // msgSink consumed one beat of data
    if (trace_xsimtop) fprintf(stderr, "[%s:%d] sinkbeats.pop()\n", __FUNCTION__, __LINE__);
    memSlaveRequest->sinkbeats.pop();
    dst_rdy = 0;
  }
  if (src_rdy) {
    // we got some data from the msgSource
      if (trace_xsimtop) fprintf(stderr, "[%s:%d] srcbeats.push() src_beat=%08x\n", __FUNCTION__, __LINE__, src_beat);
      memSlaveIndicationProxy->msgSource(src_beat);
      src_rdy = 0;
  }

}

static DpiWorker *dpiWorker;

void dpi_init()
{
    if (trace_xsimtop) fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);
    dpiWorker = new DpiWorker();
}

void dpi_poll()
{
  void *rc = defaultPoller->pollFn(1);
  if ((long)rc > 0)
      defaultPoller->event();
  if (dpiWorker->src_rdy || dpiWorker->dst_rdy) {
      if (trace_xsimtop) fprintf(stderr, "============================================================\n");
      if (trace_xsimtop)
	  fprintf(stderr, "[%s:%d] rc=%ld src_rdy=%d src_beat=%08x dst_rdy=%d\n",
		  __FUNCTION__, __LINE__, (long)rc, dpiWorker->src_rdy, dpiWorker->src_beat, dpiWorker->dst_rdy);
      dpiWorker->poll();
      if (trace_xsimtop)
	  fprintf(stderr, "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
  }

}

void dpi_msgSink_beat(int dst_rdy, int *p_beat, int *p_src_rdy)
{
  if (dst_rdy && (dpiWorker->memSlaveRequest->sinkbeats.size() > 0)) {
    uint32_t beat = dpiWorker->memSlaveRequest->sinkbeats.front();
    if (trace_xsimtop)
      fprintf(stderr, "[%s:%d] sink message beat %08x\n", __FUNCTION__, __LINE__, beat);
    *p_beat = beat;
    *p_src_rdy = 1;
    dpiWorker->dst_rdy = 1;
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
    dpiWorker->src_beat = beat;
    dpiWorker->src_rdy = 1;
    *p_dst_rdy = 1;
  } else {
    *p_dst_rdy = 0;
  }
}

int dpi_msgSource_dst_rdy_b(int src_rdy)
{
  if (src_rdy) {
    fprintf(stderr, "dpi_msgSource_dst_rdy_b() called\n");
    return 1;
  }
}

