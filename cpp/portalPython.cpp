/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 * Copyright (c) 2016 ConnectalProject
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

static int tracePython;// = 1;
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
    if (tracePython)
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

extern "C" {

typedef int (*HandleMessage)(struct PortalInternal *pint, unsigned int channel, int messageFd);

struct PortalPython {
    struct PortalInternal pint;
    HandleMessage handleMessage;
    PyObject *callbackFunction;
};

static int handleIndicationMessage(struct PortalInternal *pint, unsigned int channel, int messageFd)
{
    struct PortalPython *ppython = (struct PortalPython *)pint;
    HandleMessage handleMessage = ppython->handleMessage;
    pint->json_arg_vector = 1;
    int value = handleMessage(pint, channel, messageFd);
    PyGILState_STATE gstate = PyGILState_Ensure();
    const char *jsonp = (const char *)pint->parent;
    if (tracePython) fprintf(stderr, "handleIndicationMessage: json=%s\n", jsonp);
    if (ppython->callbackFunction) {
	PyEval_CallMethod(ppython->callbackFunction, "callback", "(s)", jsonp, NULL);
    } else {
	fprintf(stderr, "%s:%d no callback for portal\n", __FUNCTION__, __LINE__);
    }
    PyGILState_Release(gstate);
    return value;
}

void set_callback(struct PortalPython *ppython, PyObject *param)
{
    Py_INCREF(param);
    ppython->callbackFunction = param;
    pythonTransport.transport = &callbackTransport;
    pythonTransport.map_base = (volatile unsigned int *)malloc(1000);
}

void *newRequestPortal(int ifcname, int reqinfo)
{
    struct PortalInternal *pint = (struct PortalInternal *)calloc(1, sizeof(struct PortalInternal));
    void *parent = NULL;;
    if (tracePython) fprintf(stderr, "%s:%d ifcname=%x reqinfo=%08x pint=%p\n", __FUNCTION__, __LINE__, ifcname, reqinfo, pint);
    init_portal_internal(pint, ifcname, DEFAULT_TILE, NULL, NULL, NULL, NULL, parent, reqinfo);
    return pint;
}

void *newIndicationPortal(int ifcname, int reqinfo, HandleMessage handleMessage, void *proxyreq)
{
    void *parent = malloc(4096);
    struct PortalPython *ppython = (struct PortalPython *)calloc(1, sizeof(struct PortalPython));
    ppython->handleMessage = handleMessage;
    if (tracePython)
    fprintf(stderr, "%s:%d ifcname=%x reqinfo=%08x handleMessage=%p proxyreq=%p pint=%p\n",
	    __FUNCTION__, __LINE__, ifcname, reqinfo, handleMessage, proxyreq, ppython);
    init_portal_internal(&ppython->pint, ifcname, DEFAULT_TILE,
			 (PORTAL_INDFUNC) handleIndicationMessage, proxyreq, NULL, NULL, parent, reqinfo);
    // encode message as vector ["methodname", arg0, arg1, ...]
    pythonTransport.json_arg_vector = 1;
    return ppython;
}
} // extern "C"
