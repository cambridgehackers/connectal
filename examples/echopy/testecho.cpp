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

#include <stdio.h>
#include "GeneratedTypes.h"
#include <python2.7/Python.h>

static PyObject *callbackFunction;
static PortalInternal erequest, eindication;
static PortalInternal pythonTransport;

#define STUB \
{ \
    fprintf(stderr, "[%s:%d]\n", __FUNCTION__, __LINE__);	\
    exit(-1); \
}
static volatile unsigned int *pythonTransportMAPCHANNELIND(struct PortalInternal *pint, unsigned int v)
{
    return &pythonTransport.map_base[0];
}
static volatile unsigned int *pythonTransportMAPCHANNELREQ(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return &pythonTransport.map_base[0];
}
static void pythonTransportSENDMSG(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd)
{
  fprintf(stderr, "%s:%d %s\n", __FUNCTION__, __LINE__, (const char *)buffer);
}
static int pythonTransportTRANSPORTINIT(struct PortalInternal *pint, void *param) STUB
static unsigned int pythonTransportREADWORD(struct PortalInternal *pint, volatile unsigned int **addr) STUB
static void pythonTransportWRITEWORD(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v) STUB
static void pythonTransportWRITEFDWORD(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v) STUB
static int pythonTransportRECVMSG(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd) STUB
static int pythonTransportBUSYWAIT(struct PortalInternal *pint, unsigned int v, const char *str) STUB
static void pythonTransportENABLEINT(struct PortalInternal *pint, int val) STUB
static int pythonTransportEVENT(struct PortalInternal *pint) STUB
static int pythonTransportNOTFULL(struct PortalInternal *pint, unsigned int v) STUB
PortalTransportFunctions callbackTransport = {
    pythonTransportTRANSPORTINIT, pythonTransportREADWORD, pythonTransportWRITEWORD, pythonTransportWRITEFDWORD,
    pythonTransportMAPCHANNELIND, pythonTransportMAPCHANNELREQ, pythonTransportSENDMSG, pythonTransportRECVMSG,
    pythonTransportBUSYWAIT, pythonTransportENABLEINT, pythonTransportEVENT, pythonTransportNOTFULL};

// static int heard_cb(struct PortalInternal *p,uint32_t v) {
//     EchoIndicationJson_heard (&pythonTransport, v);
//     PyGILState_STATE gstate = PyGILState_Ensure();
//     PyEval_CallMethod(callbackFunction, "callback", "(s)", pythonTransport.map_base, NULL);
//     PyGILState_Release(gstate);
//     return 0;
// }
// static int heard2_cb(struct PortalInternal *p,uint16_t a, uint16_t b) {
//     EchoIndicationJson_heard2 (&pythonTransport, a, b);
//     PyGILState_STATE gstate = PyGILState_Ensure();
//     PyEval_CallMethod(callbackFunction, "callback", "(s)", pythonTransport.map_base, NULL);
//     PyGILState_Release(gstate);
//     return 0;
// }
//static EchoIndicationCb EchoInd_cbTable = { portal_disconnect, heard_cb, heard2_cb};

extern "C" {
static int handleIndicationMessage(struct PortalInternal *pint, unsigned int channel, int messageFd)
{
  SENDMSG send = pint->transport->send;
  pint->json_arg_vector = 1;
  pint->transport->send = pythonTransportSENDMSG;
  int value = EchoIndication_handleMessage(pint, channel, messageFd);
  PyGILState_STATE gstate = PyGILState_Ensure();
  const char *jsonp = (const char *)pint->transport->mapchannelInd(pint, 0);
  fprintf(stderr, "handleIndicationMessage: json=%s\n", jsonp);
  PyEval_CallMethod(callbackFunction, "callback", "(s)", jsonp, NULL);
  PyGILState_Release(gstate);
  pint->transport->send = send;
  return value;
}

void set_callback(PyObject *param)
{
    Py_INCREF(param);
    callbackFunction = param;
    pythonTransport.transport = &callbackTransport;
    pythonTransport.map_base = (volatile unsigned int *)malloc(1000);
}

void *trequest(int ifcname, int reqinfo)
{
    void *parent = NULL;
    init_portal_internal(&erequest, ifcname, DEFAULT_TILE, NULL, NULL, NULL, NULL, parent, reqinfo);
    return &erequest;
}
void *tindication()
{
  void *parent = NULL;
    init_portal_internal(&eindication, IfcNames_EchoIndicationH2S, DEFAULT_TILE,
			 (PORTAL_INDFUNC) handleIndicationMessage, &EchoIndicationJsonProxyReq, NULL, NULL, parent, EchoIndication_reqinfo);
    // encode message as vector ["methodname", arg0, arg1, ...]
    pythonTransport.json_arg_vector = 1;
    return &eindication;
}
} // extern "C"
