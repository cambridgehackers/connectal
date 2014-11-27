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

#include "EchoIndication.h"
#include "EchoRequest.h"
#include "GeneratedTypes.h"
#include "Swallow.h"
#include <python2.7/Python.h>

extern "C" {
PyObject *heardCallback[20];
static PyObject* py_myHeard(PyObject* self, PyObject* args)
{
    PyObject *cb;
    int ind;
    PyArg_ParseTuple(args, "Oi", &cb, &ind);
    Py_INCREF(cb);
printf("[%s:%d] [%d] = %p\n", __FUNCTION__, __LINE__, ind, cb);
    heardCallback[ind] = cb;
    return Py_BuildValue("d", 0);
}

EchoRequestProxy *echoRequestProxy = 0;
static sem_t sem_heard2;

class EchoIndication : public EchoIndicationWrapper
{
public:
    virtual void heard(uint32_t v) {
        PyEval_CallFunction(heardCallback[0], "(i)", v);
    }
    virtual void heard2(uint32_t a, uint32_t b) {
        sem_post(&sem_heard2);
        PyEval_CallFunction(heardCallback[1], "(ii)", a, b);
        //printf("heard an echo2: %ld %ld\n", a, b);
    }
    EchoIndication(unsigned int id) : EchoIndicationWrapper(id) {}
};

static PyObject* py_call_say(PyObject* self, PyObject* args)
{
    int v;
    PyArg_ParseTuple(args, "i", &v);
    echoRequestProxy->say(v);
    sem_wait(&sem_heard2);
    return Py_BuildValue("d", 0);
}
static PyObject* py_call_say2(PyObject* self, PyObject* args)
{
    int v, v2;
    PyArg_ParseTuple(args, "ii", &v, &v2);
    echoRequestProxy->say2(v, v2);
    return Py_BuildValue("d", 0);
}
static PyObject* py_portalExec_start(PyObject* self, PyObject* args)
{
    portalExec_start();
    return Py_BuildValue("d", 0);
}
static PyObject* py_tmain(PyObject* self, PyObject* args)
{
    EchoIndication *echoIndication = new EchoIndication(IfcNames_EchoIndication);
    SwallowProxy *swallowProxy = new SwallowProxy(IfcNames_Swallow);
    echoRequestProxy = new EchoRequestProxy(IfcNames_EchoRequest);
    return Py_BuildValue("d", 0);
}

static PyMethodDef myModule_methods[] = {
    {"myHeard", py_myHeard, METH_VARARGS},
    {"tmain", py_tmain, METH_VARARGS},
    {"call_say", py_call_say, METH_VARARGS},
    {"call_say2", py_call_say2, METH_VARARGS},
    {"portalExec_start", py_portalExec_start, METH_VARARGS},
    {NULL, NULL}
};

void initconnectal()
{
    Py_InitModule("connectal", myModule_methods);
}
} // extern "C"
