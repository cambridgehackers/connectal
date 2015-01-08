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
#include <python2.7/Python.h>
#include <netdb.h>

#include "sock_utils.h"

#include "GeneratedTypes.h"

static PyObject *sampleCallback[20];
static PortalInternal eindication;

extern "C" {
void jcabozo(PyObject *param, int ind)
{
    Py_INCREF(param);
    sampleCallback[ind] = param;
}

static void sample_cb(struct PortalInternal *p,uint32_t v) {
    PyGILState_STATE gstate = PyGILState_Ensure();
    PyEval_CallFunction(sampleCallback[0], "(i)", v, NULL);
    PyGILState_Release(gstate);
}

static SampleCb cbTable = {sample_cb};

#define SANITY
#ifdef SANITY
#include "Sample.h"
class Sample : public SampleWrapper{
public:
    virtual void sample(uint32_t v) {fprintf(stderr, "sample : %d\n", v);}
    Sample(unsigned int id, PortalItemFunctions *item, void *param) : SampleWrapper(id, item, param) {}
};
#endif

void *tindication()
{
  PortalSocketParam param = {0};
  int rc = getaddrinfo("127.0.0.1", "5000", NULL, &param.addr);
#ifndef SANITY
  init_portal_internal(&eindication, IfcNames_Sample, Sample_handleMessage, &cbTable, &socketfuncInit, &param, Sample_reqinfo);
#else
  Sample *sIndication = new Sample(IfcNames_Sample, &socketfuncInit, &param);
  portalExec_start();
  while(1) sleep(1);
#endif
  return &eindication;
}
} // extern "C"
