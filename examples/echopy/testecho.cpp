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
static PortalInternal dummy;

#define STUB \
{ \
    printf("[%s:%d]\n", __FUNCTION__, __LINE__); \
    exit(-1); \
}
static volatile unsigned int *dummyMAPCHANNELIND(struct PortalInternal *pint, unsigned int v)
{
    return &dummy.map_base[0];
}
static volatile unsigned int *dummyMAPCHANNELREQ(struct PortalInternal *pint, unsigned int v, unsigned int size)
{
    return &dummy.map_base[0];
}
static void dummySENDMSG(struct PortalInternal *pint, volatile unsigned int *buffer, unsigned int hdr, int sendFd)
{
}
static int dummyITEMINIT(struct PortalInternal *pint, void *param) STUB
static unsigned int dummyREADWORD(struct PortalInternal *pint, volatile unsigned int **addr) STUB
static void dummyWRITEWORD(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v) STUB
static void dummyWRITEFDWORD(struct PortalInternal *pint, volatile unsigned int **addr, unsigned int v) STUB
static int dummyRECVMSG(struct PortalInternal *pint, volatile unsigned int *buffer, int len, int *recvfd) STUB
static int dummyBUSYWAIT(struct PortalInternal *pint, unsigned int v, const char *str) STUB
static void dummyENABLEINT(struct PortalInternal *pint, int val) STUB
static int dummyEVENT(struct PortalInternal *pint) STUB
static int dummyNOTFULL(struct PortalInternal *pint, unsigned int v) STUB
PortalTransportFunctions callbackItem = {
    dummyITEMINIT, dummyREADWORD, dummyWRITEWORD, dummyWRITEFDWORD,
    dummyMAPCHANNELIND, dummyMAPCHANNELREQ, dummySENDMSG, dummyRECVMSG,
    dummyBUSYWAIT, dummyENABLEINT, dummyEVENT, dummyNOTFULL};

static int heard_cb(struct PortalInternal *p,uint32_t v) {
    EchoIndicationJson_heard (&dummy, v);
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyEval_CallFunction(callbackFunction, "(s)", dummy.map_base, NULL);
    PyGILState_Release(gstate);
    return 0;
}
static int heard2_cb(struct PortalInternal *p,uint16_t a, uint16_t b) {
    EchoIndicationJson_heard2 (&dummy, a, b);
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyEval_CallFunction(callbackFunction, "(s)", dummy.map_base, NULL);
    PyGILState_Release(gstate);
    return 0;
}
static EchoIndicationCb EchoInd_cbTable = { portal_disconnect, heard_cb, heard2_cb};

extern "C" {
void set_callback(PyObject *param)
{
    Py_INCREF(param);
    callbackFunction = param;
    dummy.item = &callbackItem;
    dummy.map_base = (volatile unsigned int *)malloc(1000);
}

void *trequest()
{
    init_portal_internal(&erequest, IfcNames_EchoRequest, DEFAULT_TILE, NULL, NULL, NULL, NULL, EchoRequest_reqinfo);
//void init_portal_internal(PortalInternal *pint, int id, int tile, PORTAL_INDFUNC handler, void *cb, PortalTransportFunctions *item, void *param, uint32_t reqinfo);
    return &erequest;
}
void *tindication()
{
    init_portal_internal(&eindication, IfcNames_EchoIndication, DEFAULT_TILE,
        (PORTAL_INDFUNC) EchoIndication_handleMessage, &EchoInd_cbTable, NULL, NULL, EchoIndication_reqinfo);
    return &eindication;
}
} // extern "C"
